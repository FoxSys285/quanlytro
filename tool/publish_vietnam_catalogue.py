"""Publish the 34-province catalogue, preserving unrelated Firebase data.

Preview first. Replacement deletes only the earlier nt60 dataset authorized by the user.
Auth, Firestore and their journals are separate; each property group is committed atomically.
"""
import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from copy import deepcopy
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import sys

import requests

from collect_nationwide_rentals import (ROOT, cloud, decode_wire, dump, list_auth,
                                      project_config, verified_read, wire_value)
from generate_vietnam_catalogue import BATCH, WORK, OUTPUT, read_catalogue, summary, validate

COLLECTIONS = ['users', 'rental_properties', 'public_rooms', 'rental_records',
               'user_state', 'management', 'support_tickets']
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')


def base_url():
    project, _ = project_config()
    return f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'


def fingerprint(data):
    return hashlib.sha256(json.dumps(data, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def decode_document(doc):
    result = {k: decode_wire(v) for k, v in doc.get('fields', {}).items()}
    if 'createdAt' in result and 'timestampValue' in doc.get('fields', {}).get('createdAt', {}):
        result['createdAt'] = datetime.fromisoformat(result['createdAt'].replace('Z', '+00:00')).isoformat()
    return result


def list_collection(collection):
    from urllib.parse import quote
    result, page = {}, ''
    while True:
        response = verified_read('GET', base_url() + '/' + collection + '?pageSize=1000' + page,
                                 headers={'Authorization': 'Bearer ' + os.environ['FIREBASE_ACCESS_TOKEN']})
        if not response.ok:
            raise RuntimeError(f'Firestore collection read failed: {collection}, HTTP {response.status_code}')
        payload = response.json()
        for doc in payload.get('documents', []):
            result[doc['name'].split('/documents/')[1]] = doc
        if not payload.get('nextPageToken'):
            return result
        page = '&pageToken=' + quote(payload['nextPageToken'], safe='')


def source_documents():
    data = read_catalogue()
    validate(data)
    source = json.loads((WORK / 'cloud_documents.json').read_text(encoding='utf-8'))
    provenance = {p['propertyId']: p for p in data['provenance']}
    stores = {s['property']['id']: s for s in data['snapshot']['portfolio']['properties']}
    room_lookup = {pid: {r['code']: r for r in s['rooms']} for pid, s in stores.items()}
    for path, fields in source.items():
        pid = path.split('/')[1] if path.startswith('rental_properties/') else fields['propertyId']
        ref = provenance[pid]
        fields.update(importBatch=BATCH, isDemo=True, generation='synthetic',
                      provinceCode=ref['provinceCode'], wardCode=ref['wardCode'],
                      photosAreIllustrative=True)
        if path.startswith('rental_properties/'):
            fields['floorCount'] = ref['floors']
            fields['source'] = {'administrative': data['administrativeSource'],
                                'photos': ref['photoSources'], 'realAddressVerified': False}
        if path.startswith('public_rooms/'):
            room = room_lookup[pid][fields['roomCode']]
            fields.update(floor=room['floor'], roomTypeId=room['roomTypeId'])
    for owner in data['owners']:
        source['users/' + owner['ownerUid']] = {
            'email': owner['email'], 'displayName': owner['displayName'], 'role': 'landlord',
            'disabled': False, 'createdAt': data['createdAt'], 'importBatch': BATCH,
            'isDemo': True, 'photoURL': '',
        }
    if len(source) != summary(data)['rooms'] + 3 * 680:
        raise ValueError('Unexpected number of exported documents')
    if any('password' in fields for fields in source.values()):
        raise ValueError('No password field may be stored in Firestore')
    if max(len(json.dumps(fields, ensure_ascii=False).encode()) for fields in source.values()) >= 900000:
        raise ValueError('A document is too close to Firestore size limits')
    return source


def old_identity():
    old = json.loads((ROOT / '.local-backups/nationwide-rentals/plan.json').read_text(encoding='utf-8'))
    if old['project'] != project_config()[0] or len(old['items']) != 60:
        raise ValueError('Earlier catalogue must match the same Firebase project and 60 entries')
    return {i['propertyId'] for i in old['items']}, {i['ownerUid']: i['email'] for i in old['items']}


def old_document(path, fields, old_properties, old_owners):
    collection, doc_id = path.split('/')
    if collection == 'rental_properties':
        return doc_id in old_properties and fields.get('ownerUid') in old_owners
    if collection in {'public_rooms', 'rental_records'}:
        return fields.get('propertyId') in old_properties and fields.get('ownerUid') in old_owners
    if collection == 'users':
        return doc_id in old_owners and fields.get('email') == old_owners[doc_id]
    if collection in {'user_state', 'management'}:
        return doc_id in old_owners
    return collection == 'support_tickets' and fields.get('accountUid') in old_owners


def preview():
    path = WORK / 'publication-plan.json'
    if path.exists():
        raise ValueError('Publication plan already exists. Resume it without replacing its backups.')
    source = source_documents()
    data = read_catalogue()
    old_properties, old_owners = old_identity()
    before = {}
    for collection in COLLECTIONS:
        before.update(list_collection(collection))
    auth = list_auth(data['project'])
    if source.keys() & before.keys():
        raise ValueError('New document IDs already exist')
    new_ids = {o['ownerUid'] for o in data['owners']}
    new_emails = {o['email'] for o in data['owners']}
    if new_ids & auth.keys() or new_emails & {a.get('email') for a in auth.values()}:
        raise ValueError('New Auth UID/email already exists')
    deletions = {p: d for p, d in before.items() if old_document(p, decode_document(d), old_properties, old_owners)}
    for uid, email in old_owners.items():
        if uid in auth and auth[uid].get('email') != email:
            raise ValueError('Earlier account email changed; refusing an ambiguous deletion')
    dump(WORK / 'before-firestore.json', before)
    dump(WORK / 'before-auth-summary.json', auth)
    plan = {'project': data['project'], 'batch': BATCH, 'sourceHash': fingerprint(source),
            'deletePaths': sorted(deletions), 'deleteAuthUids': sorted(old_owners.keys() & auth.keys()),
            'newDocumentCount': len(source), 'newAuthCount': len(new_ids),
            'createdAt': datetime.now(timezone.utc).isoformat()}
    dump(path, plan)
    print('PUBLICATION_PREVIEW', json.dumps({**summary(data), 'newDocuments': len(source),
          'oldDocumentsToDelete': len(deletions), 'oldAccountsToDelete': len(plan['deleteAuthUids']),
          'unrelatedDocumentsPreserved': len(before) - len(deletions)}, ensure_ascii=False))


def checked_plan():
    plan = json.loads((WORK / 'publication-plan.json').read_text(encoding='utf-8'))
    source = source_documents()
    if plan['project'] != project_config()[0] or plan['sourceHash'] != fingerprint(source):
        raise ValueError('Data changed after publication preview')
    return plan, source


def provision_auth():
    plan, _ = checked_plan()
    data = read_catalogue()
    before = json.loads((WORK / 'before-auth-summary.json').read_text(encoding='utf-8'))
    existing = list_auth(data['project'])
    wanted = {o['ownerUid']: o for o in data['owners']}
    if wanted.keys() & before.keys():
        raise ValueError('A new UID existed before this import')
    pending = []
    for uid, owner in wanted.items():
        if uid in existing:
            if existing[uid].get('email') != owner['email'] or existing[uid].get('displayName') != owner['displayName']:
                raise ValueError('An existing UID no longer matches the import owner')
        else:
            if owner['email'] in {a.get('email') for a in existing.values()}:
                raise ValueError('Owner email collision')
            pending.append(owner)
    dump(WORK / 'auth-intents.json', {uid: o['email'] for uid, o in wanted.items()})
    done = set(wanted) & existing.keys()
    def create(owner):
        response = cloud('POST', f"https://identitytoolkit.googleapis.com/v1/projects/{data['project']}/accounts", {
            'localId': owner['ownerUid'], 'email': owner['email'], 'displayName': owner['displayName'],
            'password': owner['password'], 'disabled': False, 'emailVerified': False,
        })
        if response.get('localId') != owner['ownerUid']:
            raise ValueError('Unexpected Firebase UID')
        return owner['ownerUid']
    errors = []
    with ThreadPoolExecutor(max_workers=5) as pool:
        futures = {pool.submit(create, owner): owner['ownerUid'] for owner in pending}
        for future in as_completed(futures):
            try:
                done.add(future.result())
                if len(done) % 50 == 0:
                    dump(WORK / 'auth-completed.json', sorted(done))
                    print('AUTH_PROVISIONED', len(done), '/ 680', flush=True)
            except Exception:
                errors.append(futures[future])
    dump(WORK / 'auth-completed.json', sorted(done))
    if errors:
        dump(WORK / 'auth-retry-uids.json', errors)
        raise RuntimeError(f'{len(errors)} Auth requests need a resume; no passwords printed')
    if len(done) != plan['newAuthCount']:
        raise ValueError('Incomplete Auth creation')
    print('AUTH_PROVISIONING_COMPLETE', len(done))


def delete_previous():
    plan, _ = checked_plan()
    before = json.loads((WORK / 'before-firestore.json').read_text(encoding='utf-8'))
    old_properties, old_owners = old_identity()
    completed_path = WORK / 'old-deletion-completed.json'
    if completed_path.exists():
        print('EARLIER_DATASET_ALREADY_REMOVED')
        return
    # The user explicitly authorized deletion of these 60 generated houses/accounts.
    writes = []
    found = cloud('POST', base_url() + ':batchGet', {
        'documents': [before[path]['name'] for path in plan['deletePaths']]}) if plan['deletePaths'] else []
    live_documents = {result['found']['name']: result['found'] for result in found if 'found' in result}
    for path in plan['deletePaths']:
        doc = before[path]
        if not old_document(path, decode_document(doc), old_properties, old_owners):
            raise ValueError('Deletion is outside the original nt60 dataset')
        live = live_documents.get(doc['name'])
        if live is None:
            continue
        if not old_document(path, decode_document(live), old_properties, old_owners):
            raise ValueError('Deletion target identity changed')
        # Save the most recent document before deleting; precondition rejects concurrent edits.
        dump(WORK / 'delete-backups' / (fingerprint(path) + '.json'), live)
        writes.append({'delete': live['name'], 'currentDocument': {'updateTime': live['updateTime']}})
    for offset in range(0, len(writes), 400):
        cloud('POST', base_url() + ':commit', {'writes': writes[offset:offset + 400]})
    auth = list_auth(plan['project'])
    uids = [uid for uid in plan['deleteAuthUids'] if uid in auth]
    if any(auth[uid].get('email') != old_owners[uid] for uid in uids):
        raise ValueError('Old Auth identity changed')
    if uids:
        result = cloud('POST', f"https://identitytoolkit.googleapis.com/v1/projects/{plan['project']}/accounts:batchDelete",
                       {'localIds': uids, 'force': True})
        if result.get('errors'):
            raise RuntimeError('Some previous accounts were not removed; inspect and resume')
    dump(completed_path, {'documents': len(plan['deletePaths']), 'authAccounts': len(plan['deleteAuthUids']),
                          'completedAt': datetime.now(timezone.utc).isoformat()})
    print('EARLIER_DATASET_REMOVED', len(plan['deletePaths']), 'documents,', len(plan['deleteAuthUids']), 'accounts')


def property_groups(source):
    groups = {}
    for path, fields in source.items():
        collection, doc_id = path.split('/')
        pid = doc_id if collection in {'users', 'rental_properties'} else fields['propertyId']
        groups.setdefault(pid, {})[path] = fields
    return groups


def publish():
    plan, source = checked_plan()
    if not (WORK / 'old-deletion-completed.json').exists():
        raise ValueError('Remove the previous dataset before publishing the replacement')
    data = read_catalogue()
    auth = list_auth(data['project'])
    if any(auth.get(o['ownerUid'], {}).get('email') != o['email'] for o in data['owners']):
        raise ValueError('Create all owner Auth accounts before publishing')
    groups = property_groups(source)
    # Resume by reading the target collections; exact matches are safe to skip.
    existing = {}
    for collection in ['users', 'rental_properties', 'rental_records', 'public_rooms']:
        existing.update(list_collection(collection))
    ready = []
    for pid, group in groups.items():
        found = group.keys() & existing.keys()
        if found and found != group.keys():
            raise ValueError('Partial property group found; refusing to overwrite')
        if found:
            if any(decode_document(existing[p]) != fields for p, fields in group.items()):
                raise ValueError('An existing target differs from the planned import')
            continue
        ready.append((pid, group))
    commits, current, current_ids = [], {}, []
    for pid, group in ready:
        if len(current) + len(group) > 400:
            commits.append((current_ids, current))
            current, current_ids = {}, []
        current.update(group)
        current_ids.append(pid)
    if current:
        commits.append((current_ids, current))
    journal = []
    journal_path = WORK / 'firestore-commits.json'
    if journal_path.exists():
        journal = json.loads(journal_path.read_text(encoding='utf-8'))
    for index, (ids, group) in enumerate(commits, 1):
        writes = []
        for path, fields in group.items():
            wire = {key: wire_value(value) for key, value in fields.items()}
            if path.startswith('users/'):
                wire['createdAt'] = {'timestampValue': fields['createdAt']}
            writes.append({'update': {'name': base_url().split('/v1/')[1] + '/' + path, 'fields': wire},
                           'currentDocument': {'exists': False}})
        response = cloud('POST', base_url() + ':commit', {'writes': writes})
        journal.append({'properties': ids, 'documents': len(group), 'commitTime': response['commitTime']})
        dump(journal_path, journal)
        print('FIRESTORE_COMMIT', index, '/', len(commits), 'properties', len(ids), 'documents', len(group), flush=True)
    print('CATALOGUE_PUBLISHED', len(source), 'documents')


def verify():
    plan, expected = checked_plan()
    data = read_catalogue()
    current = {}
    for collection in COLLECTIONS:
        current.update(list_collection(collection))
        print('COLLECTION_READ', collection, flush=True)
    for path, fields in expected.items():
        if path not in current or decode_document(current[path]) != fields:
            raise ValueError('Firebase read-back mismatch: ' + path)
    old_properties, old_owners = old_identity()
    if any(old_document(p, decode_document(d), old_properties, old_owners) for p, d in current.items()):
        raise ValueError('Some earlier dataset documents remain')
    before = json.loads((WORK / 'before-firestore.json').read_text(encoding='utf-8'))
    protected = {p: d for p, d in before.items() if p not in plan['deletePaths']}
    for path, previous in protected.items():
        if path not in current or current[path]['fields'] != previous['fields']:
            raise ValueError('An unrelated document changed: ' + path)
    auth = list_auth(data['project'])
    if auth.keys() & old_owners.keys():
        raise ValueError('An earlier owner account remains')
    previous_auth = json.loads((WORK / 'before-auth-summary.json').read_text(encoding='utf-8'))
    protected_auth = {uid: account for uid, account in previous_auth.items() if uid not in plan['deleteAuthUids']}
    if any(auth.get(uid) != account for uid, account in protected_auth.items()):
        raise ValueError('An unrelated Auth account changed')
    for owner in data['owners']:
        fields = auth.get(owner['ownerUid'], {})
        if fields.get('email') != owner['email'] or fields.get('displayName') != owner['displayName'] or fields.get('disabled', False):
            raise ValueError('Owner Auth record mismatch')
    _, key = project_config()
    def sign_in(owner):
        response = verified_read('POST', 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' + key,
                                 json={'email': owner['email'], 'password': owner['password'], 'returnSecureToken': True})
        if not response.ok or response.json().get('localId') != owner['ownerUid']:
            raise ValueError('Owner password sign-in failed: ' + owner['ownerUid'])
        identity = response.json()
        headers = {'Authorization': 'Bearer ' + identity['idToken']}
        if owner['ownerUid'].endswith('-001'):
            for suffix in ['users/' + owner['ownerUid'], 'rental_properties/' + owner['ownerUid']]:
                doc = verified_read('GET', base_url() + '/' + suffix, headers=headers)
                if not doc.ok:
                    raise ValueError('Owner cannot read its own data')
        return owner['ownerUid']
    signed_in = 0
    with ThreadPoolExecutor(max_workers=5) as pool:
        for uid in pool.map(sign_in, data['owners']):
            signed_in += 1
            if signed_in % 100 == 0:
                print('PASSWORD_SIGN_INS_VERIFIED', signed_in, '/ 680', flush=True)
    photo_pool = json.loads((WORK / 'photo-pool.json').read_text(encoding='utf-8'))
    assigned_photos = {p['url'] for store in data['snapshot']['portfolio']['properties']
                       for room_type in store['roomTypes'] for p in room_type['photos']}
    report = {**summary(data), 'project': data['project'], 'batch': BATCH,
              'verifiedAt': datetime.now(timezone.utc).isoformat(),
              'verifiedDocuments': len(expected), 'verifiedPasswordSignIns': signed_in,
              'previousDocumentsDeleted': len(plan['deletePaths']), 'previousAccountsDeleted': len(plan['deleteAuthUids']),
              'unrelatedDocumentsPreserved': len(protected), 'unrelatedAuthAccountsPreserved': len(protected_auth),
              'verifiedPhotoPoolAlbums': len(photo_pool['albums']), 'verifiedPhotoPoolUrls': photo_pool['verifiedPhotoUrls'],
              'assignedUniquePhotoUrls': len(assigned_photos), 'floorRange': [1, 10], 'roomsPerFloorRange': [2, 12],
              'roomTypesPerPropertyRange': [2, 5], 'roomCodeExamples': ['P.101', 'P.201', 'P.1001'],
              'syntheticCatalogue': True, 'passwordsStoredInFirestore': False,
              'administrativeSource': data['administrativeSource'], 'officialSource': data['officialSource']}
    dump(ROOT / 'artifacts/BAO_CAO_680_NHA_TRO.json', report)
    dump(WORK / 'verification.json', report)
    print('PUBLISHED_AND_VERIFIED', json.dumps(report, ensure_ascii=False))


def main():
    actions = {'preview': preview, 'auth': provision_auth, 'delete-old': delete_previous,
               'publish': publish, 'verify': verify}
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=actions)
    actions[parser.parse_args().action]()


if __name__ == '__main__':
    main()
