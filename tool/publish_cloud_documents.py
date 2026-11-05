"""Publish exported documents with backups and optimistic concurrency.
Run export_cloud_data_test.dart first. Without --apply this is a preview.
"""
import argparse
import datetime as dt
import getpass
import json
import os
from pathlib import Path
import re
import urllib.error
from urllib.parse import quote
import urllib.request
import warnings
from update_demo_firestore import ROOT, BASE, WORK

_session_token = None


def request(url, data=None):
    headers = {'Content-Type': 'application/json'}
    token = _session_token or os.environ.get('FIREBASE_ACCESS_TOKEN')
    if token and url.startswith(BASE):
        headers['Authorization'] = 'Bearer ' + token
    payload = None if data is None else json.dumps(data, ensure_ascii=False).encode('utf-8')
    with urllib.request.urlopen(urllib.request.Request(url, data=payload, headers=headers), timeout=40) as response:
        return json.load(response)


def sign_in_admin(email):
    """Password and ID token stay in this process; never write a credential file."""
    global _session_token
    _session_token = None
    config = (ROOT / 'lib/firebase_options.dart').read_text(encoding='utf-8')
    web = re.search(r'FirebaseOptions web\s*=\s*FirebaseOptions\((.*?)\);', config, re.S)
    key = re.search(r"apiKey:\s*'([^']+)'", web.group(1)) if web else None
    project = re.search(r"projectId:\s*'([^']+)'", web.group(1)) if web else None
    if key is None or project is None or f'/projects/{project.group(1)}/' not in BASE:
        raise ValueError('Không đọc được cấu hình Firebase web đúng project')
    with warnings.catch_warnings():
        warnings.simplefilter('error', getpass.GetPassWarning)
        try:
            password = getpass.getpass('Firebase password (hidden): ')
        except getpass.GetPassWarning:
            raise ValueError('Chạy trong terminal hỗ trợ nhập mật khẩu ẩn; không truyền mật khẩu bằng tham số') from None
    try:
        account = request('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' + quote(key.group(1), safe=''),
                          {'email': email, 'password': password, 'returnSecureToken': True})
    finally:
        password = None
    uid = account.get('localId')
    token = account.get('idToken')
    if not isinstance(uid, str) or not uid or '/' in uid or not isinstance(token, str) or not token:
        raise ValueError('Đăng nhập không trả về UID/token hợp lệ')
    if account.get('email', email).casefold() != email.casefold():
        raise ValueError('Email đăng nhập không khớp tài khoản trả về')
    _session_token = token
    try:
        profile = request(BASE + '/users/' + quote(uid, safe=''))
        expected = BASE.split('/v1/')[1] + '/users/' + uid
        fields = {name: decode(value) for name, value in profile.get('fields', {}).items()}
        if profile.get('name') != expected or fields.get('role') != 'admin' or fields.get('disabled') is not False:
            raise ValueError('Chỉ tài khoản admin đang hoạt động được import dữ liệu')
    except Exception:
        _session_token = None
        raise
    return uid


def value(item):
    if item is None:
        return {'nullValue': None}
    if isinstance(item, bool):
        return {'booleanValue': item}
    if isinstance(item, int):
        return {'integerValue': str(item)}
    if isinstance(item, float):
        return {'doubleValue': item}
    if isinstance(item, str):
        return {'stringValue': item}
    if isinstance(item, list):
        return {'arrayValue': {'values': [value(v) for v in item]}}
    return {'mapValue': {'fields': {k: value(v) for k, v in item.items()}}}


def decode(item):
    if 'mapValue' in item:
        return {k: decode(v) for k, v in item['mapValue'].get('fields', {}).items()}
    if 'arrayValue' in item:
        return [decode(v) for v in item['arrayValue'].get('values', [])]
    if 'integerValue' in item:
        return int(item['integerValue'])
    return next(iter(item.values()))


