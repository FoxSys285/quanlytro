"""Seed additive, realistic sample properties and operational records.

Adds 9 additional sample properties (`op26-02-01` .. `op26-02-09`) owned by the
existing demo landlords (`report-demo-owner-1..3`) plus rich members, viewings,
incidents, invoices, payments, readings, conversations, and support tickets.

Never overwrites or deletes existing users, properties, or operational records.
Preview by default; pass `--apply` (with Firebase admin auth via prompt or
`FIREBASE_ADMIN_PASSWORD` / `--admin-email`) to publish to `tropremium-d14ac`.
"""
import argparse
import datetime as dt
import getpass
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import urllib.error
from urllib.parse import quote
import urllib.request
import zlib

ROOT = Path(__file__).resolve().parents[1]
PROJECT_ID = 'tropremium-d14ac'
BASE = (
    f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/'
    'databases/(default)/documents'
)
BATCH_TAG = 'operating-samples-20261126'

# Verified CDN photo sets already present in rental_api_photos.dart.
PHOTO_SETS = [
    [
        'https://cdn.chotot.com/8VKNdWMbHXvyQ4fc0_UmnuRecMVRe4V7bKZtbXwnPQY/preset:view/plain/bf856103162a6e02fbb66f4e96da2a48-3009074081710770452.jpg',
        'https://cdn.chotot.com/9FR1SMju3MlRGdpjMb_JuDdDcAW5bP2dpu_PlXEwvLo/preset:view/plain/000d13a375c5ee1448e70f78c22158c2-3009074081833507510.jpg',
        'https://cdn.chotot.com/kOz1_oKdyGhztiAXtzYJg9SWWlttfU6sHnTJg67nuoU/preset:view/plain/b848f631f991463195917919202a15ae-3009074082312696936.jpg',
    ],
    [
        'https://cdn.chotot.com/9Pke28L0K8Ms3wNSW5vYrKuDxI46AX3yX3sgzvCNCXM/preset:view/plain/737adf07e7e050800e7273c888689e1d-3006685408665764054.jpg',
        'https://cdn.chotot.com/pLvj-wRMCm_ervjtdDlw1h-fx88PeGRm_Wh5UE9mp8c/preset:view/plain/c39597531479a0511ffd6a60fc7636ad-3006685420436077522.jpg',
        'https://cdn.chotot.com/NRoxepZnLug7O-dQr4N3KhDEulkm_Evsiea5lr8juNk/preset:view/plain/6a4d383196d8f884b9159e576f129d20-3006685420543572646.jpg',
    ],
    [
        'https://cdn.chotot.com/Wtb7g26bKraMMLXKUA-uEEBl6_08bvzSeJRwhj8VVOA/preset:view/plain/49712c3df7c83bf7e464e5de8e1ab272-3008643345909858149.jpg',
        'https://cdn.chotot.com/aGaC43QaoWQdzI_9I7ahHV25Kw2A-DTAKdVqu7pvi0Q/preset:view/plain/b4a101b563da2959298fa4631e6c9139-3008643346233186348.jpg',
        'https://cdn.chotot.com/yKO9UlFIf7zkYe6zsrt_V29ue46sFQNYBgPLxLrzfZ0/preset:view/plain/85da4466d7b4b81d58cc14d3b7778322-3008643345877975364.jpg',
    ],
    [
        'https://cdn.chotot.com/7hfWF-AWiumJL4ivo6Re3KRbsr4yD6SBTbQ5JpWaB98/preset:view/plain/f50e8ee8298c4f7c4d6baf48c44f6fb1-3005841095243181595.jpg',
        'https://cdn.chotot.com/e2uHHQloJdvn1V7rDRMRDAhFv26ZF36iD75koxDsPhA/preset:view/plain/bf657b43bd7ecb3e688a443100687aed-3005841113928531560.jpg',
        'https://cdn.chotot.com/O3uMgA1o1tSv5LDtFSgwy2qQMtYN1_cAm_mzKTLJf8A/preset:view/plain/31416501fd6dbb505411827a4cdc8b14-3005841113274154600.jpg',
    ],
    [
        'https://cdn.chotot.com/RAUq-ORZVZR-2LUi2vPyxRhHazvG2f2RrUnScHY1JEs/preset:view/plain/519044420409164e54b072d20393d852-3003836484258681676.jpg',
        'https://cdn.chotot.com/N5JD8cmCnUoTxPDnelbDp0rRYuwQY8k08IBa-MZGyHM/preset:view/plain/003ea4c587954ef1c53910ed7388de51-3003836484740093529.jpg',
        'https://cdn.chotot.com/qCha2WMi0YfGMkPdHYlQcauZ0TYdQRJYSbA8K2OoWlQ/preset:view/plain/fb200027ea6f7ae6a5bd98c8767f76b0-3003836485837383297.jpg',
    ],
    [
        'https://cdn.chotot.com/gHFdHjoqdrzZimp3FjYA60IkhXNT-9WmvhVaPUi_9AY/preset:view/plain/beee61096ef5437e577622fef0812027-3008642390688874820.jpg',
        'https://cdn.chotot.com/InfMeTBkAElpqDNZQVWY_bLUyqEtXggFwsWI-_mW_a8/preset:view/plain/0cc1ace79a1433da65c0d0975abf28d3-3008642390803922789.jpg',
        'https://cdn.chotot.com/Bp-sEdqPdg17yIAX7myt3FHVMQJYFGEuhAFfnIdwz7Y/preset:view/plain/bdb2b7944d48084b36d42eb357bef25d-3008642391095208787.jpg',
    ],
    [
        'https://cdn.chotot.com/vDm0vo7c-r8P4XIeeGEOyv_BkoC7JLA9AdjNuK0qQcI/preset:view/plain/da6eb03e86db5c786115c639958ae516-3009072073443371675.jpg',
        'https://cdn.chotot.com/2aT8hU0R5I2jMzCjnFpPU_oOc45cI3_trzA4psHcX3w/preset:view/plain/893cfebf93615d135356c56400155917-3009072072125733558.jpg',
        'https://cdn.chotot.com/jJ_TcXRHK06SNsMVUnogfT3-rOXGpXA9fpFmxWf1kVQ/preset:view/plain/85886e446fa6c90091bc7e956f17de0b-3009072074242733160.jpg',
    ],
    [
        'https://cdn.chotot.com/50yebb9GnSQihoCnAt1lsn-K0pX-U_GFMhAmOfPIaGA/preset:view/plain/974576638d102a7933202806a1c84a34-3004972262055615506.jpg',
        'https://cdn.chotot.com/2s4PcV4boJnRV9JPxqObUE2_SAYUcxW83oXfkgSzUg8/preset:view/plain/41a81f982364685e989f15de3e7ded97-3004972262011870744.jpg',
        'https://cdn.chotot.com/6JcOThny8ftM6gKc1Oyf7a9tTrHFR0sZ9J2OMHi_gHQ/preset:view/plain/c4ce6f22ae9983aabae2e3e856cea96a-3004972262045799792.jpg',
    ],
    [
        'https://cdn.chotot.com/vsg8EXOlmqhnkme20ESLYb-CGgj-O1Q6JRM-FpluO1o/preset:view/plain/38fe1facd290eb9d61c70f1aedeade90-3008569931718539212.jpg',
        'https://cdn.chotot.com/4PhmgjwVkAwzwUAggf6EICS6cBwRdc0-EpGL-CwwszU/preset:view/plain/797e5cec2beee30269bbc2a4798e0a92-3008569934268127485.jpg',
        'https://cdn.chotot.com/mgA5WFv01ba0LhKfxl1yLLhztDPNYmnSCED644kuLeE/preset:view/plain/9520d318a9b43e6ea5010a286acc1f9d-3008569936253618905.jpg',
    ],
]

