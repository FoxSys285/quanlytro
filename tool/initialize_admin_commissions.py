"""Fill missing commission rates/statements from EXISTING Firestore payments.

Read-only unless --apply is provided. Preserves invoices, payments, receipts,
accounts and existing admin configuration. Uses update-time preconditions.
"""
import argparse
import copy
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.request import Request, urlopen


def rent_collected(store, period):
    invoices = {i['id']: i for i in store.get('invoices', [])}
    result = 0
    for payment in store.get('payments', []):
        date = payment.get('reviewedAt') or payment['paidAt']
        if payment['status'] != 'approved' or date[:7] != period:
            continue
        invoice = invoices.get(payment['invoiceId'])
        if not invoice or invoice.get('cancelled', False):
            continue
        total = sum(c['amount'] for c in invoice['charges'])
        rent = sum(c['amount'] for c in invoice['charges']
                   if c['name'].strip().lower() in ('tiền phòng', 'tiền thuê phòng'))
        if total > 0:
            result += ((payment.get('approvedAmount') or 0) * rent + total // 2) // total
    return result


def plan(portfolio, current, now):
    admin = copy.deepcopy(current)
    rates = admin.setdefault('commissionRates', {})
    statements = admin.setdefault('commissionStatements', [])
    existing = {(s['propertyId'], s['month'][:7]) for s in statements}
    details = []
    stamp = now.isoformat()
    current_period = now.strftime('%Y-%m')
    for index, store in enumerate(portfolio['properties']):
        property_id = store['property']['id']
        rates.setdefault(property_id, 300 + index * 50)
        if not 0 <= rates[property_id] <= 10000:
            raise ValueError('Invalid commission rate: ' + property_id)
        periods = sorted({(p.get('reviewedAt') or p['paidAt'])[:7]
                          for p in store.get('payments', [])
                          if p['status'] == 'approved'
                          and (p.get('reviewedAt') or p['paidAt'])[:7] < current_period})[-2:]
        for period in periods:
            if (property_id, period) in existing:
                continue
            base = rent_collected(store, period)
            if base <= 0:
                continue
            statements.append({
                'propertyId': property_id, 'propertyName': store['property']['name'],
                'month': period + '-01T00:00:00.000', 'rentCollected': base,
                'rateBasisPoints': rates[property_id], 'createdAt': stamp,
                'receipts': [],
            })
        current_rent = rent_collected(store, current_period)
        details.append({'id': property_id, 'ratePercent': rates[property_id] / 100,
                        'currentMonthRent': current_rent,
                        'currentMonthForecast': (current_rent * rates[property_id] + 5000) // 10000})
    if admin != current:
        admin.setdefault('logs', []).insert(0, {
            'action': 'Thiết lập tỷ lệ riêng và đối soát từ khoản thu đã duyệt; chưa ghi nhận tiền hoa hồng.',
            'actor': 'Quản trị viên', 'at': stamp,
        })
        admin['logs'] = admin['logs'][:500]
    return admin, details


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    base = f'https://firestore.googleapis.com/v1/projects/{args.project}/databases/(default)/documents'
    now = datetime.now(timezone(timedelta(hours=7)))
    backup = Path('.local-backups/firestore') / now.strftime('%Y%m%dT%H%M%S%f')
    backup.mkdir(parents=True, exist_ok=False)
    records = {}
    for key in ('portfolio', 'admin'):
        with urlopen(base + '/app_documents/' + key, timeout=30) as response:
            records[key] = json.load(response)
        (backup / (key + '.json')).write_text(json.dumps(records[key], ensure_ascii=False), encoding='utf-8')
    portfolio, current = [json.loads(records[key]['fields']['payload']['stringValue'])
                          for key in ('portfolio', 'admin')]
    updated, details = plan(portfolio, current, now)
    payload = json.dumps(updated, ensure_ascii=False, separators=(',', ':'))
    if len(payload.encode('utf-8')) > 800000:
        raise ValueError('Admin document is too large')
    print(json.dumps({'apply': args.apply, 'rates': details,
                      'newStatements': len(updated['commissionStatements']) - len(current.get('commissionStatements', [])),
                      'backup': str(backup)}, ensure_ascii=True))
    if not args.apply or updated == current:
        return
    fields = copy.deepcopy(records['admin']['fields'])
    fields['payload'] = {'stringValue': payload}
    fields['updated_at'] = {'stringValue': now.isoformat()}
    request = Request(base + ':commit', data=json.dumps({'writes': [
        {'verify': records['portfolio']['name'], 'currentDocument': {'updateTime': records['portfolio']['updateTime']}},
        {'update': {'name': records['admin']['name'], 'fields': fields},
         'currentDocument': {'updateTime': records['admin']['updateTime']}},
    ]}).encode('utf-8'), headers={'Content-Type': 'application/json'}, method='POST')
    with urlopen(request, timeout=30) as response:
        result = json.load(response)
    with urlopen(base + '/app_documents/admin', timeout=30) as response:
        live = json.load(response)
    if json.loads(live['fields']['payload']['stringValue']) != updated:
        raise RuntimeError('Read-back differs from committed data; inspect concurrent writes')
    (backup / 'admin-after.json').write_text(json.dumps(live, ensure_ascii=False), encoding='utf-8')
    print(json.dumps({'verified': True, 'commitTime': result['commitTime'],
                      'statements': len(updated['commissionStatements']),
                      'receivedAdded': 0}))


if __name__ == '__main__':
    main()
