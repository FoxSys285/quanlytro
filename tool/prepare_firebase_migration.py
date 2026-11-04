"""Back up current legacy data and prepare a scoped migration; never writes Firebase."""
import datetime as dt
import json
from pathlib import Path
from update_demo_firestore import BASE, WORK, request


def main():
    config = json.loads((WORK / 'provisioning.json').read_text(encoding='utf-8'))
    uids = [config.get(role + 'Uid') for role in ('landlord', 'tenant', 'admin')]
    if any(not isinstance(uid, str) or not uid.strip() or '/' in uid for uid in uids) or len(set(uids)) != 3:
        raise ValueError('Cần ba UID Firebase Auth khác nhau trong provisioning.json')
    documents = []
    page = ''
    while True:
        result = request(BASE + '/app_documents?pageSize=1000' + page)
        documents.extend(result.get('documents', []))
        token = result.get('nextPageToken')
        if not token:
            break
        from urllib.parse import quote
        page = '&pageToken=' + quote(token, safe='')
    WORK.mkdir(parents=True, exist_ok=True)
    stamp = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    (WORK / f'pre-migration-{stamp}.json').write_text(json.dumps(documents, ensure_ascii=False), encoding='utf-8')
    snapshot = {
        doc['name'].split('/')[-1]: json.loads(doc['fields']['payload']['stringValue'])
        for doc in documents if 'payload' in doc.get('fields', {})
    }
    if not snapshot.get('portfolio', {}).get('properties'):
        raise ValueError('Không có nhà trọ hiện hành để chuyển')
    tenant_id = config.get('tenantId', 'tenant-demo')
    if not any(lease.get('tenantId') == tenant_id
               for store in snapshot['portfolio']['properties'] for lease in store['leases']):
        raise ValueError('tenantId chưa có trong hợp đồng hiện tại')
    (WORK / 'prepared.json').write_text(json.dumps(snapshot, ensure_ascii=False), encoding='utf-8')
    print(f'PREPARED_CURRENT_DATA: {len(snapshot["portfolio"]["properties"])} properties; no demo data added; Firebase unchanged')


if __name__ == '__main__':
    main()
