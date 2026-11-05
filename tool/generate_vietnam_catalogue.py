"""Generate 20 apartment houses per current province, using real administrative names.

Buildings/owners/prices are synthetic. Internet photographs are illustrations with provenance.
Credentials stay in ignored local files; Firebase handles the passwords.
"""
import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
from pathlib import Path
import random
import re
import secrets
import shutil
import subprocess
import sys

import requests
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.worksheet.table import Table, TableStyleInfo

from collect_nationwide_rentals import ROOT, dump, project_config, verified_read
from rental_import import SCHEMA

WORK = ROOT / '.local-backups/vietnam-34-rentals'
OUTPUT = ROOT / 'artifacts/DU_LIEU_680_NHA_TRO_34_TINH.xlsx'
BATCH = 'vn34-v1'
SEED = 340680
ADMIN_SOURCE = 'https://provinces.open-api.vn/api/v2/?depth=2'
OFFICIAL_SOURCE = 'https://baochinhphu.vn/bang-danh-muc-va-ma-so-cua-34-tinh-thanh-moi-3321-don-vi-hanh-chinh-cap-xa-moi-102250704153652947.htm'
PHOTO_API = 'https://gateway.chotot.com/v1/public/ad-listing'
EXPECTED_CODES = {1, 4, 8, 11, 12, 14, 15, 19, 20, 22, 24, 25, 31, 33, 37, 38, 40, 42,
                  44, 46, 48, 51, 52, 56, 66, 68, 75, 79, 80, 82, 86, 91, 92, 96}
FLOOR_ROOM_COUNTS = [2] * 8 + [3] * 6 + [4] * 4 + [5] * 2 + [6, 8, 10, 12]
BRANDS = ['An Nhiên', 'Bình An', 'Ban Mai', 'Minh Khang', 'Thiên Phúc', 'Hòa Bình',
          'Thanh Xuân', 'Gia Hưng', 'Ánh Dương', 'Phúc Lộc', 'Hoàng Gia', 'Trúc Xanh',
          'Sen Việt', 'Hạnh Phúc', 'Bảo An', 'Ngọc Lan', 'Tâm An', 'Hải Đăng', 'Sao Mai', 'Khánh Linh']
STREETS = ['Lê Lợi', 'Nguyễn Trãi', 'Trần Phú', 'Nguyễn Du', 'Lý Thường Kiệt', 'Phan Đình Phùng',
           'Hoàng Diệu', 'Trần Hưng Đạo', 'Nguyễn Văn Trỗi', 'Hùng Vương', 'Lê Hồng Phong',
           'Nguyễn Thị Minh Khai', 'Điện Biên Phủ', 'Phạm Văn Đồng', 'Hai Bà Trưng', 'Đoàn Kết',
           'Ngô Quyền', 'Lý Tự Trọng', 'Tô Hiệu', 'Võ Thị Sáu']
SURNAMES = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Huỳnh', 'Phan', 'Vũ', 'Võ', 'Đặng',
            'Bùi', 'Đỗ', 'Hồ', 'Ngô', 'Dương', 'Đinh', 'Đoàn']
GIVEN_NAMES = ['Minh Anh', 'Quốc Bảo', 'Thanh Bình', 'Ngọc Châu', 'Tuấn Dũng', 'Thu Hà',
               'Gia Hân', 'Mạnh Hùng', 'Khánh Huyền', 'Trung Kiên', 'Thùy Linh', 'Hoài Nam',
               'Bảo Ngọc', 'Phương Nhi', 'Đức Phúc', 'Minh Quân', 'Hồng Sơn', 'Thanh Tâm',
               'Anh Thư', 'Quốc Tuấn', 'Như Ý', 'Hải Yến', 'Thanh Vân', 'Nhật Minh',
               'Khánh An', 'Phúc Khang', 'Ngọc Mai', 'Hữu Thành', 'Thảo Vy', 'Đình Long',
               'Thiên Trang', 'Việt Hoàng', 'Bích Ngân', 'Đức Huy', 'Kim Oanh', 'Quang Vinh',
               'Thùy Dương', 'Gia Linh', 'Thành Đạt', 'Hải Đăng']