def validate_create_source(source):
    if not source or len(source) > 450:
        raise ValueError('Mỗi đợt import cần 1–450 document để ghi nguyên tử; chia workbook theo nhà')
    properties = {path.split('/')[1]: data for path, data in source.items()
                  if path.startswith('rental_properties/') and len(path.split('/')) == 2}
    if not properties:
        raise ValueError('Import cần ít nhất một nhà mới')
    for path, data in source.items():
        parts = path.split('/')
        if len(parts) != 2 or parts[0] not in {'rental_properties', 'public_rooms', 'rental_records'}:
            raise ValueError('Import danh mục không được tạo/sửa tài khoản hoặc quản trị')
        property_id = parts[1] if parts[0] == 'rental_properties' else data.get('propertyId')
        prop = properties.get(property_id)
        if prop is None or not isinstance(data.get('ownerUid'), str) or data['ownerUid'] != prop.get('ownerUid'):
            raise ValueError('Document chưa có nhà mới/chủ sở hữu nhất quán: ' + path)
        if parts[0] == 'rental_properties' and data.get('data', {}).get('property', {}).get('id') != property_id:
            raise ValueError('Mã nhà không khớp document: ' + path)
        if parts[0] == 'rental_records' and (data.get('kind') != 'settings' or data.get('tenantIds') != []):
            raise ValueError('Import nhà mới không được tạo nghiệp vụ/người thuê: ' + path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--source', type=Path, default=WORK / 'cloud_documents.json')
    parser.add_argument('--create-only', action='store_true', help='Rental catalogue import: reject existing IDs; one atomic commit')
    parser.add_argument('--admin-email', help='Firebase admin email; prompts privately for password in terminal')
    args = parser.parse_args()
    source_path = args.source.resolve()
    if not source_path.is_relative_to(ROOT):
        raise ValueError('--source phải nằm trong workspace')
    source = json.loads(source_path.read_text(encoding='utf-8'))
    if not isinstance(source, dict) or not source:
        raise ValueError('Không có document để publish')
    allowed = {'public_rooms', 'rental_properties', 'rental_records', 'users', 'management', 'support_tickets', 'public_settings'}
    if not all(isinstance(data, dict) and path.split('/')[0] in allowed and
               len(path.split('/')) == 2 for path, data in source.items()):
        raise ValueError('Collection, document hoặc cấu trúc dữ liệu không được hỗ trợ')
    if args.create_only:
        validate_create_source(source)
    if args.admin_email:
        sign_in_admin(args.admin_email)
    if args.create_only and args.apply and not (_session_token or os.environ.get('FIREBASE_ACCESS_TOKEN')):
        raise ValueError('Dùng --admin-email EMAIL để đăng nhập admin hoặc FIREBASE_ACCESS_TOKEN; không ghi mật khẩu/token vào file')
    previous = {}
    for collection in {path.split('/')[0] for path in source}:
        page = ''
        while True:
            response = request(BASE + '/' + collection + '?pageSize=1000' + page)
            previous.update({d['name'].split('/documents/')[1]: d for d in response.get('documents', [])})
            token = response.get('nextPageToken')
            if not token:
                break
            from urllib.parse import quote
            page = '&pageToken=' + quote(token, safe='')
    if args.create_only:
        conflicts = source.keys() & previous.keys()
        if conflicts:
            raise ValueError('Chỉ tạo mới; document đã tồn tại: ' + ', '.join(sorted(conflicts)[:5]))
        for uid in {data['ownerUid'] for path, data in source.items() if path.startswith('rental_properties/')}:
            from urllib.parse import quote
            profile = request(BASE + '/users/' + quote(uid, safe=''))
            fields = {key: decode(value) for key, value in profile.get('fields', {}).items()}
            if fields.get('role') != 'landlord' or fields.get('disabled') is not False:
                raise ValueError('ownerUid chưa có hồ sơ chủ trọ đang hoạt động: ' + uid)
    WORK.mkdir(parents=True, exist_ok=True)
    stamp = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    (WORK / f'cloud-backup-{stamp}.json').write_text(json.dumps(previous, ensure_ascii=False), encoding='utf-8')
    writes = []
    prefix = BASE.split('/v1/')[1]
    for path, data in source.items():
        fields = {key: value(v) for key, v in data.items()}
        old = previous.get(path)
        if old and {k: decode(v) for k, v in old['fields'].items()} == data:
            continue
        if len(json.dumps(fields, ensure_ascii=False).encode()) >= 950_000:
            raise ValueError('Document vượt giới hạn dung lượng: ' + path)
        writes.append({'update': {'name': prefix + '/' + path, 'fields': fields},
            'currentDocument': {'updateTime': old['updateTime']} if old else {'exists': False}})
    print(f'{len(source)} exported documents, {len(writes)} changed. Backup is inside .dart_tool/demo_data.', flush=True)
    if not args.apply:
        print('PREVIEW_ONLY')
        return
    chunk_size = 450 if args.create_only else 100
    for offset in range(0, len(writes), chunk_size):
        request(BASE + ':commit', {'writes': writes[offset:offset + chunk_size]})
    # Verify the complete collection after publishing, not just the final write.
    for collection in {path.split('/')[0] for path in source}:
        count = 0
        page = ''
        while True:
            response = request(BASE + '/' + collection + '?pageSize=1000' + page)
            for doc in response.get('documents', []):
                path = doc['name'].split('/documents/')[1]
                if path in source:
                    if {k: decode(v) for k, v in doc['fields'].items()} != source[path]:
                        raise RuntimeError('Dữ liệu đọc lại không khớp: ' + path)
                    count += 1
            token = response.get('nextPageToken')
            if not token:
                break
            from urllib.parse import quote
            page = '&pageToken=' + quote(token, safe='')
        if count != sum(path.startswith(collection + '/') for path in source):
            raise RuntimeError('Chưa đọc lại đủ document: ' + collection)
        print(f'{collection}: verified {count} documents', flush=True)
    print('PUBLISHED_AND_VERIFIED')


if __name__ == '__main__':
    main()