NEW_PROPERTIES = [
    {
        'id': 'op26-02-01',
        'ownerUid': 'report-demo-owner-1',
        'ownerName': 'Nguyễn Minh Anh',
        'phone': '0901000201',
        'name': 'Sài Gòn Corner Bình Thạnh',
        'address': '128 Nguyễn Gia Trí, Phường 25, Quận Bình Thạnh, TP. Hồ Chí Minh',
        'city': 'TP. Hồ Chí Minh',
        'ward': 'Phường 25',
        'description': 'Sài Gòn Corner Bình Thạnh gần HUTECH và hàng quán. Phòng có cửa sổ lớn, máy lạnh inverter, thang máy, bãi xe tầng trệt và camera 24/7.',
        'amenities': ['Wifi', 'Máy lạnh', 'Thang máy', 'Bãi xe', 'Camera'],
        'state': 'verified',
        'rentBase': 3800000,
    },
    {
        'id': 'op26-02-02',
        'ownerUid': 'report-demo-owner-1',
        'ownerName': 'Nguyễn Minh Anh',
        'phone': '0901000202',
        'name': 'Nhà trọ Ánh Dương',
        'address': '45 Xuân Thủy, Phường Dịch Vọng, Cầu Giấy, Thành phố Hà Nội',
        'city': 'Thành phố Hà Nội',
        'ward': 'Phường Dịch Vọng',
        'description': 'Nhà trọ Ánh Dương nằm trong ngõ yên tĩnh cách Đại học Quốc gia 300m. Có gác lửng thoáng, bếp riêng, giờ giấc tự do và khóa vân tay.',
        'amenities': ['Wifi', 'Gác lửng', 'Bếp riêng', 'Giờ giấc tự do', 'Camera'],
        'state': 'pending',
        'rentBase': 3200000,
    },
    {
        'id': 'op26-02-03',
        'ownerUid': 'report-demo-owner-1',
        'ownerName': 'Nguyễn Minh Anh',
        'phone': '0901000203',
        'name': 'Gác Gỗ Thảo Điền',
        'address': '19 Xuân Thủy, Phường Thảo Điền, Thành phố Thủ Đức, TP. Hồ Chí Minh',
        'city': 'TP. Hồ Chí Minh',
        'ward': 'Phường Thảo Điền',
        'description': 'Gác Gỗ Thảo Điền thiết kế phong cách ấm cúng gần tuyến Metro. Trang bị sẵn tủ lạnh, máy giặt chung, ban công rộng và bảo vệ trực.',
        'amenities': ['Wifi', 'Ban công', 'Nội thất', 'Máy giặt chung', 'Bãi xe'],
        'state': 'supplement',
        'rentBase': 4200000,
    },
    {
        'id': 'op26-02-04',
        'ownerUid': 'report-demo-owner-2',
        'ownerName': 'Nguyễn Quốc Bảo',
        'phone': '0902000204',
        'name': 'Biển Xanh Sơn Trà',
        'address': '64 Trần Hưng Đạo, Phường An Hải Bắc, Sơn Trà, Thành phố Đà Nẵng',
        'city': 'Thành phố Đà Nẵng',
        'ward': 'Phường An Hải Bắc',
        'description': 'Biển Xanh Sơn Trà thoáng mát, đi bộ 5 phút ra cầu Rồng và sông Hàn. Phòng full nội thất, thang máy, sân phơi tầng thượng sạch sẽ.',
        'amenities': ['Wifi', 'Ban công', 'Máy lạnh', 'Thang máy', 'Camera'],
        'state': 'verified',
        'rentBase': 2900000,
    },
    {
        'id': 'op26-02-05',
        'ownerUid': 'report-demo-owner-2',
        'ownerName': 'Nguyễn Quốc Bảo',
        'phone': '0902000205',
        'name': 'SunHome Phú Nhuận',
        'address': '82 Phan Xích Long, Phường 2, Quận Phú Nhuận, TP. Hồ Chí Minh',
        'city': 'TP. Hồ Chí Minh',
        'ward': 'Phường 2',
        'description': 'SunHome Phú Nhuận mặt tiền khu ẩm thực Phan Xích Long, tiện di chuyển Quận 1 và sân bay. Phòng studio đầy đủ nội thất, có dọn vệ sinh tuần.',
        'amenities': ['Wifi', 'Máy lạnh', 'Nội thất', 'Thang máy', 'Bãi xe'],
        'state': 'pending',
        'rentBase': 4000000,
    },
    {
        'id': 'op26-02-06',
        'ownerUid': 'report-demo-owner-2',
        'ownerName': 'Nguyễn Quốc Bảo',
        'phone': '0902000206',
        'name': 'Nhà trọ Vườn Cau',
        'address': '33 Mậu Thân, Phường Xuân Khánh, Ninh Kiều, Thành phố Cần Thơ',
        'city': 'Thành phố Cần Thơ',
        'ward': 'Phường Xuân Khánh',
        'description': 'Nhà trọ Vườn Cau nhiều cây xanh mát mẻ, gần Đại học Cần Thơ. Phòng rộng rãi, có chỗ để xe riêng và wifi tốc độ cao từng tầng.',
        'amenities': ['Wifi', 'Bãi xe', 'Giờ giấc tự do', 'Cửa sổ'],
        'state': 'draft',
        'rentBase': 2300000,
    },
    {
        'id': 'op26-02-07',
        'ownerUid': 'report-demo-owner-3',
        'ownerName': 'Nguyễn Thanh Bình',
        'phone': '0903000207',
        'name': 'Phố Nắng Thủ Dầu Một',
        'address': '112 Đại lộ Bình Dương, Phường Phú Hòa, Thủ Dầu Một, Tỉnh Bình Dương',
        'city': 'Tỉnh Bình Dương',
        'ward': 'Phường Phú Hòa',
        'description': 'Phố Nắng Thủ Dầu Một thuận tiện cho sinh viên và kỹ sư làm việc tại KCN VSIP. Phòng có gác đúc, kệ bếp đá hoa cương, camera an ninh.',
        'amenities': ['Wifi', 'Gác lửng', 'Bếp riêng', 'Bãi xe', 'Camera'],
        'state': 'verified',
        'rentBase': 2400000,
    },
    {
        'id': 'op26-02-08',
        'ownerUid': 'report-demo-owner-3',
        'ownerName': 'Nguyễn Thanh Bình',
        'phone': '0903000208',
        'name': 'Bình Yên Studio',
        'address': '56 Nguyễn Thị Thập, Phường Tân Phong, Quận 7, TP. Hồ Chí Minh',
        'city': 'TP. Hồ Chí Minh',
        'ward': 'Phường Tân Phong',
        'description': 'Bình Yên Studio ngay cạnh Lotte Mart Quận 7 và Đại học Tôn Đức Thắng. Căn hộ dịch vụ mini, ban công kính, hầm xe rộng và bảo vệ.',
        'amenities': ['Wifi', 'Máy lạnh', 'Ban công', 'Thang máy', 'Nội thất'],
        'state': 'verified',
        'rentBase': 4300000,
    },
    {
        'id': 'op26-02-09',
        'ownerUid': 'report-demo-owner-3',
        'ownerName': 'Nguyễn Thanh Bình',
        'phone': '0903000209',
        'name': 'Cỏ Xanh Residence',
        'address': '18 Tạ Quang Bửu, Phường Bách Khoa, Hai Bà Trưng, Thành phố Hà Nội',
        'city': 'Thành phố Hà Nội',
        'ward': 'Phường Bách Khoa',
        'description': 'Cỏ Xanh Residence cách cổng Bách Khoa 200m, khu dân trí cao. Phòng sạch sẽ có điều hòa, nóng lạnh, máy giặt chung miễn phí.',
        'amenities': ['Wifi', 'Máy lạnh', 'Máy giặt chung', 'Camera', 'Giờ giấc tự do'],
        'state': 'pending',
        'rentBase': 3400000,
    },
]