TYPE_SPECS = [
    {'id': 'tieu-chuan', 'name': 'Phòng tiêu chuẩn', 'photoKind': 'studio', 'area': 18, 'capacity': 2, 'premium': 0},
    {'id': 'gac-lung', 'name': 'Phòng có gác lửng', 'photoKind': 'loft', 'area': 25, 'capacity': 3, 'premium': 500000},
    {'id': 'studio', 'name': 'Studio đầy đủ nội thất', 'photoKind': 'studio', 'area': 28, 'capacity': 2, 'premium': 1200000},
    {'id': 'ban-cong', 'name': 'Phòng có ban công', 'photoKind': 'balcony', 'area': 32, 'capacity': 3, 'premium': 1600000},
    {'id': 'nhieu-nguoi', 'name': 'Phòng rộng nhiều người', 'photoKind': 'group', 'area': 40, 'capacity': 4, 'premium': 2000000},
]
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')


def collect_administrative_units():
    response = verified_read('GET', ADMIN_SOURCE)
    response.raise_for_status()
    provinces = response.json()
    if len(provinces) != 34 or {p['code'] for p in provinces} != EXPECTED_CODES:
        raise ValueError('Administrative API does not match the expected 34-province list')
    if any(not p.get('wards') for p in provinces):
        raise ValueError('Province is missing its ward list')
    dump(WORK / 'administrative-units.json', provinces)
    print('ADMINISTRATIVE_UNITS_READY', len(provinces))


def collect_photos():
    queries = [('loft', 'gác lửng'), ('balcony', 'ban công'), ('studio', 'studio'),
               ('studio', 'phòng trọ nội thất'), ('group', 'phòng rộng')]
    def fetch(task):
        kind, query = task
        result = verified_read('GET', PHOTO_API, params={'cg': 1050, 'limit': 30, 'o': 0,
                                                        'st': 'u,h', 'w': 1, 'q': query})
        result.raise_for_status()
        return kind, result.url, result.json().get('ads', [])
    albums = []
    seen = set()
    with ThreadPoolExecutor(max_workers=4) as pool:
        fetched = list(pool.map(fetch, queries))
    for kind, endpoint, ads in fetched:
        for ad in ads:
            listing = ad.get('list_id')
            if not isinstance(listing, int) or (kind, listing) in seen:
                continue
            photos = [u for u in ad.get('images', []) if isinstance(u, str)
                      and u.startswith('https://cdn.chotot.com/')][:3]
            if not photos:
                continue
            seen.add((kind, listing))
            albums.append({'kind': kind, 'listingId': str(listing), 'photos': photos,
                           'sourceUrl': f'https://www.nhatot.com/{listing}.htm',
                           'sourceApiUrl': f'{PHOTO_API}/{listing}', 'searchApiUrl': endpoint})
    # Reuse earlier internet albums as fallbacks; they retain their original source.
    old = json.loads((ROOT / 'assets/images/rental_api/manifest.json').read_text(encoding='utf-8'))
    for album in old['albums']:
        kind = album['type']
        if kind in {'loft', 'studio', 'balcony', 'group'} and (kind, int(album['listingId'])) not in seen:
            albums.append({'kind': kind, 'listingId': str(album['listingId']),
                           'photos': [p['url'] for p in album['photos'][:3]],
                           'sourceUrl': f"https://www.nhatot.com/{album['listingId']}.htm",
                           'sourceApiUrl': f"{PHOTO_API}/{album['listingId']}",
                           'searchApiUrl': album.get('endpoint', old['endpoint'])})
    urls = sorted({url for album in albums for url in album['photos']})
    def check(url):
        try:
            with requests.get(url, stream=True, timeout=20) as response:
                return url, response.ok and response.headers.get('Content-Type', '').startswith('image/')
        except requests.exceptions.RequestException:
            return url, False
    with ThreadPoolExecutor(max_workers=8) as pool:
        valid = dict(pool.map(check, urls))
    for album in albums:
        album['photos'] = [url for url in album['photos'] if valid[url]]
    albums = [album for album in albums if album['photos']]
    counts = Counter(album['kind'] for album in albums)
    if any(counts[kind] < 3 for kind in ['studio', 'loft', 'balcony', 'group']):
        raise ValueError('Not enough working image albums per room category')
    result = {'provider': 'Nhà Tốt / Chợ Tốt', 'usage': 'Ảnh minh họa cho dữ liệu đồ án tự tạo',
              'collectedAt': datetime.now(timezone.utc).isoformat(), 'albums': albums,
              'verifiedPhotoUrls': sum(valid.values())}
    dump(WORK / 'photo-pool.json', result)
    dump(ROOT / 'artifacts/NGUON_ANH_680_NHA_TRO.json', result)
    print('PHOTO_POOL_READY', json.dumps({'albums': len(albums), 'photos': sum(valid.values()),
                                        'byKind': dict(counts)}, ensure_ascii=False))


