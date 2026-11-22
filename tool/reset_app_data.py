"""Back up and reset this app's Firebase data using the existing CLI login.

Run through with_firebase_cli.cjs. Prepare is read-only; apply consumes an
explicit backup directory and checks the configured project before deletion.
"""
import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
from urllib.error import HTTPError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
PROJECT = 'tropremium-d14ac'
BASE = f'https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents'
AUTH = f'https://identitytoolkit.googleapis.com/v1/projects/{PROJECT}/accounts'


def request(method, url, data=None, binary=False):
    payload = None if data is None else json.dumps(data).encode()
    headers = {'Authorization': 'Bearer ' + os.environ['FIREBASE_ACCESS_TOKEN']}
    if payload is not None:
        headers['Content-Type'] = 'application/json'
    try:
        with urlopen(Request(url, data=payload, headers=headers, method=method), timeout=60) as response:
            body = response.read()
            return body if binary else json.loads(body) if body else {}
    except HTTPError as error:
        # Never echo response bodies that might include account information.
        raise RuntimeError(f'{method} {url.split("?")[0]} failed: HTTP {error.code}') from None


def dump(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding='utf-8')


def validate_project():
    configured = json.loads((ROOT / '.firebaserc').read_text(encoding='utf-8'))['projects']['default']
    projects = set(re.findall(r"projectId:\s*'([^']+)'", (ROOT / 'lib/firebase_options.dart').read_text(encoding='utf-8')))
    if configured != PROJECT or projects != {PROJECT}:
        raise RuntimeError('Firebase configuration does not match reset target')


def documents():
    result, cursor = [], None
    while True:
        query = {
            'from': [{'allDescendants': True}],
            'orderBy': [{'field': {'fieldPath': '__name__'}}],
            'limit': 500,
        }
        if cursor:
            query['startAt'] = {'values': [{'referenceValue': cursor}], 'before': False}
        rows = request('POST', BASE + ':runQuery', {'structuredQuery': query})
        page = [row['document'] for row in rows if 'document' in row]
        result.extend(page)
        if len(page) < 500:
            return result
        cursor = page[-1]['name']
        if len(result) % 2500 == 0:
            print(json.dumps({'firestoreDocumentsRead': len(result)}), flush=True)


def users():
    result, page = [], ''
    while True:
        params = {'maxResults': 1000}
        if page:
            params['nextPageToken'] = page
        data = request('GET', AUTH + ':batchGet?' + urlencode(params))
        result.extend(data.get('users', []))
        page = data.get('nextPageToken')
        if not page:
            return result


def storage_objects():
    result, page = [], ''
    while True:
        params = {'project': PROJECT, 'maxResults': 1000}
        if page:
            params['pageToken'] = page
        data = request('GET', 'https://storage.googleapis.com/storage/v1/b?' + urlencode(params))
        for bucket in data.get('items', []):
            object_page = ''
            while True:
                query = {'maxResults': 1000, 'versions': 'true'}
                if object_page:
                    query['pageToken'] = object_page
                objects = request('GET', f'https://storage.googleapis.com/storage/v1/b/{quote(bucket["name"], safe="")}/o?' + urlencode(query))
                result.extend(objects.get('items', []))
                object_page = objects.get('nextPageToken')
                if not object_page:
                    break
        page = data.get('nextPageToken')
        if not page:
            return result


def prepare():
    target = ROOT / '.local-backups' / ('app-reset-' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
    if target.exists():
        raise RuntimeError('Backup directory already exists')
    target.mkdir(parents=True)
    with ThreadPoolExecutor(max_workers=3) as pool:
        futures = [pool.submit(fn) for fn in (documents, users, storage_objects)]
        docs, accounts, objects = [future.result() for future in futures]
    dump(target / 'firestore.json', docs)
    dump(target / 'auth.json', accounts)
    dump(target / 'storage.json', objects)
    for index, item in enumerate(objects):
        url = f'https://storage.googleapis.com/storage/v1/b/{quote(item["bucket"], safe="")}/o/{quote(item["name"], safe="")}?'
        url += urlencode({'alt': 'media', 'generation': item['generation']})
        content = request('GET', url, binary=True)
        asset = target / 'storage-files' / f'{index:08d}.bin'
        asset.parent.mkdir(parents=True, exist_ok=True)
        asset.write_bytes(content)
    manifest = {
        'project': PROJECT,
        'backupDirectory': str(target),
        'firestoreDocuments': len(docs),
        'collections': dict(Counter(doc['name'].split('/documents/')[1].split('/')[0] for doc in docs)),
        'authUsers': len(accounts),
        'storageObjects': len(objects),
        'status': 'backed-up',
    }
    dump(target / 'manifest.json', manifest)
    print(json.dumps(manifest), flush=True)


def apply(target):
    target = Path(target).resolve()
    if target.parent != (ROOT / '.local-backups').resolve():
        raise RuntimeError('Expected a backup directory inside this workspace')
    manifest = json.loads((target / 'manifest.json').read_text(encoding='utf-8'))
    if manifest['project'] != PROJECT or manifest['status'] != 'backed-up':
        raise RuntimeError('Backup project/status mismatch')
    docs = json.loads((target / 'firestore.json').read_text(encoding='utf-8'))
    accounts = json.loads((target / 'auth.json').read_text(encoding='utf-8'))
    objects = json.loads((target / 'storage.json').read_text(encoding='utf-8'))
    live_docs, live_users = documents(), users()
    if {doc['name']: doc['updateTime'] for doc in docs} != {doc['name']: doc['updateTime'] for doc in live_docs}:
        raise RuntimeError('Firestore changed after backup; prepare a fresh backup')
    if {user['localId'] for user in accounts} != {user['localId'] for user in live_users}:
        raise RuntimeError('Auth users changed after backup; prepare a fresh backup')
    # Delete exactly backed-up accounts first, so their sessions cannot create
    # fresh data while Firestore is being cleared. Never delete project config.
    for start in range(0, len(accounts), 1000):
        response = request('POST', AUTH + ':batchDelete', {
            'localIds': [user['localId'] for user in accounts[start:start + 1000]],
            'force': True,
        })
        if response.get('errors'):
            raise RuntimeError('Some Auth users could not be deleted; see backup before retry')
    for start in range(0, len(docs), 400):
        batch = docs[start:start + 400]
        request('POST', BASE + ':commit', {'writes': [
            {'delete': doc['name'], 'currentDocument': {'updateTime': doc['updateTime']}}
            for doc in batch
        ]})
        print(json.dumps({'firestoreDocumentsDeleted': min(start + 400, len(docs))}), flush=True)
    for item in objects:
        url = f'https://storage.googleapis.com/storage/v1/b/{quote(item["bucket"], safe="")}/o/{quote(item["name"], safe="")}?'
        request('DELETE', url + urlencode({'generation': item['generation'], 'ifGenerationMatch': item['generation']}))
    remaining = {'firestoreDocuments': len(documents()), 'authUsers': len(users()), 'storageObjects': len(storage_objects())}
    manifest.update(status='reset' if not any(remaining.values()) else 'incomplete', remaining=remaining)
    dump(target / 'manifest.json', manifest)
    print(json.dumps({'project': PROJECT, 'status': manifest['status'], 'remaining': remaining}), flush=True)
    if any(remaining.values()):
        raise RuntimeError('New data appeared during reset; inspect before proceeding')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['prepare', 'apply'])
    parser.add_argument('--backup')
    args = parser.parse_args()
    validate_project()
    if args.action == 'prepare':
        prepare()
    elif not args.backup:
        parser.error('apply requires --backup')
    else:
        apply(args.backup)