def canon(item):
    if isinstance(item, dict):
        return {str(k): canon(item[k]) for k in sorted(item.keys(), key=str)}
    if isinstance(item, list):
        return [canon(x) for x in item]
    return item


def property_proof(store_data):
    prop = dict(store_data['property'])
    for k in ('verificationDocuments', 'verificationSubmittedAt', 'verificationIsOwner'):
        prop.pop(k, None)
    payload = {
        'property': prop,
        'rooms': store_data['rooms'],
        'types': store_data['roomTypes'],
    }
    encoded = json.dumps(canon(payload), ensure_ascii=False, separators=(',', ':'))
    return hashlib.sha256(encoded.encode('utf-8')).hexdigest()


def make_sample_png_bytes(rgb):
    """Generates a tiny (~140 byte) valid PNG swatch readable by Flutter Image.memory."""
    w, h = 120, 80
    r, g, b = rgb
    raw_rows = b''.join(b'\x00' + bytes([r, g, b]) * w for _ in range(h))

    def chunk(tag, payload):
        return (
            struct.pack('>I', len(payload))
            + tag
            + payload
            + struct.pack('>I', zlib.crc32(tag + payload) & 0xFFFFFFFF)
        )

    ihdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    idat = zlib.compress(raw_rows, 9)
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')
    return list(png)


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
    return {'mapValue': {'fields': {k: wire_value(v) for k, v in item.items()}}}


