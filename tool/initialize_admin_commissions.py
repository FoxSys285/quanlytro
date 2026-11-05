"""Fill missing commission rates/statements from EXISTING Firestore payments.

Read-only unless --apply is provided. Preserves invoices, payments, receipts,
accounts and existing admin configuration in management/system. Requires admin
authentication; reads and writes within a Firestore transaction.
"""
import argparse
import copy
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
import os
import sys
from urllib.error import HTTPError

# Reuse the existing authenticated publisher; no password/token files.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from publish_cloud_documents import BASE, ROOT, request, decode, value, sign_in_admin


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
    for key, default in {'verified': {}, 'verificationProofs': {}, 'reviewNotes': {},
                         'hidden': [], 'tickets': [], 'logs': [],
                         'acceptingViewings': True}.items():
        admin.setdefault(key, default)
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
                          and (p.get('reviewedAt') or p['paidAt'])[:7] < current_period})
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


def scoped_portfolio(properties, records):
    stores = {}
    for prop in properties:
        if prop.get('archived') or not isinstance(prop.get('data'), dict):
            continue
        store = copy.deepcopy(prop['data'])
        if store.get('property', {}).get('id') != prop['id']:
            raise ValueError('Property ID mismatch: ' + prop['id'])
        store.update(invoices=[], payments=[])
        stores[prop['id']] = store
    for record in records:
        store = stores.get(record.get('propertyId'))
        kind = record.get('kind')
        if store is not None and not record.get('archived') and kind in ('invoices', 'payments'):
            store[kind].append(copy.deepcopy(record['data']))
    if not stores:
        raise ValueError('No current Firebase properties')
    return {'properties': list(stores.values())}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', default='doantro-caf4b')
    parser.add_argument('--admin-email', help='Prompts for password privately in terminal')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    if '/projects/' + args.project + '/' not in BASE:
        parser.error('Project must match the app Firebase configuration')
    if args.admin_email:
        sign_in_admin(args.admin_email)
    elif not os.environ.get('FIREBASE_ACCESS_TOKEN'):
        parser.error('Use --admin-email EMAIL or an existing FIREBASE_ACCESS_TOKEN; never send passwords in chat')
    now = datetime.now(timezone(timedelta(hours=7)))
    backup = ROOT / '.local-backups/firestore' / now.strftime('%Y%m%dT%H%M%S%f')
    transaction = request(BASE + ':beginTransaction', {})['transaction']
    committed = False
    try:
        records = {}
        for collection in ('rental_properties', 'rental_records', 'management'):
            query = {'from': [{'collectionId': collection}]}
            if collection == 'management':
                query['where'] = {'fieldFilter': {
                    'field': {'fieldPath': '__name__'}, 'op': 'EQUAL',
                    'value': {'referenceValue': BASE.split('/v1/')[1] + '/management/system'}}}
            rows = request(BASE + ':runQuery', {'structuredQuery': query, 'transaction': transaction})
            records[collection] = [r['document'] for r in rows if 'document' in r]
        backup.mkdir(parents=True, exist_ok=False)
        (backup / 'before.json').write_text(json.dumps(records, ensure_ascii=False), encoding='utf-8')
        def unpack(doc):
            return {k: decode(v) for k, v in doc.get('fields', {}).items()}
        properties = [{**unpack(d), 'id': d['name'].split('/')[-1]} for d in records['rental_properties']]
        portfolio = scoped_portfolio(properties, [unpack(d) for d in records['rental_records']])
        old = records['management'][0] if records['management'] else None
        management = unpack(old) if old else {}
        current = management.get('admin', {})
        updated, details = plan(portfolio, current, now)
        management['admin'] = updated
        fields = {k: value(v) for k, v in management.items()}
        if len(json.dumps(fields, ensure_ascii=False).encode('utf-8')) > 800000:
            raise ValueError('Management document is too large')
        print(json.dumps({'apply': args.apply, 'rates': details,
                          'newStatements': len(updated['commissionStatements']) - len(current.get('commissionStatements', [])),
                          'backup': str(backup.relative_to(ROOT))}, ensure_ascii=True), flush=True)
        if not args.apply or updated == current:
            return
        name = BASE.split('/v1/')[1] + '/management/system'
        result = request(BASE + ':commit', {'transaction': transaction, 'writes': [{
            'update': {'name': name, 'fields': fields},
            'currentDocument': {'updateTime': old['updateTime']} if old else {'exists': False},
        }]})
        committed = True
        live = request(BASE + '/management/system')
        if unpack(live) != management:
            raise RuntimeError('Read-back differs; inspect concurrent writes')
        (backup / 'after.json').write_text(json.dumps(live, ensure_ascii=False), encoding='utf-8')
        print(json.dumps({'verified': True, 'commitTime': result['commitTime'],
                          'statements': len(updated['commissionStatements']), 'receivedAdded': 0}))
    finally:
        if not committed:
            request(BASE + ':rollback', {'transaction': transaction})


if __name__ == '__main__':
    try:
        main()
    except HTTPError as error:
        # HTTP response bodies may contain account details; do not print them.
        raise SystemExit(f'Firebase HTTP {error.code}: sign in with an active admin account') from None
