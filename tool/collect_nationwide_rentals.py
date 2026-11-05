"""Collect public listing references and prepare a labeled teaching catalogue.

Original templates and existing Firebase accounts/documents are never overwritten.
"""
import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import sys
import time
import unicodedata

import requests
from openpyxl import load_workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.worksheet.table import Table, TableStyleInfo

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / '.local-backups/nationwide-rentals'
TEMPLATE = ROOT / 'artifacts/MAU_THU_THAP_NHA_TRO.xlsx'
OUTPUT = ROOT / 'artifacts/DU_LIEU_60_NHA_TRO.xlsx'
API = 'https://gateway.chotot.com/v1/public/ad-listing'
QUERIES = ['Hà Nội', 'Hải Phòng', 'Bắc Ninh', 'Thái Nguyên', 'Huế',
           'Đà Nẵng', 'Nghệ An', 'Khánh Hòa', 'Đắk Lắk', 'Lâm Đồng',
           'Hồ Chí Minh', 'Cần Thơ', 'Đồng Nai', 'An Giang']
REGIONS = [
    (12000, 'Hà Nội', 'Bắc', 16), (4019, 'Hải Phòng', 'Bắc', 4),
    (6040, 'Huế', 'Trung', 4), (3017, 'Đà Nẵng', 'Trung', 5),
    (7044, 'Khánh Hòa', 'Trung', 3), (9053, 'Đắk Lắk', 'Trung', 4),
    (9057, 'Lâm Đồng', 'Trung', 4),
    (13000, 'TP. Hồ Chí Minh', 'Nam', 8), (5027, 'Cần Thơ', 'Nam', 6),
    (2013, 'Đồng Nai', 'Nam', 4), (5024, 'An Giang', 'Nam', 2),
]
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')