def prepare():
    path = WORK / 'catalogue.json'
    if path.exists():
        raise ValueError('Catalogue already exists; never regenerate account passwords')
    provinces = json.loads((WORK / 'administrative-units.json').read_text(encoding='utf-8'))
    if {p['code'] for p in provinces} != EXPECTED_CODES or len(provinces) != 34:
        raise ValueError('Administrative list differs from the official 34-province codes')
    photo_pool = json.loads((WORK / 'photo-pool.json').read_text(encoding='utf-8'))
    pools = {kind: [a for a in photo_pool['albums'] if a['kind'] == kind]
             for kind in ['studio', 'loft', 'balcony', 'group']}
    rng = random.Random(SEED)
    owners, stores, provenance = [], [], []
    floor_cursor = 0
    for p_index, province in enumerate(provinces):
        short_city = re.sub(r'^(Tỉnh|Thành phố)\s+', '', province['name'])
        wards = [w for w in province['wards'] if w['name'].startswith('Phường ')]
        wards += [w for w in province['wards'] if not w['name'].startswith('Phường ')]
        # Prefer populated wards while spreading 20 houses across the province.
        wards = wards[:max(20, min(len(wards), 40))]
        for number in range(1, 21):
            pid = f"vn34-{province['code']:02d}-{number:03d}"
            global_index = len(stores)
            owner_name = SURNAMES[(global_index // len(GIVEN_NAMES)) % len(SURNAMES)] + ' ' + GIVEN_NAMES[global_index % len(GIVEN_NAMES)]
            owner = {'ownerUid': pid, 'displayName': owner_name,
                     'email': f"landlord.{province['code']:02d}.{number:03d}@example.com",
                     'password': 'Tro!9a' + secrets.token_urlsafe(15), 'provinceCode': province['code'],
                     'role': 'landlord', 'disabled': False}
            owners.append(owner)
            ward = wards[(number - 1) % len(wards)]
            floors = (number - 1) % 10 + 1
            floor_counts = {}
            rooms = []
            for floor in range(1, floors + 1):
                count = 12 if (p_index == 0 and number == 20) else FLOOR_ROOM_COUNTS[floor_cursor % len(FLOOR_ROOM_COUNTS)]
                floor_cursor += 1
                floor_counts[floor] = count
                for position in range(1, count + 1):
                    rooms.append({'code': f'P.{floor}{position:02d}', 'floor': floor,
                                  'roomTypeId': '', 'area': 0, 'capacity': 0, 'leaseRoomCode': None})
            num_types = min(2 + (number - 1) % 4, len(rooms))
            # Rotate combinations so small buildings do not all have the same room types.
            rotated = TYPE_SPECS[(number - 1) % len(TYPE_SPECS):] + TYPE_SPECS[:(number - 1) % len(TYPE_SPECS)]
            types = []
            photo_refs = []
            base_rent = (2400000 if province['code'] in {1, 48, 79} else 1400000) + rng.randrange(0, 9) * 100000
            for type_index, spec in enumerate(rotated[:num_types]):
                album = pools[spec['photoKind']][(global_index * 3 + type_index) % len(pools[spec['photoKind']])]
                types.append({'id': spec['id'], 'name': spec['name'], 'monthlyRent': base_rent + spec['premium'],
                              'photos': [{'name': f'Ảnh {i + 1}', 'url': url} for i, url in enumerate(album['photos'])]})
                photo_refs.append({'roomTypeId': spec['id'], 'listingId': album['listingId'],
                                   'sourceUrl': album['sourceUrl'], 'sourceApiUrl': album['sourceApiUrl'],
                                   'photoUrls': album['photos']})
            for room_index, room in enumerate(rooms):
                spec = rotated[room_index % num_types]
                room.update(roomTypeId=spec['id'], area=spec['area'] + rng.choice([0, 1, 2, 3]), capacity=spec['capacity'])
            amenities = ['Wifi', 'Bãi xe', 'Camera', 'Giờ giấc tự do']
            if floors >= 5:
                amenities.append('Thang máy')
            if number % 2 == 0:
                amenities.append('Máy giặt')
            name = f"Nhà trọ {BRANDS[(number - 1 + p_index) % len(BRANDS)]} {short_city}"
            description = (f"Nhà trọ tại {ward['name']}, {short_city}, gồm {floors} tầng với {len(rooms)} phòng "
                           f"và {num_types} loại phòng. Phòng có khu vệ sinh riêng, khu bếp, ánh sáng tự nhiên. "
                           'Khu để xe có camera; wifi và giờ giấc tự do. ' +
                           ('Có thang máy thuận tiện di chuyển. ' if floors >= 5 else '') +
                           'Phù hợp sinh viên, người đi làm và gia đình nhỏ. Giá thuê theo từng loại phòng.')
            prop = {'id': pid, 'name': name,
                    'address': f"{12 + number * 7} Đường {STREETS[(number - 1) % len(STREETS)]}, {ward['name']}, {province['name']}",
                    'city': province['name'], 'ward': ward['name'], 'ownerName': owner_name,
                    'phone': '0000000000', 'description': description, 'amenities': amenities,
                    'imageUrl': types[0]['photos'][0]['url'], 'imageBytes': None, 'imageName': None}
            services = [
                {'id': 'electricity', 'name': 'Điện', 'unit': 'kWh', 'basis': 'Theo chỉ số', 'price': 3500, 'active': True},
                {'id': 'water', 'name': 'Nước', 'unit': 'm3', 'basis': 'Theo chỉ số', 'price': 15000, 'active': True},
                {'id': 'internet', 'name': 'Internet', 'unit': 'tháng', 'basis': 'Theo phòng', 'price': 100000, 'active': True},
                {'id': 'parking', 'name': 'Giữ xe', 'unit': 'xe/tháng', 'basis': 'Theo người', 'price': 80000, 'active': True},
                {'id': 'cleaning', 'name': 'Vệ sinh chung', 'unit': 'tháng', 'basis': 'Theo phòng', 'price': 30000, 'active': True},
            ]
            stores.append({'property': prop, 'rooms': rooms, 'roomTypes': types, 'services': services,
                           **{k: [] for k in ['leases', 'invoices', 'payments', 'paymentAccounts', 'members', 'incidents', 'readings']},
                           'counters': [1] * 7})
            provenance.append({'propertyId': pid, 'ownerUid': pid, 'provinceCode': province['code'],
                               'wardCode': ward['code'], 'floors': floors, 'roomsPerFloor': floor_counts,
                               'generation': 'synthetic', 'photosAreIllustrative': True, 'photoSources': photo_refs})
    catalogue = {'project': project_config()[0], 'batch': BATCH, 'seed': SEED,
                 'createdAt': datetime.now(timezone.utc).isoformat(), 'administrativeSource': ADMIN_SOURCE,
                 'officialSource': OFFICIAL_SOURCE, 'photoCollectedAt': photo_pool['collectedAt'],
                 'owners': owners, 'snapshot': {'portfolio': {'selectedId': stores[0]['property']['id'], 'properties': stores}},
                 'ownersByProperty': {s['property']['id']: s['property']['id'] for s in stores}, 'provenance': provenance}
    validate(catalogue)
    dump(path, catalogue)
    print('CATALOGUE_PREPARED', json.dumps(summary(catalogue), ensure_ascii=False))


def read_catalogue():
    data = json.loads((WORK / 'catalogue.json').read_text(encoding='utf-8'))
    if data['project'] != project_config()[0] or data['batch'] != BATCH:
        raise ValueError('Catalogue project/batch mismatch')
    return data


def summary(data):
    stores = data['snapshot']['portfolio']['properties']
    return {'provinces': len({s['property']['city'] for s in stores}), 'properties': len(stores),
            'owners': len(data['owners']), 'roomTypes': sum(len(s['roomTypes']) for s in stores),
            'rooms': sum(len(s['rooms']) for s in stores), 'services': sum(len(s['services']) for s in stores),
            'floors': sum(max(r['floor'] for r in s['rooms']) for s in stores),
            'byProvince': dict(Counter(s['property']['city'] for s in stores))}


def validate(data):
    stores = data['snapshot']['portfolio']['properties']
    owners = {o['ownerUid'] for o in data['owners']}
    if len(stores) != 680 or len(owners) != 680:
        raise ValueError('Expected 680 properties and 680 unique owners')
    if len({s['property']['id'] for s in stores}) != 680:
        raise ValueError('Duplicate property IDs')
    provinces = json.loads((WORK / 'administrative-units.json').read_text(encoding='utf-8'))
    names = {p['name'] for p in provinces}
    counts = Counter(s['property']['city'] for s in stores)
    if set(counts) != names or any(v != 20 for v in counts.values()):
        raise ValueError('Every one of the current 34 provinces must have exactly 20 properties')
    ward_names = {p['name']: {w['name'] for w in p['wards']} for p in provinces}
    for store in stores:
        prop, rooms, types = store['property'], store['rooms'], store['roomTypes']
        if prop['id'] not in owners or prop['ward'] not in ward_names[prop['city']]:
            raise ValueError('Owner/administrative link is invalid')
        floors = Counter(r['floor'] for r in rooms)
        if not 1 <= max(floors) <= 10 or set(floors) != set(range(1, max(floors) + 1)):
            raise ValueError('Building floors must be consecutive and within 1–10')
        if any(not 2 <= count <= 12 for count in floors.values()):
            raise ValueError('Each floor must have 2–12 rooms')
        if not 2 <= len(types) <= 5 or {r['roomTypeId'] for r in rooms} != {t['id'] for t in types}:
            raise ValueError('Each building needs multiple used room types')
        if len({r['code'] for r in rooms}) != len(rooms):
            raise ValueError('Duplicate room codes within a building')
        for floor, count in floors.items():
            if {r['code'] for r in rooms if r['floor'] == floor} != {f'P.{floor}{i:02d}' for i in range(1, count + 1)}:
                raise ValueError('Room codes do not agree with floors/positions')
        if prop['name'].startswith('[') or any(not t['photos'] for t in types):
            raise ValueError('Display prefix or missing type photos')
    return summary(data)


def add_table(book, name, headers, rows):
    sheet = book.create_sheet(name)
    sheet.append(headers)
    for row in rows:
        sheet.append(row)
    sheet.freeze_panes = 'C2'
    sheet.sheet_view.showGridLines = False
    for cell in sheet[1]:
        cell.font = Font(name='Calibri', bold=True, color='FFFFFF')
        cell.fill = PatternFill('solid', fgColor='126B5D')
        sheet.column_dimensions[cell.column_letter].width = 24
    for row in sheet.iter_rows(min_row=2):
        for cell in row:
            if isinstance(cell.value, str):
                cell.data_type = 's'
                cell.number_format = '@'
            cell.alignment = Alignment(vertical='top')
    table = Table(displayName=name + 'Catalogue', ref=sheet.dimensions)
    table.tableStyleInfo = TableStyleInfo(name='TableStyleMedium2', showRowStripes=True)
    sheet.add_table(table)
    return sheet


def build():
    data = read_catalogue()
    info = validate(data)
    book = Workbook()
    book.remove(book.active)
    stores = data['snapshot']['portfolio']['properties']
    add_table(book, 'ChuTro', ['ownerUid', 'displayName', 'email', 'password', 'role', 'disabled', 'createdAt'],
              [[o['ownerUid'], o['displayName'], o['email'], o['password'], o['role'], o['disabled'], data['createdAt']] for o in data['owners']])
    add_table(book, 'NhaTro', SCHEMA['NhaTro'],
              [[s['property']['id'], data['ownersByProperty'][s['property']['id']],
                *[s['property'][key] for key in ['name', 'address', 'city', 'ward', 'ownerName', 'phone', 'description']],
                '|'.join(s['property']['amenities']), s['property']['imageUrl']] for s in stores])
    add_table(book, 'LoaiPhong', SCHEMA['LoaiPhong'],
              [[s['property']['id'], t['id'], t['name'], t['monthlyRent'], '|'.join(p['url'] for p in t['photos'])] for s in stores for t in s['roomTypes']])
    add_table(book, 'PhongTro', SCHEMA['PhongTro'],
              [[s['property']['id'], r['code'], r['floor'], r['roomTypeId'], r['area'], r['capacity']] for s in stores for r in s['rooms']])
    add_table(book, 'DichVu', SCHEMA['DichVu'],
              [[s['property']['id'], *[v[key] for key in ['id', 'name', 'unit', 'basis', 'price', 'active']]] for s in stores for v in s['services']])
    add_table(book, 'TangNha', ['propertyId', 'floor', 'roomCount'],
              [[s['property']['id'], floor, count] for s in stores for floor, count in sorted(Counter(r['floor'] for r in s['rooms']).items())])
    add_table(book, 'ThongKeTinhThanh', ['tinhThanh', 'nhaTro', 'chuTro', 'tang', 'phong', 'loaiPhong'],
              [[province, len(group := [s for s in stores if s['property']['city'] == province]), len(group),
                sum(max(r['floor'] for r in s['rooms']) for s in group), sum(len(s['rooms']) for s in group),
                sum(len(s['roomTypes']) for s in group)] for province in info['byProvince']])
    source = add_table(book, 'NguonAnh', ['propertyId', 'roomTypeId', 'sourceListingId', 'sourceUrl', 'sourceApiUrl', 'photoUrls', 'ghiChu'],
              [[ref['propertyId'], photo['roomTypeId'], photo['listingId'], photo['sourceUrl'], photo['sourceApiUrl'],
                '|'.join(photo['photoUrls']), 'Ảnh minh họa lấy trên mạng; không khẳng định ảnh của nhà trọ tự tạo này.']
               for ref in data['provenance'] for photo in ref['photoSources']])
    for row in source.iter_rows(min_row=2):
        row[3].hyperlink, row[3].style = row[3].value, 'Hyperlink'
        row[4].hyperlink, row[4].style = row[4].value, 'Hyperlink'
    guide = book.create_sheet('HuongDan')
    for row in [
        ['BỘ DỮ LIỆU ĐỒ ÁN', '34 tỉnh/thành, mỗi tỉnh 20 nhà trọ. Tỉnh/phường theo danh mục hiện hành; nhà/chủ/địa chỉ đường/giá/phòng được tự tạo theo yêu cầu.'],
        ['Quy mô', json.dumps({k: v for k, v in info.items() if k != 'byProvince'}, ensure_ascii=False)],
        ['Liên kết', 'ChuTro.ownerUid = NhaTro.ownerUid = Firebase UID. propertyId liên kết nhà/tầng/loại/phòng/dịch vụ. roomTypeId duy nhất trong cùng nhà.'],
        ['Số tầng / phòng', 'Mỗi tỉnh có nhà đủ các quy mô 1–10 tầng. Mỗi tầng 2–12 phòng, đánh số liên tiếp: P.101, P.102, P.201; tầng 10: P.1001–P.1012.'],
        ['Loại phòng', 'Mỗi nhà 2–5 loại phòng. Mỗi loại đều có phòng sử dụng và có album riêng. Phòng cùng loại dùng chung giá và ảnh theo model ứng dụng.'],
        ['Ảnh', 'NguonAnh lưu link tin gốc, API chi tiết và album. Ảnh tải từ Internet đã kiểm tra URL; ảnh chỉ minh họa, có thể lặp ở nhiều nhà tự tạo.'],
        ['Chủ trọ / mật khẩu', '680 chủ trọ tự tạo, mỗi người 1 nhà. Mật khẩu ngẫu nhiên dùng Firebase Authentication, không lưu mật khẩu trong Firestore. Không chia sẻ công khai file này.'],
        ['Địa chỉ / liên hệ', 'Tỉnh, phường có thật. Tên đường và số nhà giả lập, chưa xác minh địa chỉ thực tế. Điện thoại 0000000000 để tránh dùng số của người thật.'],
        ['Mô tả / tiện ích / chi phí', 'Thông tin tự tạo cho đồ án; không phải cam kết của chủ nhà thật. Không có người thuê, hợp đồng, hóa đơn hoặc giao dịch thật.'],
        ['Nguồn hành chính', ADMIN_SOURCE], ['Đối chiếu mã tỉnh', OFFICIAL_SOURCE],
        ['Firebase', data['project'] + ' — batch ' + BATCH],
    ]:
        guide.append(row)
    guide.column_dimensions['A'].width = 30
    guide.column_dimensions['B'].width = 120
    for row in guide:
        row[1].alignment = Alignment(wrap_text=True, vertical='top')
        guide.row_dimensions[row[0].row].height = 45
    book.active = book.sheetnames.index('ThongKeTinhThanh')
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    book.save(OUTPUT)
    print('WORKBOOK_READY', OUTPUT.relative_to(ROOT))


def export():
    data = read_catalogue()
    validate(data)
    source = WORK / 'rental_import.json'
    dump(source, {'snapshot': data['snapshot'], 'owners': data['ownersByProperty']})
    dart = shutil.which('dart')
    if not dart:
        raise ValueError('Dart SDK is required')
    direct = Path(dart).parent / 'cache/dart-sdk/bin/dart.exe'
    if direct.is_file():
        dart = str(direct)
    subprocess.run([dart, '--packages=.dart_tool/package_config.json', 'tool/rental_import_codec.dart',
                    str(source), str(WORK / 'cloud_documents.json')], cwd=ROOT, check=True)
    print('EXPORTED_USING_APP_CODEC')


def main():
    actions = {'administrative': collect_administrative_units, 'photos': collect_photos,
               'prepare': prepare, 'build': build, 'export': export,
               'validate': lambda: print(json.dumps(validate(read_catalogue()), ensure_ascii=False))}
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=actions)
    actions[parser.parse_args().action]()


if __name__ == '__main__':
    main()
