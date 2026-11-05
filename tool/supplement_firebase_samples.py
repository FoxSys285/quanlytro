"""Add labeled samples to current authenticated Firebase; preview unless --apply.
Never writes legacy app_documents, users, rules, or management/system.
"""
import argparse
import copy
import json
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import quote

sys.path.insert(0, str(Path(__file__).resolve().parent))
from publish_cloud_documents import BASE, ROOT, decode, request, sign_in_admin, value

PREFIX = 'sample-v1'


def plan(current, now, admin_uid):
    additions = {}
    stamp = now.isoformat()
    def add(path, data):
        if path not in current:
            additions[path] = data
    for path, prop in current.items():
        if not path.startswith('rental_properties/') or prop.get('archived'):
            continue
        pid = path.split('/')[1]
        owner = prop['ownerUid']
        property_data = prop['data']['property']
        records = [v for v in current.values() if v.get('propertyId') == pid
                   and not v.get('archived') and v.get('kind')]
        leases = [r['data'] for r in records if r['kind'] == 'leases'
                  and r['data'].get('status') == 'active'
                  and r['data']['startDate'][:10] <= stamp[:10] <= r['data']['endDate'][:10]]
        # Samples follow a real lease/reader; no invented login or owner identity.
        if not leases:
            continue
        tenant_ids = {u.get('tenantId') for p, u in current.items()
                      if p.startswith('users/') and u.get('role') == 'tenant' and not u.get('disabled')}
        lease = next((l for l in leases if l['tenantId'] in tenant_ids), leases[0])
        tenant = lease['tenantId']
        room = lease['room']
        key = f'{PREFIX}-{pid}'
        def record(kind, suffix, data, readers=None, document_key=None):
            rid = f'{key}-{suffix}'
            data = {'id': rid, **data}
            add(f'rental_records/{pid}:{kind}:{document_key or rid}', {
                'kind': kind, 'propertyId': pid, 'ownerUid': owner,
                'tenantIds': [tenant] if readers is None else readers,
                'archived': False, 'data': data})
            return rid
        # Draft and ended contracts are isolated from the live room occupancy.
        for status in ('draft', 'terminated'):
            sample = copy.deepcopy(lease)
            for field in ('tenantCitizenId', 'landlordCitizenId', 'tenantPermanentAddress',
                          'tenantBirthYear', 'bankAccountNumber', 'tenantCitizenIssueDate'):
                sample[field] = None if field == 'tenantCitizenIssueDate' else ''
            sample.update(id=f'{key}-lease-{status}', tenantId=f'{key}-tenant',
                          propertyId=pid, tenantName='[MẪU] Nguyễn Minh An', phone='0900000000',
                          status=status, note='[MẪU] Hợp đồng minh họa, không phải giao dịch thực tế.')
            sample['bankTransferEnabled'] = False
            if status == 'terminated':
                sample.update(startDate=(now-timedelta(days=180)).isoformat(),
                              endDate=(now-timedelta(days=30)).isoformat(), termMonths=5)
            else:
                sample.update(startDate=(now+timedelta(days=7)).isoformat(),
                              endDate=(now+timedelta(days=372)).isoformat(), termMonths=12)
            record('leases', f'lease-{status}', sample, [sample['tenantId']])
        rent = lease['monthlyRent']
        total = rent + 435000
        for index, scenario in enumerate(('paid', 'partial', 'overdue', 'pending', 'rejected')):
            paid = total if scenario == 'paid' else total//2 if scenario == 'partial' else 0
            due = now + timedelta(days=-7 if scenario == 'overdue' else 7)
            iid = record('invoices', 'invoice-'+scenario, {
                'leaseId': lease['id'], 'room': room, 'tenantName': lease['tenantName'],
                'period': now.replace(day=1,hour=0,minute=0,second=0,microsecond=0).isoformat(),
                'dueDate': due.isoformat(), 'charges': [
                    {'name': 'Tiền thuê phòng', 'amount': rent},
                    {'name': 'Điện · 70 kWh [MẪU]', 'amount': 280000},
                    {'name': 'Nước · 5 m³ [MẪU]', 'amount': 75000},
                    {'name': 'Dịch vụ [MẪU]', 'amount': 80000}],
                'paidAmount': paid, 'cancelled': False})
            if scenario == 'overdue':
                continue
            approved = scenario in ('paid', 'partial')
            record('payments', 'payment-'+scenario, {
                'invoiceId': iid, 'tenantName': lease['tenantName'], 'room': room,
                'reportedAmount': paid if approved else total, 'paidAt': stamp,
                'method': 'Tiền mặt [MẪU]', 'reference': f'MAU-{pid}-{scenario}',
                'status': 'approved' if approved else scenario,
                'approvedAmount': paid if approved else None,
                'reviewedAt': stamp if approved or scenario == 'rejected' else None,
                'rejectionReason': '[MẪU] Nội dung chứng từ chưa khớp hóa đơn.' if scenario == 'rejected' else None,
                'proofBytes': None, 'proofName': None, 'paymentAccountId': None})
        for status in ('pending', 'active', 'rejected'):
            record('members', 'member-'+status, {
                'leaseId': lease['id'], 'tenantId': f'{key}-member-{status}',
                'name': f'[MẪU] Thành viên {status}', 'phone': '0900000000',
                'joinedAt': stamp, 'isRepresentative': False, 'status': status,
                'rejectionReason': '[MẪU] Cần bổ sung thông tin.' if status == 'rejected' else None,
                'requestedBy': tenant, 'requestedAt': stamp})
        for index, status in enumerate(('newly', 'inProgress', 'resolved', 'closed')):
            record('incidents', 'incident-'+status, {
                'leaseId': lease['id'], 'reporterId': tenant, 'reporter': lease['tenantName'],
                'room': room, 'title': '[MẪU] '+('Vòi nước rò rỉ','Bóng đèn hành lang','Kiểm tra wifi','Vệ sinh máy lạnh')[index],
                'category': ('Nước','Điện','Internet','Điện lạnh')[index],
                'description': '[MẪU] Yêu cầu sửa chữa để minh họa các bước xử lý sự cố.',
                'date': now.strftime('%d/%m/%Y'), 'urgent': index == 0, 'status': status})
        # A separate past reading does not overwrite the live room/month reading.
        period = now.replace(day=1) - timedelta(days=1)
        existing_readings = [r['data'] for r in records if r['kind'] == 'readings']
        if not any(r['room'] == room and r['period'][:7] == period.strftime('%Y-%m') for r in existing_readings):
            record('readings', 'reading', {'room': room,
                'period': period.replace(day=1).isoformat(), 'oldElectric': 1000,
                'newElectric': 1070, 'oldWater': 100, 'newWater': 105})
        for index, status in enumerate(('pending','confirmed','cancelled')):
            record('viewings', 'viewing-'+status, {'propertyId': pid, 'tenantId': tenant,
                'roomName': f'[MẪU] {property_data["name"]} · Phòng {room}',
                'address': property_data['address'], 'startsAt': (now+timedelta(days=index+1)).isoformat(),
                'customerName': lease['tenantName'], 'phone': '0900000000',
                'personalNeeds': '[MẪU] Lịch tham khảo các trạng thái, không phải cuộc hẹn thực tế.',
                'status': status, 'attendeeCount': 1, 'roomId': None, 'createdAt': stamp})
        cid = record('conversations', 'conversation', {'propertyId': pid,
            'tenantId': tenant, 'leaseId': lease['id'], 'tenantName': lease['tenantName'],
            'room': room, 'landlordName': property_data.get('ownerName',''),
            'propertyName': property_data['name'], 'messages': [], 'unread': 1, 'tenantUnread': 1})
        for index, text in enumerate(('[MẪU] Em xem chi tiết hóa đơn ở đâu ạ?',
                                    '[MẪU] Em mở mục Hóa đơn để xem từng khoản nhé.')):
            record('messages', f'message-{index}', {'text': text, 'time': '09:0'+str(index),
                'fromLandlord': index == 1, 'createdAt': stamp, 'index': index,
                'conversationId': cid, 'conversationKey': f'{pid}:conversations:{cid}'})
        announcement = {'id': key+'-announcement', 'title': '[MẪU] Lịch vệ sinh khu vực chung',
            'content': '[MẪU] Dữ liệu minh họa gửi thông báo; không phải lịch vận hành thực tế.',
            'category': 'operations', 'createdAt': stamp, 'propertyId': pid,
            'isRead': False, 'priority': 'normal', 'recipients': [room], 'audienceLabel': 'Phòng '+room}
        payload = {'sent': [announcement], 'recipients': {announcement['id']: [tenant]},
                   'readByTenant': {tenant: []}, 'landlordRead': [], 'nextId': 1}
        # Existing announcements/read states are preserved; fill only missing channels.
        for kind, readers in (('announcements', []), ('tenantAnnouncements', [tenant])):
            if any(r['kind'] == kind and (kind == 'announcements' or tenant in r.get('tenantIds', []))
                   for r in records):
                continue
            record(kind, 'announcement-'+kind, payload, readers,
                   document_key=pid if kind == 'announcements' else tenant)
    add('support_tickets/'+PREFIX+'-admin', {'accountUid': admin_uid, 'data': {
        'id': PREFIX+'-admin', 'role': 'admin', 'title': '[MẪU] Kiểm tra hỗ trợ',
        'content': '[MẪU] Yêu cầu do quản trị viên tạo để thử luồng phản hồi hỗ trợ.',
        'createdAt': stamp, 'reply': '', 'closed': False}})
    return additions


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--admin-email', help='Prompts in terminal when omitted')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    admin = sign_in_admin(args.admin_email or input('Firebase admin email: ').strip())
    now = datetime.now(timezone(timedelta(hours=7)))
    current, raw = {}, []
    for collection in ('rental_properties','rental_records','support_tickets','users'):
        page = ''
        while True:
            response = request(BASE+'/'+collection+'?pageSize=1000'+page)
            for doc in response.get('documents', []):
                raw.append(doc)
                current[doc['name'].split('/documents/')[1]] = {
                    k: decode(v) for k,v in doc.get('fields',{}).items()}
            if not response.get('nextPageToken'):
                break
            page = '&pageToken='+quote(response['nextPageToken'], safe='')
    additions = plan(current, now, admin)
    backup = ROOT/'.local-backups/firestore'/('samples-'+now.strftime('%Y%m%dT%H%M%S%f'))
    backup.mkdir(parents=True, exist_ok=False)
    (backup/'before.json').write_text(json.dumps(raw,ensure_ascii=False),encoding='utf-8')
    (backup/'planned.json').write_text(json.dumps(additions,ensure_ascii=False),encoding='utf-8')
    print(json.dumps({'newDocuments': len(additions),
        'kinds': dict(Counter(d.get('kind','support') for d in additions.values())),
        'backup': str(backup.relative_to(ROOT)), 'apply': args.apply}), flush=True)
    if len(additions) > 450:
        raise ValueError('More than 450 documents; split by property before applying')
    if not args.apply or not additions:
        return
    prefix = BASE.split('/v1/')[1]+'/'
    # Firebase ID token can list/commit here, but beginTransaction returns 403.
    # One create-only commit stays atomic and cannot overwrite live records.
    request(BASE+':commit', {'writes': [
        {'update': {'name': prefix+p,'fields': {k:value(v) for k,v in d.items()}},
         'currentDocument': {'exists': False}} for p,d in additions.items()]})
    verified = []
    for path, expected in additions.items():
        live = request(BASE+'/'+path)
        if {k:decode(v) for k,v in live['fields'].items()} != expected:
            raise RuntimeError('Read-back differs: '+path)
        verified.append(live)
    (backup/'after.json').write_text(json.dumps(verified,ensure_ascii=False),encoding='utf-8')
    print('PUBLISHED_AND_VERIFIED: '+str(len(verified)), flush=True)


if __name__ == '__main__':
    try:
        main()
    except HTTPError as error:
        raise SystemExit(f'Firebase HTTP {error.code}; requires active admin authentication') from None