def decode_value(item):
    if 'mapValue' in item:
        return {k: decode_value(v) for k, v in item['mapValue'].get('fields', {}).items()}
    if 'arrayValue' in item:
        return [decode_value(v) for v in item['arrayValue'].get('values', [])]
    if 'integerValue' in item:
        return int(item['integerValue'])
    if 'doubleValue' in item:
        return float(item['doubleValue'])
    return next(iter(item.values())) if item else None


def http_json(url, data=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    payload = None if data is None else json.dumps(data, ensure_ascii=False).encode('utf-8')
    with urllib.request.urlopen(urllib.request.Request(url, data=payload, headers=headers), timeout=30) as resp:
        return json.load(resp)


def firebase_config():
    cfg = (ROOT / 'lib/firebase_options.dart').read_text(encoding='utf-8')
    web = re.search(r'FirebaseOptions web\s*=\s*FirebaseOptions\((.*?)\);', cfg, re.S)
    key = re.search(r"apiKey:\s*'([^']+)'", web.group(1)).group(1)
    proj = re.search(r"projectId:\s*'([^']+)'", web.group(1)).group(1)
    if proj != PROJECT_ID:
        raise RuntimeError(f'Unexpected projectId: {proj}')
    return key


def sign_in_admin(email, password=None):
    api_key = firebase_config()
    secret = password or os.environ.get('FIREBASE_ADMIN_PASSWORD') or getpass.getpass('Firebase admin password (hidden): ')
    resp = http_json(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' + quote(api_key, safe=''),
        {'email': email, 'password': secret, 'returnSecureToken': True},
    )
    return resp['idToken'], resp['localId']


def list_collection(col, token):
    docs = {}
    page = ''
    while True:
        resp = http_json(f'{BASE}/{col}?pageSize=300{page}', token=token)
        for doc in resp.get('documents', []):
            path = doc['name'].split('/documents/')[1]
            docs[path] = doc
        tok = resp.get('nextPageToken')
        if not tok:
            break
        page = '&pageToken=' + quote(tok, safe='')
    return docs


def build_additions(existing, now, admin_uid='report-demo-admin'):
    now_iso = now.isoformat()
    period_nov = '2026-10-31T17:00:00.000Z'
    period_oct = '2026-09-30T17:00:00.000Z'
    portrait_bytes = make_sample_png_bytes((24, 118, 178))
    id_front_bytes = make_sample_png_bytes((15, 138, 108))
    id_back_bytes = make_sample_png_bytes((42, 148, 120))
    owner_bytes = make_sample_png_bytes((194, 112, 48))

    verification_docs_payload = [
        {'id': 'portrait', 'files': [{'name': 'chan-dung-chu-tro.png', 'bytes': portrait_bytes, 'storagePath': None}]},
        {
            'id': 'identity',
            'files': [
                {'name': 'cccd-mat-truoc.png', 'bytes': id_front_bytes, 'storagePath': None},
                {'name': 'cccd-mat-sau.png', 'bytes': id_back_bytes, 'storagePath': None},
            ],
        },
        {'id': 'ownership', 'files': [{'name': 'so-hong-nha-tro.png', 'bytes': owner_bytes, 'storagePath': None}]},
    ]

    additions = {}
    new_verified = {}
    new_proofs = {}

    def add_doc(path, body):
        if path not in existing:
            additions[path] = body

    def rec(pid, owner, kind, key, data, readers):
        doc_key = f'{quote(pid, safe="")}:{kind}:{quote(key, safe="")}'
        add_doc(
            f'rental_records/{doc_key}',
            {
                'kind': kind,
                'propertyId': pid,
                'ownerUid': owner,
                'tenantIds': readers,
                'archived': False,
                'importBatch': BATCH_TAG,
                'isDemo': True,
                'generation': 'synthetic',
                'data': data,
            },
        )

    for idx, spec in enumerate(NEW_PROPERTIES):
        pid = spec['id']
        owner = spec['ownerUid']
        photos_urls = PHOTO_SETS[idx % len(PHOTO_SETS)]
        room_photos = [{'name': f'Ảnh phòng {i + 1}', 'url': url} for i, url in enumerate(photos_urls)]
        services = [
            {'id': 'electricity', 'name': 'Điện', 'unit': 'kWh', 'basis': 'Theo chỉ số', 'price': 3800, 'active': True},
            {'id': 'water', 'name': 'Nước', 'unit': 'm³', 'basis': 'Theo chỉ số', 'price': 16000, 'active': True},
            {'id': 'internet', 'name': 'Internet', 'unit': 'phòng', 'basis': 'Theo phòng', 'price': 100000, 'active': True},
            {'id': 'cleaning', 'name': 'Vệ sinh', 'unit': 'phòng', 'basis': 'Theo phòng', 'price': 30000, 'active': True},
            {'id': 'parking', 'name': 'Gửi xe máy', 'unit': 'cái', 'basis': 'Theo cái / xe', 'price': 80000, 'active': True},
        ]
        rent1 = spec['rentBase']
        rent2 = spec['rentBase'] + 500000
        room_types = [
            {
                'id': 'studio',
                'name': 'Phòng Studio tiêu chuẩn',
                'monthlyRent': rent1,
                'borderColorValue': None,
                'serviceIds': ['electricity', 'water', 'internet', 'cleaning'],
                'servicePrices': {'electricity': 3800, 'water': 16000, 'internet': 100000, 'cleaning': 30000},
                'photos': room_photos,
            },
            {
                'id': 'balcony',
                'name': 'Phòng ban công thoáng',
                'monthlyRent': rent2,
                'borderColorValue': None,
                'serviceIds': ['electricity', 'water', 'internet', 'cleaning', 'parking'],
                'servicePrices': {'electricity': 3800, 'water': 16000, 'internet': 100000, 'cleaning': 30000, 'parking': 80000},
                'photos': list(reversed(room_photos)),
            },
        ]
        rooms = [
            {'code': '101', 'floor': 1, 'roomTypeId': 'studio', 'area': 24, 'capacity': 2, 'leaseRoomCode': None},
            {'code': '102', 'floor': 1, 'roomTypeId': 'studio', 'area': 25, 'capacity': 2, 'leaseRoomCode': None},
            {'code': '201', 'floor': 2, 'roomTypeId': 'balcony', 'area': 30, 'capacity': 3, 'leaseRoomCode': None},
            {'code': '202', 'floor': 2, 'roomTypeId': 'balcony', 'area': 32, 'capacity': 4, 'leaseRoomCode': None},
        ]
        store_data = {
            'schemaVersion': 2,
            'property': {
                'id': pid,
                'name': spec['name'],
                'address': spec['address'],
                'ownerName': spec['ownerName'],
                'phone': spec['phone'],
                'phoneIsSynthetic': True,
                'description': spec['description'],
                'amenities': spec['amenities'],
                'imageUrl': photos_urls[0],
                'imageBytes': None,
                'imageName': None,
                'city': spec['city'],
                'ward': spec['ward'],
            },
            'rooms': rooms,
            'roomTypes': room_types,
            'services': services,
        }
        verified = spec['state'] == 'verified'
        proof = property_proof(store_data) if verified else ''
        if verified:
            new_verified[pid] = True
            new_proofs[pid] = proof

        add_doc(
            f'rental_properties/{pid}',
            {
                'ownerUid': owner,
                'published': True,
                'verified': verified,
                'verificationProof': proof,
                'importBatch': BATCH_TAG,
                'isDemo': True,
                'generation': 'synthetic',
                'data': store_data,
            },
        )
        # Room 101 has a synthetic sample lease; 102, 201, 202 are vacant for Discovery.
        for room in rooms:
            rtype = room_types[0] if room['roomTypeId'] == 'studio' else room_types[1]
            add_doc(
                f'public_rooms/{quote(f"{pid}:{room["code"]}", safe="")}',
                {
                    'propertyId': pid,
                    'ownerUid': owner,
                    'roomCode': room['code'],
                    'name': f"{spec['name']} · Phòng {room['code']} · {rtype['name']}",
                    'address': spec['address'],
                    'price': rtype['monthlyRent'],
                    'area': room['area'],
                    'capacity': room['capacity'],
                    'roomType': rtype['name'],
                    'city': spec['city'],
                    'ward': spec['ward'],
                    'description': spec['description'],
                    'photos': rtype['photos'],
                    'tags': [*spec['amenities'], f"Tầng {room['floor']}", 'Giờ tự do'],
                    'electricityPrice': 3800,
                    'waterType': 'Theo m³',
                    'waterPrice': 16000,
                    'services': [s for s in services if s['id'] in rtype['serviceIds']],
                    'published': True,
                    'available': room['code'] != '101',
                    'importBatch': BATCH_TAG,
                    'isDemo': True,
                    'generation': 'synthetic',
                },
            )

        sample_tenant_id = f'SMP260{idx + 1:02d}'
        sample_tenant_name = [
            'Lê Hoàng Minh', 'Trần Thị Thu Hà', 'Phạm Đức Anh',
            'Ngô Bảo Châu', 'Đỗ Gia Huy', 'Bùi Khánh Linh',
            'Võ Trung Kiên', 'Hoàng Lan Anh', 'Đặng Quang Hải',
        ][idx]
        lease_id = f'lease-{pid}-101'
        rec(pid, owner, 'settings', pid, {'counters': [10000]*7, 'paymentAccounts': []}, [sample_tenant_id])

        if spec['state'] in ('verified', 'pending', 'supplement'):
            submitted_at = (now - dt.timedelta(days=1)).isoformat() if spec['state'] == 'supplement' else now_iso
            rec(
                pid,
                owner,
                'verification',
                pid,
                {'submittedAt': submitted_at, 'isOwner': True, 'documents': verification_docs_payload},
                [],
            )
        review_note = (
            'Vui lòng chụp rõ hơn mặt sau CCCD và trang thông tin chủ sở hữu trên sổ hồng.'
            if spec['state'] == 'supplement'
            else ''
        )
        rec(
            pid,
            owner,
            'verificationReview',
            pid,
            {
                'note': review_note,
                'requestedAt': now_iso if review_note else None,
                'submissionAt': (now - dt.timedelta(days=1)).isoformat() if review_note else None,
            },
            [],
        )

        # Synthetic active lease on room 101 for realistic Landlord operations.
        rec(
            pid,
            owner,
            'leases',
            lease_id,
            {
                'id': lease_id,
                'tenantId': sample_tenant_id,
                'propertyId': pid,
                'room': '101',
                'tenantName': sample_tenant_name,
                'phone': f'091200030{idx + 1}',
                'startDate': '2026-08-01T00:00:00.000Z',
                'endDate': '2027-08-01T00:00:00.000Z',
                'monthlyRent': rent1,
                'deposit': rent1,
                'termMonths': 12,
                'dueDay': 5,
                'landlordName': spec['ownerName'],
                'landlordPermanentAddress': spec['address'],
                'landlordCitizenId': '',
                'landlordContact': spec['phone'],
                'landlordBirthDate': None,
                'landlordCitizenIssueDate': None,
                'landlordCitizenIssuePlace': '',
                'tenantBirthYear': '2000',
                'tenantBirthDate': None,
                'tenantCitizenId': '',
                'tenantCitizenIssueDate': None,
                'tenantCitizenIssuePlace': '',
                'tenantPermanentAddress': spec['city'],
                'electricityPrice': 3800,
                'waterPrice': 16000,
                'waterType': 'Theo m³',
                'electricityServiceId': 'electricity',
                'waterServiceId': 'water',
                'vehicleFee': 0,
                'serviceFee': 130000,
                'services': [],
                'serviceId': '',
                'serviceName': '',
                'serviceUnit': '',
                'serviceBasis': '',
                'cashPaymentEnabled': True,
                'cashPaymentLocation': 'Văn phòng nhà trọ',
                'bankTransferEnabled': False,
                'bankName': '',
                'bankAccountNumber': '',
                'occupantCount': 2,
                'status': 'active',
                'note': 'Hợp đồng mẫu phục vụ demo vận hành.',
                'responsibilityA': '',
                'responsibilityB': '',
                'commonResponsibilities': '',
                'templateId': '',
                'rentalAddress': spec['address'],
                'terminationReason': '',
                'terminatedAt': None,
                'terminationRequestStatus': '',
                'terminationRequestedAt': None,
                'terminationRequestedBy': '',
                'terminationRequestReason': '',
                'terminationReviewedAt': None,
                'terminationRejectionReason': '',
                'renewalStatus': '',
                'renewalRequestedAt': None,
                'renewalRequestedBy': '',
                'renewalProposedEndDate': None,
                'renewalReason': '',
                'renewalReviewedAt': None,
                'renewalRejectionReason': '',
            },
            [sample_tenant_id],
        )

        # Meter readings across rooms (done + undone so meter screen feels alive).
        for r_idx, room in enumerate(rooms):
            done = r_idx < 2
            rec(
                pid,
                owner,
                'readings',
                f"{room['code']}:{period_nov}",
                {
                    'room': room['code'],
                    'period': period_nov,
                    'oldElectric': 1000 + r_idx * 40,
                    'newElectric': (1075 + r_idx * 45) if done else None,
                    'oldWater': 120 + r_idx * 5,
                    'newWater': (126 + r_idx * 5) if done else None,
                },
                [sample_tenant_id] if room['code'] == '101' else [],
            )

        # Monthly invoice + payment sample.
        total_due = rent1 + 415000
        paid = total_due if idx % 3 == 0 else (total_due // 2 if idx % 3 == 1 else 0)
        inv_id = f'inv-{pid}-11'
        rec(
            pid,
            owner,
            'invoices',
            inv_id,
            {
                'id': inv_id,
                'leaseId': lease_id,
                'room': '101',
                'tenantName': sample_tenant_name,
                'period': period_nov,
                'dueDate': '2026-11-10T17:00:00.000Z' if idx % 3 == 2 else '2026-12-05T17:00:00.000Z',
                'charges': [
                    {'name': 'Tiền thuê phòng', 'amount': rent1},
                    {'name': 'Điện · 75 kWh', 'amount': 285000},
                    {'name': 'Nước · 6 m³', 'amount': 96000},
                    {'name': 'Internet & vệ sinh', 'amount': 34000},
                ],
                'paidAmount': paid,
                'cancelled': False,
                'pendingPaymentId': f'pay-{inv_id}' if idx % 3 == 2 else None,
                'lastApprovedPaymentId': f'pay-{inv_id}' if paid > 0 else None,
            },
            [sample_tenant_id],
        )
        if idx % 3 != 0 or paid > 0:
            pstatus = 'pending' if idx % 3 == 2 else 'approved'
            rec(
                pid,
                owner,
                'payments',
                f'pay-{inv_id}',
                {
                    'id': f'pay-{inv_id}',
                    'invoiceId': inv_id,
                    'tenantName': sample_tenant_name,
                    'room': '101',
                    'reportedAmount': total_due if pstatus == 'pending' else paid,
                    'paidAt': now_iso,
                    'method': 'Tiền mặt',
                    'reference': f'MAU-{pid}-11',
                    'status': pstatus,
                    'approvedAmount': paid if pstatus == 'approved' else None,
                    'reviewedAt': now_iso if pstatus == 'approved' else None,
                    'rejectionReason': None,
                    'proofBytes': None,
                    'proofName': None,
                    'proofUrl': None,
                    'paymentAccountId': None,
                },
                [sample_tenant_id],
            )

    # Rich operational records on existing quick-login properties op26-01-01..03.
    op_extras = [
        ('op26-01-01', 'report-demo-owner-1', 'lease-T0101001', 'T0101001', 'Vũ Thanh Vân', '101', 'Nhà trọ Bình Minh', 'Nguyễn Minh Anh', '27 Nguyễn Trãi, Phường Hoàn Kiếm, Thành phố Hà Nội'),
        ('op26-01-02', 'report-demo-owner-2', 'lease-T0102001', 'T0102001', 'Vũ Phúc Khang', '101', 'An Nhiên House', 'Nguyễn Quốc Bảo', '36 Trần Phú, Phường Hồng Hà, Thành phố Hà Nội'),
        ('op26-01-03', 'report-demo-owner-3', 'lease-T0103001', 'T0103001', 'Vũ Đình Long', '101', 'Mộc Lan Residence', 'Nguyễn Thanh Bình', '14 Lý Thường Kiệt, Phường Hai Bà Trưng, Thành phố Hà Nội'),
    ]
    for p_idx, (pid, owner, lid, tid, tname, room, pname, oname, paddr) in enumerate(op_extras):
        # Members: representative + pending roommate request + rejected request.
        rec(
            pid, owner, 'members', f'sample26-rep-{pid}',
            {
                'id': f'sample26-rep-{pid}', 'leaseId': lid, 'tenantId': tid,
                'name': tname, 'phone': f'090110010{p_idx + 1}',
                'joinedAt': '2026-08-01T00:00:00.000Z', 'isRepresentative': True,
                'status': 'active', 'rejectionReason': None,
                'requestedBy': tid, 'requestedAt': '2026-08-01T00:00:00.000Z',
            },
            [tid],
        )
        pending_names = ['Trần Minh Quân', 'Nguyễn Ngọc Hân', 'Phạm Gia Bảo']
        rec(
            pid, owner, 'members', f'sample26-pending-{pid}',
            {
                'id': f'sample26-pending-{pid}', 'leaseId': lid, 'tenantId': f'SMPMEM0{p_idx + 1}',
                'name': pending_names[p_idx], 'phone': f'090880020{p_idx + 1}',
                'joinedAt': (now + dt.timedelta(days=2)).isoformat(), 'isRepresentative': False,
                'status': 'pending', 'rejectionReason': None,
                'requestedBy': tid, 'requestedAt': (now - dt.timedelta(hours=6)).isoformat(),
            },
            [tid],
        )
        rec(
            pid, owner, 'members', f'sample26-rej-{pid}',
            {
                'id': f'sample26-rej-{pid}', 'leaseId': lid, 'tenantId': f'SMPREJ0{p_idx + 1}',
                'name': 'Lê Hoàng Nam', 'phone': f'090770020{p_idx + 1}',
                'joinedAt': (now - dt.timedelta(days=5)).isoformat(), 'isRepresentative': False,
                'status': 'rejected', 'rejectionReason': 'Cần bổ sung ảnh CCCD rõ nét trước khi duyệt.',
                'requestedBy': tid, 'requestedAt': (now - dt.timedelta(days=7)).isoformat(),
            },
            [tid],
        )

        # Incidents in inProgress, resolved (so tenant can test Mở lại / Xác nhận), closed.
        for s_idx, (st, title, cat, urgent) in enumerate([
            ('inProgress', 'Đèn hành lang tầng 2 nhấp nháy', 'Điện', False),
            ('resolved', 'Bảo trì khóa cửa vân tay cổng chính', 'Khác', True),
            ('closed', 'Vệ sinh định kỳ cục nóng máy lạnh', 'Điện lạnh', False),
        ]):
            inc_id = f'sample26-inc-{pid}-{st}'
            rec(
                pid, owner, 'incidents', inc_id,
                {
                    'id': inc_id, 'leaseId': lid, 'reporterId': tid, 'reporter': tname,
                    'room': room, 'title': title, 'category': cat,
                    'description': f'Yêu cầu xử lý sự cố tại {pname} · Phòng {room}.',
                    'date': (now - dt.timedelta(days=s_idx + 1)).strftime('%d/%m/%Y'),
                    'urgent': urgent, 'status': st,
                },
                [tid],
            )

        # Viewing appointments (pending, confirmed, cancelled) for Landlord & Tenant.
        for v_idx, (vst, rcode) in enumerate([('pending', '102'), ('confirmed', '201'), ('cancelled', '202')]):
            vid = f'sample26-view-{pid}-{vst}'
            rec(
                pid, owner, 'viewings', vid,
                {
                    'id': vid, 'propertyId': pid, 'tenantId': tid,
                    'roomName': f'{pname} · Phòng {rcode}', 'address': paddr,
                    'startsAt': (now + dt.timedelta(days=v_idx + 1, hours=10)).isoformat(),
                    'customerName': tname, 'phone': f'090110010{p_idx + 1}',
                    'personalNeeds': 'Cần phòng yên tĩnh, có chỗ để xe và ánh sáng tự nhiên.',
                    'status': vst, 'attendeeCount': 2 if v_idx == 0 else 1,
                    'roomId': f'{pid}:{rcode}', 'createdAt': (now - dt.timedelta(days=1)).isoformat(),
                },
                [tid],
            )

        # Meter readings for other rooms in op26-01-01..03 (pending & done).
        for r_idx, rcode in enumerate(['102', '201', '202']):
            done = r_idx == 0
            rec(
                pid, owner, 'readings', f'{rcode}:{period_nov}',
                {
                    'room': rcode, 'period': period_nov,
                    'oldElectric': 820 + r_idx * 35,
                    'newElectric': (875 + r_idx * 40) if done else None,
                    'oldWater': 64 + r_idx * 4,
                    'newWater': (70 + r_idx * 4) if done else None,
                },
                [],
            )

        # Past month readings for room 101 so period picker history has records too.
        rec(
            pid, owner, 'readings', f'101:{period_oct}',
            {
                'room': '101', 'period': period_oct,
                'oldElectric': 1000, 'newElectric': 1060,
                'oldWater': 100, 'newWater': 103,
            },
            [tid],
        )

        # Unread follow-up conversation on a vacant room for Tenant Discovery -> Chat demo.
        conv_id = f'sample26-chat-{pid}-201'
        conv_key = f'{pid}:conversations:{conv_id}'
        rec(
            pid, owner, 'conversations', conv_id,
            {
                'id': conv_id, 'propertyId': pid, 'tenantId': tid, 'ownerUid': owner,
                'leaseId': None, 'tenantName': tname, 'room': '201',
                'landlordName': oname, 'propertyName': pname,
                'messages': [], 'unread': 1, 'tenantUnread': 1,
                'lastRoomContext': {
                    'propertyId': pid, 'roomId': f'{pid}:201',
                    'roomName': f'{pname} · Phòng 201', 'propertyName': pname,
                    'source': 'discovery',
                },
                'roomContexts': [{
                    'propertyId': pid, 'roomId': f'{pid}:201',
                    'roomName': f'{pname} · Phòng 201', 'propertyName': pname,
                    'source': 'discovery',
                }],
            },
            [tid],
        )
        for m_idx, (from_l, text) in enumerate([
            (False, 'Anh/chị ơi phòng 201 tháng sau còn trống không ạ?'),
            (True, 'Chào bạn, phòng 201 hiện vẫn trống, bạn đặt lịch xem phòng giúp mình nhé.'),
        ]):
            rec(
                pid, owner, 'messages', f'{conv_id}:msg-{m_idx}',
                {
                    'id': f'msg-{m_idx}', 'text': text, 'time': f'10:0{m_idx + 2}',
                    'fromLandlord': from_l, 'createdAt': (now - dt.timedelta(hours=3 - m_idx)).isoformat(),
                    'index': m_idx, 'conversationId': conv_id, 'conversationKey': conv_key,
                },
                [tid],
            )

    # Support tickets obeying firestore.rules (created by active admin account).
    tickets = [
        ('sample26-tk-1', 'Kiểm tra hồ sơ xác minh Nhà trọ Ánh Dương', 'Chủ trọ đã gửi đầy đủ CCCD, ảnh chân dung và sổ hồng lên mục Xác minh nhà trọ.'),
        ('sample26-tk-2', 'Rà soát lịch xem phòng và yêu cầu thêm người tháng 11', 'Theo dõi các yêu cầu thêm người ở ghép tại Nhà trọ Bình Minh, An Nhiên House và Mộc Lan Residence.'),
        ('sample26-tk-3', 'Kiểm tra đồng bộ hóa đơn và gói dịch vụ TroPremium', 'Đã đối chiếu trạng thái gói dịch vụ và chỉ số điện nước kỳ tháng 11/2026.'),
    ]
    for tid, title, content in tickets:
        add_doc(
            f'support_tickets/{tid}',
            {
                'accountUid': admin_uid,
                'importBatch': BATCH_TAG,
                'data': {
                    'id': tid,
                    'role': 'admin',
                    'title': title,
                    'content': content,
                    'createdAt': (now - dt.timedelta(days=1)).isoformat(),
                    'reply': '',
                    'closed': False,
                },
            },
        )

    return additions, new_verified, new_proofs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--admin-email', default='demo-admin@example.com')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()

    token, admin_uid = sign_in_admin(args.admin_email)
    existing = {}
    for col in ('rental_properties', 'public_rooms', 'rental_records', 'support_tickets'):
        existing.update(list_collection(col, token))
    mgmt_path = 'management/system'
    mgmt_live = http_json(f'{BASE}/{mgmt_path}', token=token)

    now = dt.datetime.now(dt.timezone(dt.timedelta(hours=7))).replace(microsecond=0)
    additions, new_verified, new_proofs = build_additions(existing, now, admin_uid=admin_uid)

    mgmt_fields = {k: decode_value(v) for k, v in mgmt_live.get('fields', {}).items()}
    admin_obj = dict(mgmt_fields.get('admin', {}))
    verified_map = dict(admin_obj.get('verified', {}))
    proofs_map = dict(admin_obj.get('verificationProofs', {}))
    mgmt_changed = False
    for pid, flag in new_verified.items():
        if verified_map.get(pid) != flag or proofs_map.get(pid) != new_proofs[pid]:
            verified_map[pid] = flag
            proofs_map[pid] = new_proofs[pid]
            mgmt_changed = True
    admin_obj['verified'] = verified_map
    admin_obj['verificationProofs'] = proofs_map

    print(json.dumps({
        'existingDocsChecked': len(existing),
        'newDocuments': len(additions),
        'newProperties': sum(1 for p in additions if p.startswith('rental_properties/')),
        'newPublicRooms': sum(1 for p in additions if p.startswith('public_rooms/')),
        'newRecords': sum(1 for p in additions if p.startswith('rental_records/')),
        'newSupportTickets': sum(1 for p in additions if p.startswith('support_tickets/')),
        'updateManagementSystem': mgmt_changed,
        'apply': args.apply,
    }, ensure_ascii=False))

    if not args.apply:
        print('PREVIEW_ONLY')
        return

    doc_prefix = BASE.split('https://firestore.googleapis.com/v1/')[1]
    writes = [
        {
            'update': {
                'name': f'{doc_prefix}/{path}',
                'fields': {k: wire_value(v) for k, v in data.items()},
            },
            'currentDocument': {'exists': False},
        }
        for path, data in sorted(additions.items())
    ]
    if mgmt_changed:
        writes.append({
            'update': {
                'name': f'{doc_prefix}/{mgmt_path}',
                'fields': {k: wire_value(v) for k, v in {**mgmt_fields, 'admin': admin_obj}.items()},
            },
            'currentDocument': {'updateTime': mgmt_live['updateTime']},
        })

    for start in range(0, len(writes), 150):
        batch = writes[start:start + 150]
        http_json(f'{BASE}:commit', {'writes': batch}, token=token)
        print(f'Committed batch {start // 150 + 1}: {len(batch)} writes')
    # Close sample26-tk-3 in a separate update matching firestore.rules affectedKeys(['reply', 'closed']).
    tk3_path = 'support_tickets/sample26-tk-3'
    if tk3_path in additions:
        http_json(
            f'{BASE}:commit',
            {
                'writes': [{
                    'update': {
                        'name': f'{doc_prefix}/{tk3_path}',
                        'fields': {'data': wire_value({'reply': 'Đã kiểm tra đồng bộ dữ liệu, hóa đơn và gói dịch vụ hoạt động ổn định.', 'closed': True})},
                    },
                    'updateMask': {'fieldPaths': ['data.reply', 'data.closed']},
                }],
            },
            token=token,
        )
        print('Updated sample26-tk-3 reply/closed status')
    print('SEED_ADDITIONAL_SAMPLES_APPLIED')


if __name__ == '__main__':
    main()