def dump(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')


def project_config():
    project = json.loads((ROOT / '.firebaserc').read_text(encoding='utf-8'))['projects']['default']
    config = (ROOT / 'lib/firebase_options.dart').read_text(encoding='utf-8')
    web = re.search(r'FirebaseOptions web\s*=\s*FirebaseOptions\((.*?)\);', config, re.S).group(1)
    if re.search(r"projectId:\s*'([^']+)'", web).group(1) != project:
        raise ValueError('Firebase CLI and Flutter project IDs differ')
    key = re.search(r"apiKey:\s*'([^']+)'", web).group(1)
    return project, key


def verified_read(method, url, **kwargs):
    """Retry only reads/sign-in checks; account creation and commits are not retried."""
    for attempt in range(4):
        try:
            response = requests.request(method, url, timeout=30, **kwargs)
            if response.status_code not in {429, 500, 502, 503, 504} or attempt == 3:
                return response
        except requests.exceptions.RequestException:
            if attempt == 3:
                raise RuntimeError('Read/sign-in verification failed after four network attempts') from None
        time.sleep(attempt + 1)


def cloud(method, url, data=None, allow_missing=False):
    token = os.environ.get('FIREBASE_ACCESS_TOKEN')
    if not token:
        raise ValueError('Run through tool/with_firebase_cli.cjs')
    response = requests.request(method, url, json=data,
                                headers={'Authorization': 'Bearer ' + token}, timeout=40)
    if allow_missing and response.status_code == 404:
        return None
    if not response.ok:
        # Avoid including request bodies, passwords, tokens, or Auth responses.
        try:
            code = response.json().get('error', {}).get('message', 'unknown')
        except ValueError:
            code = 'non-JSON error'
        raise RuntimeError(f'Cloud request failed: {response.status_code} {code}')
    return response.json()


def probe():
    project, _ = project_config()
    cloud('GET', f'https://firebase.googleapis.com/v1beta1/projects/{project}')
    base = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
    result = cloud('GET', base + '/rental_properties?pageSize=1')
    auth = cloud('GET', f'https://identitytoolkit.googleapis.com/v1/projects/{project}/accounts:batchGet?maxResults=1')
    print(json.dumps({'project': project, 'firestoreAccessible': True,
                      'authAccessible': True, 'samplePropertyCount': len(result.get('documents', [])),
                      'sampleAccountCount': len(auth.get('users', []))}))


def fetch_query(query):
    parameters = {'cg': 1050, 'limit': 100, 'o': 0, 'st': 'u,h', 'w': 1, 'q': query}
    response = requests.get(API, params=parameters, timeout=30)
    response.raise_for_status()
    data = response.json()
    return {'query': query, 'url': response.url, 'total': data.get('total', 0), 'ads': data.get('ads', [])}


def collect():
    WORK.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(max_workers=4) as pool:
        responses = list(pool.map(fetch_query, QUERIES))
    dump(WORK / 'collected.json', {'collectedAt': datetime.now(timezone.utc).isoformat(), 'responses': responses})
    for result in responses:
        regions = Counter((ad.get('region_v2'), ad.get('region_name')) for ad in result['ads'])
        print(result['query'], result['total'], regions.most_common(4))


def fetch_region(region):
    code, city, zone, count = region
    response = requests.get(API, params={'cg': 1050, 'limit': 50, 'o': 0,
                                        'st': 'u,h', 'w': 1, 'region_v2': code}, timeout=30)
    response.raise_for_status()
    data = response.json()
    return {'code': code, 'city': city, 'zone': zone, 'count': count,
            'url': response.url, 'total': data.get('total', 0), 'ads': data.get('ads', [])}


def collect_regions():
    with ThreadPoolExecutor(max_workers=4) as pool:
        responses = list(pool.map(fetch_region, REGIONS))
    dump(WORK / 'regions.json', {'collectedAt': datetime.now(timezone.utc).isoformat(), 'responses': responses})
    for result in responses:
        valid = [ad for ad in result['ads'] if ad.get('region_v2') == result['code']
                 and ad.get('street_name') and ad.get('ward_name') and ad.get('images')
                 and 6 <= (ad.get('size') or 0) <= 500 and 0 < (ad.get('price') or 0) <= 1000000000]
        print(result['city'], 'available', result['total'], 'usable', len(valid), 'need', result['count'])


def normalized(text):
    return ''.join(c for c in unicodedata.normalize('NFD', text.lower())
                   if unicodedata.category(c) != 'Mn').replace('đ', 'd')


def prepare():
    """Create a reviewable local plan, with no Firebase writes."""
    raw = json.loads((WORK / 'regions.json').read_text(encoding='utf-8'))
    by_region = {r['code']: r for r in raw['responses']}
    selected, seen_ids, seen_addresses = [], set(), set()
    for code, city, zone, count in REGIONS:
        candidates = by_region[code]['ads']
        accepted = 0
        for ad in candidates:
            if (ad.get('region_v2') != code or not ad.get('street_name') or not ad.get('ward_name')
                    or not ad.get('images') or not isinstance(ad.get('list_id'), int)
                    or not 6 <= (ad.get('size') or 0) <= 500
                    or int(ad['size']) != ad['size']
                    or not 500000 <= (ad.get('price') or 0) <= 100000000):
                continue
            address_key = (code, normalized(ad['street_name'].strip()), normalized(ad['ward_name'].strip()))
            if ad['list_id'] in seen_ids or address_key in seen_addresses:
                continue
            photos = [u for u in ad['images'] if isinstance(u, str) and u.startswith('https://cdn.chotot.com/')][:6]
            if not photos:
                continue
            seen_ids.add(ad['list_id'])
            seen_addresses.add(address_key)
            index = len(selected) + 1
            listing_id = str(ad['list_id'])
            selected.append({
                'propertyId': 'nt60-' + listing_id,
                'ownerUid': 'nt60-owner-' + listing_id,
                'email': 'nt60.owner.' + listing_id + '@example.com',
                'password': 'Tro!9a' + secrets.token_urlsafe(15),
                'displayName': f'[MẪU] Chủ trọ {index:02d}',
                'sourceListingId': listing_id,
                'sourceUrl': f'https://www.nhatot.com/{listing_id}.htm',
                'sourceApiUrl': by_region[code]['url'],
                'sourceTitle': ad.get('subject', ''),
                'sourceRegion': ad['region_name'], 'sourceWard': ad['ward_name'],
                'city': city, 'zone': zone, 'street': ad['street_name'].strip(),
                'district': ad.get('area_name', ''), 'ward': ad['ward_name'].strip(),
                'monthlyRent': int(ad['price']), 'area': int(ad['size']), 'photos': photos,
                'collectedAt': raw['collectedAt'], 'photoChecked': False,
                'latitude': ad.get('latitude'), 'longitude': ad.get('longitude'),
            })
            accepted += 1
            if accepted == count:
                break
        if accepted != count:
            raise ValueError(f'{city}: only {accepted}/{count} distinct usable references')
    if len(selected) != 60 or Counter(r['zone'] for r in selected) != {'Bắc': 20, 'Trung': 20, 'Nam': 20}:
        raise ValueError('Expected exactly 20 references per region')
    # Preserve the first credential plan so a rerun can never replace existing passwords.
    path = WORK / 'plan.json'
    if path.exists():
        raise ValueError('Plan already exists; use the existing plan instead of rotating passwords')
    dump(path, {'project': project_config()[0], 'createdAt': datetime.now(timezone.utc).isoformat(),
                'items': selected})
    print('LOCAL_PLAN_READY', json.dumps({'properties': 60, 'owners': 60, 'rooms': 60,
          'byZone': dict(Counter(r['zone'] for r in selected)),
          'byCity': dict(Counter(r['city'] for r in selected))}, ensure_ascii=False))


def read_plan():
    plan = json.loads((WORK / 'plan.json').read_text(encoding='utf-8'))
    if plan['project'] != project_config()[0] or len(plan['items']) != 60:
        raise ValueError('Plan/project mismatch')
    return plan


def check_photos():
    plan = read_plan()
    def check(item):
        # Verify at least the cover rather than assuming a syntactically valid URL works.
        with requests.get(item['photos'][0], stream=True, timeout=25) as response:
            response.raise_for_status()
            if not response.headers.get('Content-Type', '').startswith('image/'):
                raise ValueError('Cover is not an image: ' + item['propertyId'])
        return item['propertyId']
    with ThreadPoolExecutor(max_workers=6) as pool:
        checked = set(pool.map(check, plan['items']))
    for item in plan['items']:
        item['photoChecked'] = item['propertyId'] in checked
    dump(WORK / 'plan.json', plan)
    print('COVER_IMAGES_VERIFIED', len(checked))


def style_sheet(sheet, table_name):
    sheet.freeze_panes = 'C2'
    sheet.sheet_view.showGridLines = False
    sheet.row_dimensions[1].height = 30
    for cell in sheet[1]:
        cell.font = Font(name='Calibri', bold=True, color='FFFFFF', size=11)
        cell.fill = PatternFill('solid', fgColor='126B5D')
        sheet.column_dimensions[cell.column_letter].width = 26
    for row in sheet.iter_rows(min_row=2):
        for cell in row:
            cell.alignment = Alignment(vertical='top', wrap_text=True)
            cell.font = Font(name='Calibri', size=11)
            # Treat user-visible/source strings as text, never spreadsheet formulas.
            if isinstance(cell.value, str):
                cell.data_type = 's'
                cell.number_format = '@'
        sheet.row_dimensions[row[0].row].height = 45
    table = Table(displayName=table_name, ref=sheet.dimensions)
    table.tableStyleInfo = TableStyleInfo(name='TableStyleMedium2', showRowStripes=True)
    sheet.add_table(table)


def build_workbook():
    plan = read_plan()
    if not all(item['photoChecked'] for item in plan['items']):
        raise ValueError('Verify cover images before building workbook')
    book = load_workbook(TEMPLATE)
    for name in ['NhaTro', 'LoaiPhong', 'PhongTro', 'DichVu']:
        sheet = book[name]
        sheet.delete_rows(2, sheet.max_row)
        sheet.tables.clear()
    owners = book.create_sheet('ChuTro', 0)
    owners.append(['ownerUid', 'displayName', 'email', 'password', 'role', 'disabled',
                   'createdAt', 'photoURL', 'isDemo', 'firebaseStatus'])
    sources = book.create_sheet('NguonDuLieu')
    sources.append(['propertyId', 'mien', 'tinhThanh', 'sourceListingId', 'sourceUrl',
                    'sourceApiUrl', 'collectedAt', 'sourceTitle', 'sourceRegion', 'sourceWard',
                    'latitude', 'longitude', 'anhBiaDaKiemTra', 'truongThamKhao',
                    'truongGiaLap', 'luuY'])
    for item in plan['items']:
        pid, uid = item['propertyId'], item['ownerUid']
        name = f"Nhà trọ {item['street']} · {item['city']}"
        address = ', '.join(v for v in [item['street'], item['ward'], item['district'], item['city']] if v)
        description = (
            '[DỮ LIỆU THỬ NGHIỆM] Mỗi nhà là một hồ sơ tham khảo từ một tin phòng trọ công khai, '
            'chỉ có một phòng đại diện, chưa xác minh toàn bộ tòa nhà hay chủ sở hữu. '
            f"Giá và diện tích theo tin đăng: {item['monthlyRent']:,} đồng/tháng, {item['area']} m². "
            'Tài khoản chủ trọ, điện thoại 0000000000, tầng 1, sức chứa 2 người và phí điện/nước là dữ liệu giả lập. '
            'Không dùng tài khoản này để liên hệ chủ tin thật. Chưa xác minh tình trạng còn phòng hoặc địa chỉ hành chính mới. '
            'Nguồn: ' + item['sourceUrl'])
        book['NhaTro'].append([pid, uid, name, address, item['city'], item['ward'], item['displayName'],
                               '0000000000', description, 'Dữ liệu thử nghiệm', item['photos'][0]])
        book['LoaiPhong'].append([pid, 'tham-khao', 'Phòng tham khảo', item['monthlyRent'], '|'.join(item['photos'])])
        book['PhongTro'].append([pid, 'P101', 1, 'tham-khao', item['area'], 2])
        book['DichVu'].append([pid, 'electricity', 'Điện [MẪU]', 'kWh', 'Theo chỉ số', 4000, True])
        book['DichVu'].append([pid, 'water', 'Nước [MẪU]', 'm3', 'Theo chỉ số', 15000, True])
        owners.append([uid, item['displayName'], item['email'], item['password'], 'landlord', False,
                       plan['createdAt'], '', True, 'Đã xác minh' if plan.get('verified') else 'Chờ nhập Firebase'])
        sources.append([pid, item['zone'], item['city'], item['sourceListingId'], item['sourceUrl'],
                        item['sourceApiUrl'], item['collectedAt'], item['sourceTitle'], item['sourceRegion'],
                        item['sourceWard'], item['latitude'], item['longitude'], item['photoChecked'],
                        'Đường/phường theo nguồn; giá; diện tích; album ảnh',
                        'Chủ trọ/email/mật khẩu; số điện thoại; mã phòng; tầng; sức chứa; phí dịch vụ',
                        'Chưa xác minh chủ sở hữu, số nhà đầy đủ, còn phòng, hay tổng số phòng. Tên hành chính giữ theo nguồn.'])
    for index, name in enumerate(['ChuTro', 'NhaTro', 'LoaiPhong', 'PhongTro', 'DichVu', 'NguonDuLieu']):
        style_sheet(book[name], 'Nationwide' + str(index))
    for name, keys in [('NhaTro', ['name', 'address', 'description', 'imageUrl']),
                       ('LoaiPhong', ['photoUrls']), ('NguonDuLieu', ['sourceUrl', 'truongGiaLap', 'luuY'])]:
        for cell in book[name][1]:
            if cell.value in keys:
                book[name].column_dimensions[cell.column_letter].width = 65
    for row in sources.iter_rows(min_row=2):
        row[4].hyperlink = row[4].value
        row[4].style = 'Hyperlink'
    guide = book['HuongDan']
    guide.delete_rows(1, guide.max_row)
    for row in [
        ['DỮ LIỆU 60 NHÀ TRỌ THAM KHẢO', '20 mục miền Bắc, 20 miền Trung/Tây Nguyên, 20 miền Nam. 11 tỉnh/thành theo nguồn.'],
        ['Chủ trọ', 'ChuTro có 60 tài khoản THỬ NGHIỆM. ownerUid = Firebase Auth UID = users document ID.'],
        ['Mật khẩu', 'Cột password dùng đăng nhập thử và tạo Firebase Authentication; KHÔNG lưu password trong Firestore. Giữ riêng file Excel, không commit Git.'],
        ['Thông tin theo nguồn', 'Giá, diện tích, đường/phường và ảnh theo tin Nhà Tốt, có URL và thời điểm thu thập ở NguonDuLieu. Không suy ra người đăng chính là chủ nhà.'],
        ['Thông tin giả lập', 'Tên chủ, email example.com, mật khẩu, điện thoại 0000000000, mã P101, tầng 1, sức chứa 2 và điện 4000/nước 15000 là mẫu phục vụ đồ án.'],
        ['Quy mô', 'Mỗi tin tạo 1 hồ sơ nhà, 1 loại phòng, 1 phòng đại diện và 2 dịch vụ. Không có hợp đồng/người thuê/hóa đơn.'],
        ['Địa chỉ', 'Giữ nhãn phường/khu vực nguồn; có thể là đơn vị hành chính cũ và thiếu số nhà. Chưa khảo sát thực địa hay xác minh tình trạng còn phòng.'],
        ['Ảnh', 'URL HTTPS từ CDN Nhà Tốt; ảnh bìa đã kiểm tra tải được. Liên kết ngoài có thể thay đổi, chưa tải lên Firebase Storage.'],
        ['Nguồn gốc', 'Đây là bộ thử nghiệm có dẫn nguồn, không phải danh sách 60 chủ trọ thật đã đăng ký hoặc đồng ý nhận khách.'],
        ['Firebase', 'Dự án: ' + plan['project'] + '. users / rental_properties / public_rooms / rental_records. Dữ liệu mới có prefix nt60-.'],
        ['Mẫu gốc', 'Giữ nguyên artifacts/MAU_THU_THAP_NHA_TRO.xlsx. ViDu là ví dụ mẫu, không được nhập.'],
    ]:
        guide.append(row)
    book.active = 0
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    book.save(OUTPUT)
    print('WORKBOOK_READY', str(OUTPUT.relative_to(ROOT)))


def export():
    from rental_import import build_snapshot, read_rows
    snapshot, owners = build_snapshot(read_rows(OUTPUT))
    source = WORK / 'rental_import.json'
    dump(source, {'snapshot': snapshot, 'owners': owners})
    dart = shutil.which('dart')
    if not dart:
        raise ValueError('Dart is required to use the app Firestore codec')
    # Avoid Flutter's batch bootstrap/cache lock when the SDK is already installed.
    direct_dart = Path(dart).parent / 'cache/dart-sdk/bin/dart.exe'
    if direct_dart.is_file():
        dart = str(direct_dart)
    subprocess.run([dart, '--packages=.dart_tool/package_config.json', 'tool/rental_import_codec.dart', str(source), str(WORK / 'cloud_documents.json')],
                   cwd=ROOT, check=True)
    print('EXPORTED_WITH_APP_CODEC')


def wire_value(item):
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
        return {'arrayValue': {'values': [wire_value(v) for v in item]}}
    if isinstance(item, dict):
        return {'mapValue': {'fields': {k: wire_value(v) for k, v in item.items()}}}
    raise ValueError('Unsupported Firestore value')


def decode_wire(item):
    if 'mapValue' in item:
        return {k: decode_wire(v) for k, v in item['mapValue'].get('fields', {}).items()}
    if 'arrayValue' in item:
        return [decode_wire(v) for v in item['arrayValue'].get('values', [])]
    if 'integerValue' in item:
        return int(item['integerValue'])
    return next(iter(item.values()))


def cloud_source():
    plan = read_plan()
    source = json.loads((WORK / 'cloud_documents.json').read_text(encoding='utf-8'))
    by_property = {i['propertyId']: i for i in plan['items']}
    for path, data in source.items():
        pid = path.split('/')[1] if path.startswith('rental_properties/') else data['propertyId']
        item = by_property[pid]
        data.update(isDemo=True, importBatch='nt60-v1', source={
            'provider': 'Nhà Tốt', 'listingId': item['sourceListingId'],
            'url': item['sourceUrl'], 'collectedAt': item['collectedAt'],
            'ownershipVerified': False, 'availabilityVerified': False,
            'representativeRoomOnly': True,
        })
        if path.startswith('public_rooms/'):
            # The app codec adds this default tag; it has not been verified here.
            data['tags'] = [t for t in data['tags'] if t != 'Giờ tự do']
    for item in plan['items']:
        source['users/' + item['ownerUid']] = {
            'displayName': item['displayName'], 'email': item['email'],
            'role': 'landlord', 'disabled': False, 'createdAt': plan['createdAt'],
            'photoURL': '', 'isDemo': True, 'importBatch': 'nt60-v1',
        }
    if len(source) != 240:
        raise ValueError('Expected 240 new Firestore documents')
    if any('password' in json.dumps(data).lower() for data in source.values()):
        raise ValueError('Password must never be exported to Firestore')
    return source


def list_collection(base, collection):
    result, page = {}, ''
    while True:
        data = cloud('GET', f'{base}/{collection}?pageSize=1000' + page)
        for doc in data.get('documents', []):
            result[doc['name'].split('/documents/')[1]] = doc
        if not data.get('nextPageToken'):
            return result
        from urllib.parse import quote
        page = '&pageToken=' + quote(data['nextPageToken'], safe='')


def list_auth(project):
    users, page = {}, ''
    while True:
        data = cloud('GET', f'https://identitytoolkit.googleapis.com/v1/projects/{project}/accounts:batchGet?maxResults=1000' + page)
        for user in data.get('users', []):
            # Never persist passwordHash, salt, or unrelated users' profile details.
            users[user['localId']] = {k: user[k] for k in ['localId', 'email', 'displayName', 'disabled'] if k in user}
        if not data.get('nextPageToken'):
            return users
        from urllib.parse import quote
        page = '&nextPageToken=' + quote(data['nextPageToken'], safe='')


def preview_cloud():
    plan = read_plan()
    project, _ = project_config()
    base = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
    source = cloud_source()
    before = {}
    for collection in ['users', 'rental_properties', 'public_rooms', 'rental_records']:
        before.update(list_collection(base, collection))
    auth = list_auth(project)
    collisions = source.keys() & before.keys()
    if collisions:
        raise ValueError('Existing Firestore target IDs: ' + ', '.join(sorted(collisions)[:3]))
    desired_ids = {i['ownerUid'] for i in plan['items']}
    desired_emails = {i['email'] for i in plan['items']}
    if desired_ids & auth.keys() or desired_emails & {u.get('email') for u in auth.values()}:
        raise ValueError('Existing Auth target IDs/emails; inspect the journal instead of overwriting')
    dump(WORK / 'before-firestore.json', before)
    dump(WORK / 'before-auth-summary.json', auth)
    dump(WORK / 'planned-cloud.json', source)
    print(json.dumps({'project': project, 'existingDocuments': len(before), 'existingAuthAccounts': len(auth),
                      'newDocuments': len(source), 'newAuthAccounts': 60,
                      'collections': dict(Counter(p.split('/')[0] for p in source)),
                      'passwordsInFirestore': False, 'mode': 'PREVIEW_ONLY'}))


def apply_cloud():
    """Create-only Auth journal, followed by one atomic, create-only Firestore commit."""
    plan = read_plan()
    project, key = project_config()
    if not (WORK / 'planned-cloud.json').exists():
        raise ValueError('Run cloud-preview first')
    source = cloud_source()
    if source != json.loads((WORK / 'planned-cloud.json').read_text(encoding='utf-8')):
        raise ValueError('Source changed after preview')
    base = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
    # Recheck all Firestore conflicts before creating any Auth account.
    for collection in ['users', 'rental_properties', 'public_rooms', 'rental_records']:
        if source.keys() & list_collection(base, collection).keys():
            raise ValueError('Firestore target exists; do not reapply a completed import')
    journal_path = WORK / 'auth-journal.json'
    journal = json.loads(journal_path.read_text(encoding='utf-8')) if journal_path.exists() else {}
    current_auth = list_auth(project)
    for index, item in enumerate(plan['items']):
        uid = item['ownerUid']
        if uid in current_auth:
            existing = current_auth[uid]
            if (journal.get(uid) != item['email'] or existing.get('email') != item['email']
                    or existing.get('displayName') != item['displayName'] or existing.get('disabled', False)):
                raise ValueError('Existing account not owned by this import journal')
            continue
        if item['email'] in {u.get('email') for u in current_auth.values()}:
            raise ValueError('Email collision; account will not be modified')
        # Intent persisted first; an interrupted successful create can be resumed safely.
        journal[uid] = item['email']
        dump(journal_path, journal)
        response = cloud('POST', f'https://identitytoolkit.googleapis.com/v1/projects/{project}/accounts', {
            'localId': uid, 'email': item['email'],
            'password': item['password'], 'displayName': item['displayName'],
            'emailVerified': False, 'disabled': False,
        })
        if response.get('localId') != uid:
            raise RuntimeError('Firebase returned a different UID')
        if (index + 1) % 10 == 0:
            print('AUTH_CREATED', index + 1, flush=True)
    writes = []
    for path, data in source.items():
        fields = {k: wire_value(v) for k, v in data.items()}
        if path.startswith('users/'):
            fields['createdAt'] = {'timestampValue': data['createdAt']}
        writes.append({'update': {'name': base.split('/v1/')[1] + '/' + path, 'fields': fields},
                       'currentDocument': {'exists': False}})
    # 240 documents fit in one commit. The exists:false precondition protects every target.
    cloud('POST', base + ':commit', {'writes': writes})
    print('ATOMIC_FIRESTORE_COMMIT_OK', len(writes), flush=True)


def clean_property_names(apply=False):
    """Remove the display prefix only; preserve provenance and all other fields."""
    from copy import deepcopy

    plan = read_plan()
    project, _ = project_config()
    base = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
    owners = {item['propertyId']: item['ownerUid'] for item in plan['items']}
    existing = {}
    for collection in ['rental_properties', 'public_rooms']:
        existing.update(list_collection(base, collection))
    writes, expected, backup = [], {}, {}
    for path, doc in existing.items():
        data = {key: decode_wire(value) for key, value in doc['fields'].items()}
        is_property = path.startswith('rental_properties/')
        pid = path.split('/')[1] if is_property else data.get('propertyId')
        if pid not in owners:
            continue
        if data.get('importBatch') != 'nt60-v1' or data.get('ownerUid') != owners[pid]:
            raise ValueError('Refusing to change a document outside the original import: ' + path)
        old_name = data['data']['property']['name'] if is_property else data['name']
        if not old_name.startswith('[MẪU] '):
            continue
        new_name = old_name.removeprefix('[MẪU] ')
        after = deepcopy(data)
        if is_property:
            after['data']['property']['name'] = new_name
            patch = {'data': {'property': {'name': new_name}}}
            field = 'data.property.name'
        else:
            after['name'] = new_name
            patch = {'name': new_name}
            field = 'name'
        writes.append({'update': {'name': doc['name'], 'fields': {
            key: wire_value(value) for key, value in patch.items()}},
            'updateMask': {'fieldPaths': [field]},
            'currentDocument': {'updateTime': doc['updateTime']}})
        backup[path], expected[path] = doc, after
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    dump(WORK / f'before-clean-names-{stamp}.json', backup)
    print('PROPERTY_NAME_UPDATES', len(writes), 'APPLY' if apply else 'PREVIEW_ONLY', flush=True)
    if not apply or not writes:
        return
    cloud('POST', base + ':commit', {'writes': writes})
    actual = {}
    for collection in ['rental_properties', 'public_rooms']:
        actual.update(list_collection(base, collection))
    for path, after in expected.items():
        found = {key: decode_wire(value) for key, value in actual[path]['fields'].items()}
        if found != after:
            raise ValueError('Name update read-back mismatch: ' + path)
    print('PROPERTY_NAMES_UPDATED_AND_VERIFIED', len(expected))


def verify_cloud():
    plan = read_plan()
    project, key = project_config()
    base = f'https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents'
    source = cloud_source()
    actual = {}
    for collection in ['users', 'rental_properties', 'public_rooms', 'rental_records']:
        actual.update(list_collection(base, collection))
    for path, expected in source.items():
        if path not in actual:
            raise ValueError('Missing document: ' + path)
        found = {k: decode_wire(v) for k, v in actual[path]['fields'].items()}
        if path.startswith('users/'):
            # Firestore normalizes ISO timestamps to Z and millisecond/microsecond precision.
            found['createdAt'] = datetime.fromisoformat(found['createdAt'].replace('Z', '+00:00'))
            expected = {**expected, 'createdAt': datetime.fromisoformat(expected['createdAt'])}
        if found != expected:
            raise ValueError('Read-back mismatch: ' + path)
    before = json.loads((WORK / 'before-firestore.json').read_text(encoding='utf-8'))
    for path, previous in before.items():
        if path not in actual or actual[path]['fields'] != previous['fields']:
            raise ValueError('A pre-existing document changed: ' + path)
    auth = list_auth(project)
    for item in plan['items']:
        account = auth.get(item['ownerUid'], {})
        if account.get('email') != item['email'] or account.get('disabled', False):
            raise ValueError('Auth account missing or disabled: ' + item['ownerUid'])
    # Prove every password in the workbook actually signs in, without printing tokens.
    def check_login(item):
        response = verified_read('POST', 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' + key,
                                 json={'email': item['email'], 'password': item['password'],
                                       'returnSecureToken': True})
        if not response.ok or response.json().get('localId') != item['ownerUid']:
            raise ValueError('Password sign-in failed: ' + item['ownerUid'])
        identity = response.json()
        headers = {'Authorization': 'Bearer ' + identity['idToken']}
        profile = verified_read('GET', base + '/users/' + item['ownerUid'], headers=headers)
        if not profile.ok or profile.json().get('fields', {}).get('role') != {'stringValue': 'landlord'}:
            raise ValueError('User cannot read its landlord role: ' + item['ownerUid'])
        if item == plan['items'][0]:
            # Exercise the same filtered reads as ScopedFirestoreRentalRepository.
            for collection in ['rental_properties', 'rental_records']:
                query = verified_read('POST', base + ':runQuery', headers=headers, json={'structuredQuery': {
                    'from': [{'collectionId': collection}], 'where': {'fieldFilter': {
                        'field': {'fieldPath': 'ownerUid'}, 'op': 'EQUAL',
                        'value': {'stringValue': item['ownerUid']}}}}})
                if not query.ok or sum('document' in row for row in query.json()) != 1:
                    raise ValueError('Landlord-scoped catalogue read failed: ' + collection)
            other = verified_read('GET', base + '/users/' + plan['items'][1]['ownerUid'], headers=headers)
            if other.status_code != 403:
                raise ValueError('A landlord can read another account profile')
        return item['ownerUid']
    with ThreadPoolExecutor(max_workers=3) as pool:
        logins = list(pool.map(check_login, plan['items']))
    plan['verified'] = True
    plan['verifiedAt'] = datetime.now(timezone.utc).isoformat()
    dump(WORK / 'plan.json', plan)
    report = {'project': project, 'verifiedAt': plan['verifiedAt'], 'properties': 60, 'roomTypes': 60,
              'rooms': 60, 'landlordAccounts': 60, 'serviceRows': 120,
              'verifiedDocuments': len(source), 'verifiedPasswordSignIns': len(logins),
              'originalDocumentsPreserved': len(before), 'passwordsStoredInFirestore': False,
              'byZone': dict(Counter(i['zone'] for i in plan['items'])),
              'byCity': dict(Counter(i['city'] for i in plan['items'])),
              'demoAccounts': True, 'realOwnershipVerified': False, 'realAvailabilityVerified': False}
    dump(ROOT / 'artifacts/BAO_CAO_60_NHA_TRO.json', report)
    build_workbook()
    print('PUBLISHED_AND_VERIFIED', json.dumps(report, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    actions = {'probe': probe, 'collect': collect, 'collect-regions': collect_regions,
               'prepare': prepare, 'check-photos': check_photos, 'build': build_workbook, 'export': export,
               'cloud-preview': preview_cloud, 'cloud-apply': apply_cloud, 'cloud-verify': verify_cloud,
               'clean-property-names-preview': clean_property_names,
               'clean-property-names-apply': lambda: clean_property_names(apply=True)}
    parser.add_argument('action', choices=actions)
    args = parser.parse_args()
    actions[args.action]()


if __name__ == '__main__':
    main()
