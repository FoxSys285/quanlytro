"""Backfill missing landlord contact phones; never attach generated phones to Auth.

Run preview, then apply, then verify through with_firebase_cli.cjs. Backups and
the immutable plan stay in the ignored .local-backups directory.
"""
import argparse
from collections import Counter
from datetime import datetime, timezone
import json
import os
import re
import secrets
from pathlib import Path

from collect_nationwide_rentals import ROOT, cloud, dump, project_config, wire_value
from publish_vietnam_catalogue import base_url, decode_document, list_collection

WORK = ROOT / '.local-backups/landlord-phone-backfill'
PREFIXES = ('032', '033', '034', '035', '036', '037', '038', '039',
            '070', '076', '077', '078', '079', '081', '082', '083', '084',
            '085', '086', '088', '089', '090', '091', '093', '094', '096',
            '097', '098', '099')


def normalized(value):
    value = re.sub(r'[\s().-]', '', str(value or ''))
    if value.startswith('+84'):
        value = '0' + value[3:]
    elif value.startswith('84') and len(value) == 11:
        value = '0' + value[2:]
    return value if re.fullmatch(r'0[35789]\d{8}', value) else None


def generated_phone(used):
    while True:
        number = secrets.choice(PREFIXES) + f'{secrets.randbelow(10000000):07d}'
        if number not in used:
            used.add(number)
            return number


def read_plan():
    plan = json.loads((WORK / 'plan.json').read_text(encoding='utf-8'))
    if plan['project'] != project_config()[0]:
        raise ValueError('Plan belongs to another Firebase project')
    return plan


def preview():
    if (WORK / 'plan.json').exists():
        raise ValueError('Plan already exists; resume it rather than replacing backups')
    users = list_collection('users')
    properties = list_collection('rental_properties')
    decoded = {p: decode_document(d) for p, d in {**users, **properties}.items()}
    used = {number for d in decoded.values()
            for value in (d.get('phoneNumber'), d.get('phone'),
                          d.get('data', {}).get('property', {}).get('phone'))
            if (number := normalized(value))}
    changes = []
    owners = {p.split('/')[1]: d for p, d in decoded.items()
              if p.startswith('users/') and d.get('role') == 'landlord'}
    for uid, owner in sorted(owners.items()):
        houses = {p: d for p, d in decoded.items()
                  if p.startswith('rental_properties/') and d.get('ownerUid') == uid}
        phone = normalized(owner.get('phoneNumber')) or normalized(owner.get('phone'))
        synthetic = owner.get('phoneIsSynthetic', False)
        if phone is None:
            contacts = [(normalized(d.get('data', {}).get('property', {}).get('phone')),
                         d.get('data', {}).get('property', {}).get('phoneIsSynthetic', False))
                        for d in houses.values()]
            existing = next(((n, s) for n, s in contacts if n), None)
            phone, synthetic = existing if existing else (generated_phone(used), True)
        path = 'users/' + uid
        patch = {}
        if not normalized(owner.get('phoneNumber')):
            patch = {'phoneNumber': '+84' + phone[1:], 'phoneIsSynthetic': bool(synthetic),
                     'phoneVerified': False}
        if patch:
            changes.append({'path': path, 'updateTime': users[path]['updateTime'], 'fields': patch})
        for path, house in houses.items():
            contact = house.get('data', {}).get('property', {})
            if normalized(contact.get('phone')):
                continue
            changes.append({'path': path, 'updateTime': properties[path]['updateTime'],
                            'fields': {'data.property.phone': phone,
                                       'data.property.phoneIsSynthetic': bool(synthetic)}})
    dump(WORK / 'before.json', {p: d for p, d in {**users, **properties}.items()
                               if p in {c['path'] for c in changes}})
    plan = {'project': project_config()[0], 'createdAt': datetime.now(timezone.utc).isoformat(),
            'landlords': len(owners), 'changes': changes,
            'generatedPhonesAreContactSamplesOnly': True}
    dump(WORK / 'plan.json', plan)
    print('PHONE_BACKFILL_PREVIEW', json.dumps({'project': plan['project'],
          'landlords': len(owners), 'updates': dict(Counter(c['path'].split('/')[0] for c in changes)),
          'syntheticPhones': sum(c['fields'].get('phoneIsSynthetic') is True for c in changes),
          'authPhoneNumbersModified': False}))


def nested_fields(fields):
    result = {}
    for dotted, value in fields.items():
        current = result
        parts = dotted.split('.')
        for part in parts[:-1]:
            current = current.setdefault(part, {'mapValue': {'fields': {}}})['mapValue']['fields']
        current[parts[-1]] = wire_value(value)
    return result


def value_at(data, dotted):
    for part in dotted.split('.'):
        data = data.get(part, {}) if isinstance(data, dict) else None
    return data


def apply():
    plan = read_plan()
    completed_path = WORK / 'completed.json'
    done = set(json.loads(completed_path.read_text()) if completed_path.exists() else [])
    for start in range(0, len(plan['changes']), 100):
        writes, paths = [], []
        for change in plan['changes'][start:start + 100]:
            path = change['path']
            if path in done:
                continue
            current = cloud('GET', base_url() + '/' + path)
            if all(value_at(decode_document(current), k) == v for k, v in change['fields'].items()):
                done.add(path)
                continue
            if current.get('updateTime') != change['updateTime']:
                raise ValueError('Document changed after preview: ' + path)
            writes.append({'update': {'name': current['name'], 'fields': nested_fields(change['fields'])},
                           'updateMask': {'fieldPaths': list(change['fields'])},
                           'currentDocument': {'updateTime': change['updateTime']}})
            paths.append(path)
        if writes:
            cloud('POST', base_url() + ':commit', {'writes': writes})
            done.update(paths)
        dump(completed_path, sorted(done))
        print('PHONE_BACKFILL_PROGRESS', len(done), '/', len(plan['changes']), flush=True)


def verify():
    plan = read_plan()
    before = json.loads((WORK / 'before.json').read_text(encoding='utf-8'))
    current = {**list_collection('users'), **list_collection('rental_properties')}
    for change in plan['changes']:
        path = change['path']
        actual = decode_document(current[path])
        expected = decode_document(before[path])
        for dotted, value in change['fields'].items():
            cursor = expected
            parts = dotted.split('.')
            for part in parts[:-1]:
                cursor = cursor.setdefault(part, {})
            cursor[parts[-1]] = value
        if actual != expected:
            raise ValueError('Read-back mismatch or unrelated field changed: ' + path)
    report = {'project': plan['project'], 'landlords': plan['landlords'],
              'verifiedUpdates': dict(Counter(c['path'].split('/')[0] for c in plan['changes'])),
              'authPhoneNumbersModified': False, 'unrelatedFieldsPreserved': True,
              'generatedPhonesAreContactSamplesOnly': True,
              'verifiedAt': datetime.now(timezone.utc).isoformat()}
    dump(ROOT / 'artifacts/BAO_CAO_BO_SUNG_SO_DIEN_THOAI.json', report)
    print('PHONE_BACKFILL_VERIFIED', json.dumps(report))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['preview', 'apply', 'verify'])
    globals()[parser.parse_args().action]()
