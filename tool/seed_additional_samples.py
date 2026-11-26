"""Seed additive, realistic sample properties, operational records, and demo state.

Adds 10 sample properties (`op26-02-01` .. `op26-02-10`) owned by the existing
demo landlords (`report-demo-owner-1..3`), full operational records across all
modules (members including leave requests, draft/terminated/renewal/termination
leases, multi-month invoices/payments/readings, incidents, viewings, chats,
announcements, VietQR payment accounts, landlord staff, support tickets across
roles, admin audit logs & commission statements, tenant favorites, and
Supabase subscription orders via `subscription-api`).

Additive & non-destructive: never overwrites populated user/admin/operational
state. Preview by default; pass `--apply` (with `FIREBASE_ADMIN_PASSWORD` or
interactive prompt) to publish to `tropremium-d14ac` and Supabase.
"""
import argparse
import copy
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
SUPABASE_SUBSCRIPTION_URL = (
    'https://hihsjrdzbtfldlscigzi.supabase.co/functions/v1/subscription-api'
)
SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_2oautia3Tc3XUFP1VGlVQw__uNfvWGC'
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

OWNER_ACCOUNTS = {
    'report-demo-owner-1': [
        {
            'bankName': 'Vietcombank',
            'accountName': 'NGUYEN MINH ANH',
            'accountNumber': '1028492011',
            'branch': 'CN Hoàn Kiếm - Hà Nội',
            'isDefault': True,
        },
        {
            'bankName': 'MBBank',
            'accountName': 'NGUYEN MINH ANH',
            'accountNumber': '090100000188',
            'branch': 'CN Thăng Long - Hà Nội',
            'isDefault': False,
        },
    ],
    'report-demo-owner-2': [
        {
            'bankName': 'Techcombank',
            'accountName': 'NGUYEN QUOC BAO',
            'accountNumber': '190368421055',
            'branch': 'CN Hải Châu - Đà Nẵng',
            'isDefault': True,
        },
        {
            'bankName': 'ACB',
            'accountName': 'NGUYEN QUOC BAO',
            'accountNumber': '218493021',
            'branch': 'CN Phú Nhuận - TP.HCM',
            'isDefault': False,
        },
    ],
    'report-demo-owner-3': [
        {
            'bankName': 'BIDV',
            'accountName': 'NGUYEN THANH BINH',
            'accountNumber': '3141000294812',
            'branch': 'CN Hai Bà Trưng - Hà Nội',
            'isDefault': True,
        },
        {
            'bankName': 'VPBank',
            'accountName': 'NGUYEN THANH BINH',
            'accountNumber': '2948105829',
            'branch': 'CN Quận 7 - TP.HCM',
            'isDefault': False,
        },
    ],
}

OWNER_STAFF = {
    'report-demo-owner-1': {
        'nextId': 10004,
        'staff': [
            {
                'id': 'nv-10001',
                'contact': {
                    'name': 'Trần Quốc Tuấn',
                    'phone': '0912345001',
                    'email': 'tuan.vanhanh@trop.vn',
                    'address': 'Hoàn Kiếm, Hà Nội',
                    'jobTitle': 'Quản lý vận hành khu trọ',
                },
            },
            {
                'id': 'nv-10002',
                'contact': {
                    'name': 'Lê Thị Thu Trang',
                    'phone': '0912345002',
                    'email': 'trang.ketoan@trop.vn',
                    'address': 'Bình Thạnh, TP.HCM',
                    'jobTitle': 'Kế toán & Thu ngân',
                },
            },
            {
                'id': 'nv-10003',
                'contact': {
                    'name': 'Phạm Văn Sơn',
                    'phone': '0912345003',
                    'email': 'son.kythuat@trop.vn',
                    'address': 'Cầu Giấy, Hà Nội',
                    'jobTitle': 'Kỹ thuật điện nước 24/7',
                },
            },
        ],
    },
    'report-demo-owner-2': {
        'nextId': 10004,
        'staff': [
            {
                'id': 'nv-20001',
                'contact': {
                    'name': 'Huỳnh Tấn Đạt',
                    'phone': '0932345001',
                    'email': 'dat.quanly@trop.vn',
                    'address': 'Sơn Trà, Đà Nẵng',
                    'jobTitle': 'Quản lý cơ sở miền Trung',
                },
            },
            {
                'id': 'nv-20002',
                'contact': {
                    'name': 'Võ Ngọc Bích',
                    'phone': '0932345002',
                    'email': 'bich.cskh@trop.vn',
                    'address': 'Phú Nhuận, TP.HCM',
                    'jobTitle': 'Tư vấn xem phòng & Hợp đồng',
                },
            },
            {
                'id': 'nv-20003',
                'contact': {
                    'name': 'Nguyễn Hữu Nghĩa',
                    'phone': '0932345003',
                    'email': 'nghia.baotri@trop.vn',
                    'address': 'Ninh Kiều, Cần Thơ',
                    'jobTitle': 'Bảo trì PCCC & An ninh',
                },
            },
        ],
    },
    'report-demo-owner-3': {
        'nextId': 10004,
        'staff': [
            {
                'id': 'nv-30001',
                'contact': {
                    'name': 'Đoàn Văn Khải',
                    'phone': '0942345001',
                    'email': 'khai.vanhanh@trop.vn',
                    'address': 'Thủ Dầu Một, Bình Dương',
                    'jobTitle': 'Quản lý tòa nhà',
                },
            },
            {
                'id': 'nv-30002',
                'contact': {
                    'name': 'Phan Mỹ Linh',
                    'phone': '0942345002',
                    'email': 'linh.hoadon@trop.vn',
                    'address': 'Quận 7, TP.HCM',
                    'jobTitle': 'Phụ trách ghi điện nước & Hóa đơn',
                },
            },
            {
                'id': 'nv-30003',
                'contact': {
                    'name': 'Bùi Anh Dũng',
                    'phone': '0942345003',
                    'email': 'dung.baove@trop.vn',
                    'address': 'Hai Bà Trưng, Hà Nội',
                    'jobTitle': 'Trực an ninh & Bãi xe',
                },
            },
        ],
    },
}

OWNER_PROPERTY_SPECS = [
    ('op26-01-01', 'report-demo-owner-1', 'T0101001', 'Vũ Thanh Vân', 'Nhà trọ Bình Minh'),
    ('op26-01-02', 'report-demo-owner-2', 'T0102001', 'Vũ Phúc Khang', 'An Nhiên House'),
    ('op26-01-03', 'report-demo-owner-3', 'T0103001', 'Vũ Đình Long', 'Mộc Lan Residence'),
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
    {
        'id': 'op26-02-10',
        'ownerUid': 'report-demo-owner-2',
        'ownerName': 'Nguyễn Quốc Bảo',
        'phone': '0902000210',
        'name': 'Lộc Vừng Homestay',
        'address': '214 Võ Văn Ngân, Phường Bình Thọ, Thành phố Thủ Đức, TP. Hồ Chí Minh',
        'city': 'TP. Hồ Chí Minh',
        'ward': 'Phường Bình Thọ',
        'description': 'Lộc Vừng Homestay gần ĐH Sư phạm Kỹ thuật, phòng có ban công riêng, thang máy, máy giặt sấy tầng thượng và khóa vân tay 2 lớp.',
        'amenities': ['Wifi', 'Ban công', 'Thang máy', 'Máy lạnh', 'Camera'],
        'state': 'resubmitted',
        'rentBase': 3600000,
    },
]

DEMO_ACCOUNTS = {
    'admin': ('report-demo-admin', 'demo-admin@example.com'),
    'owner1': ('report-demo-owner-1', 'demo-owner-01-01@example.com'),
    'owner2': ('report-demo-owner-2', 'demo-owner-01-02@example.com'),
    'owner3': ('report-demo-owner-3', 'demo-owner-01-03@example.com'),
    'tenant1': ('report-demo-tenant-1', 'demo-tenant-t0101001@example.com'),
    'tenant2': ('report-demo-tenant-2', 'demo-tenant-t0102001@example.com'),
    'tenant3': ('report-demo-tenant-3', 'demo-tenant-t0103001@example.com'),
}


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


def http_json(url, data=None, token=None, headers=None):
    req_headers = {'Content-Type': 'application/json'}
    if token:
        req_headers['Authorization'] = 'Bearer ' + token
    if headers:
        req_headers.update(headers)
    payload = None if data is None else json.dumps(data, ensure_ascii=False).encode('utf-8')
    with urllib.request.urlopen(urllib.request.Request(url, data=payload, headers=req_headers), timeout=30) as resp:
        return json.load(resp)


def firebase_config():
    cfg = (ROOT / 'lib/firebase_options.dart').read_text(encoding='utf-8')
    web = re.search(r'FirebaseOptions web\s*=\s*FirebaseOptions\((.*?)\);', cfg, re.S)
    key = re.search(r"apiKey:\s*'([^']+)'", web.group(1)).group(1)
    proj = re.search(r"projectId:\s*'([^']+)'", web.group(1)).group(1)
    if proj != PROJECT_ID:
        raise RuntimeError(f'Unexpected projectId: {proj}')
    return key


def sign_in_account(email, password):
    api_key = firebase_config()
    resp = http_json(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' + quote(api_key, safe=''),
        {'email': email, 'password': password, 'returnSecureToken': True},
    )
    return resp['idToken'], resp['localId']


def sign_in_admin(email, password=None):
    secret = password or os.environ.get('FIREBASE_ADMIN_PASSWORD') or getpass.getpass('Firebase admin password (hidden): ')
    return sign_in_account(email, secret)


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


def _payment_accounts_for(pid, owner_uid):
    specs = OWNER_ACCOUNTS.get(owner_uid, OWNER_ACCOUNTS['report-demo-owner-1'])
    return [
        {
            'id': f'acc-{pid}-{i + 1}',
            'bankName': s['bankName'],
            'accountName': s['accountName'],
            'accountNumber': s['accountNumber'],
            'branch': s['branch'],
            'isDefault': s['isDefault'],
            'isActive': True,
            'isVerified': True,
        }
        for i, s in enumerate(specs)
    ]


def _lease_payload(
    *,
    lease_id,
    tenant_id,
    property_id,
    room,
    tenant_name,
    phone,
    start_date,
    end_date,
    monthly_rent,
    owner_name,
    owner_phone,
    property_address,
    city,
    status='active',
    note='Hợp đồng mẫu phục vụ demo vận hành.',
    bank_account=None,
    termination_reason='',
    terminated_at=None,
    termination_request_status='',
    termination_requested_at=None,
    termination_requested_by='',
    termination_request_reason='',
    renewal_status='',
    renewal_requested_at=None,
    renewal_requested_by='',
    renewal_proposed_end_date=None,
    renewal_reason='',
):
    return {
        'id': lease_id,
        'tenantId': tenant_id,
        'propertyId': property_id,
        'room': room,
        'tenantName': tenant_name,
        'phone': phone,
        'startDate': start_date,
        'endDate': end_date,
        'monthlyRent': monthly_rent,
        'deposit': monthly_rent,
        'termMonths': 12,
        'dueDay': 5,
        'landlordName': owner_name,
        'landlordPermanentAddress': property_address,
        'landlordCitizenId': '',
        'landlordContact': owner_phone,
        'landlordBirthDate': None,
        'landlordCitizenIssueDate': None,
        'landlordCitizenIssuePlace': '',
        'tenantBirthYear': '2000',
        'tenantBirthDate': None,
        'tenantCitizenId': '',
        'tenantCitizenIssueDate': None,
        'tenantCitizenIssuePlace': '',
        'tenantPermanentAddress': city,
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
        'bankTransferEnabled': bank_account is not None,
        'bankName': bank_account['bankName'] if bank_account else '',
        'bankAccountNumber': bank_account['accountNumber'] if bank_account else '',
        'occupantCount': 2,
        'status': status,
        'note': note,
        'responsibilityA': '',
        'responsibilityB': '',
        'commonResponsibilities': '',
        'templateId': '',
        'rentalAddress': property_address,
        'terminationReason': termination_reason,
        'terminatedAt': terminated_at,
        'terminationRequestStatus': termination_request_status,
        'terminationRequestedAt': termination_requested_at,
        'terminationRequestedBy': termination_requested_by,
        'terminationRequestReason': termination_request_reason,
        'terminationReviewedAt': None,
        'terminationRejectionReason': '',
        'renewalStatus': renewal_status,
        'renewalRequestedAt': renewal_requested_at,
        'renewalRequestedBy': renewal_requested_by,
        'renewalProposedEndDate': renewal_proposed_end_date,
        'renewalReason': renewal_reason,
        'renewalReviewedAt': None,
        'renewalRejectionReason': '',
    }


def _announcements_bundle(pid, pname, tid, now):
    notices = [
        {
            'id': f'notice-{pid}-1',
            'title': f'Nhắc hạn đóng tiền phòng & dịch vụ kỳ 11/2026',
            'content': f'Kính gửi anh/chị đang thuê tại {pname}, vui lòng kiểm tra hóa đơn tháng 11 và thanh toán trước ngày 05 hàng tháng.',
            'category': 'finance',
            'createdAt': (now - dt.timedelta(days=2)).isoformat(),
            'propertyId': pid,
            'isRead': False,
            'priority': 'high',
            'recipients': [tid],
            'audienceLabel': f'Phòng 101 · {pname}',
        },
        {
            'id': f'notice-{pid}-2',
            'title': 'Lịch vệ sinh khu vực chung & kiểm tra đồng hồ điện nước',
            'content': 'Khu trọ tiến hành vệ sinh hành lang, sân xe và chốt chỉ số điện nước vào cuối tuần. Vui lòng giữ khu vực chung gọn gàng.',
            'category': 'operations',
            'createdAt': (now - dt.timedelta(days=6)).isoformat(),
            'propertyId': pid,
            'isRead': True,
            'priority': 'normal',
            'recipients': [],
            'audienceLabel': 'Toàn bộ người thuê',
        },
        {
            'id': f'notice-{pid}-3',
            'title': 'Kiểm tra thiết bị PCCC & bảo trì khóa vân tay cổng chính',
            'content': 'Kỹ thuật viên sẽ kiểm tra bình chữa cháy các tầng và cập nhật vân tay mới cho thành viên vừa được duyệt.',
            'category': 'incident',
            'createdAt': (now - dt.timedelta(days=10)).isoformat(),
            'propertyId': pid,
            'isRead': False,
            'priority': 'normal',
            'recipients': [],
            'audienceLabel': 'Toàn bộ người thuê',
        },
    ]
    return {
        'sent': notices,
        'recipients': {n['id']: [tid] for n in notices},
        'readByTenant': {tid: [f'notice-{pid}-2']},
        'landlordRead': [f'notice-{pid}-2', f'notice-{pid}-3'],
        'nextId': 10010,
    }


def utc_iso(d):
    return d.astimezone(dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.000Z')


def build_additions(existing, now, admin_uid='report-demo-admin'):
    now_iso = utc_iso(now)
    period_nov = '2026-10-31T17:00:00.000Z'
    period_oct = '2026-09-30T17:00:00.000Z'
    period_sep = '2026-08-31T17:00:00.000Z'
    portrait_bytes = make_sample_png_bytes((24, 118, 178))
    id_front_bytes = make_sample_png_bytes((15, 138, 108))
    id_back_bytes = make_sample_png_bytes((42, 148, 120))
    owner_bytes = make_sample_png_bytes((194, 112, 48))
    receipt_bytes = make_sample_png_bytes((18, 140, 92))

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

    sample_tenants = [
        ('SMP26001', 'Lê Hoàng Minh'),
        ('SMP26002', 'Trần Thị Thu Hà'),
        ('SMP26003', 'Phạm Đức Anh'),
        ('SMP26004', 'Ngô Bảo Châu'),
        ('SMP26005', 'Đỗ Gia Huy'),
        ('SMP26006', 'Bùi Khánh Linh'),
        ('SMP26007', 'Võ Trung Kiên'),
        ('SMP26008', 'Hoàng Lan Anh'),
        ('SMP26009', 'Đặng Quang Hải'),
        ('SMP26010', 'Trương Gia Hân'),
    ]

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
        occupied_codes = {'101', '102'} if spec['state'] == 'resubmitted' else {'101'}
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
                    'available': room['code'] not in occupied_codes,
                    'importBatch': BATCH_TAG,
                    'isDemo': True,
                    'generation': 'synthetic',
                },
            )

        sample_tenant_id, sample_tenant_name = sample_tenants[idx]
        accounts = _payment_accounts_for(pid, owner)
        default_acc = accounts[0]
        lease_id = f'lease-{pid}-101'
        lease_readers = [sample_tenant_id]
        if pid == 'op26-02-10':
            lease_readers = [sample_tenant_id, 'SMP26011']

        rec(pid, owner, 'settings', pid, {'counters': [10000] * 7, 'paymentAccounts': accounts}, [sample_tenant_id])

        if spec['state'] in ('verified', 'pending', 'supplement', 'resubmitted'):
            submitted_at = (
                utc_iso(now - dt.timedelta(days=1))
                if spec['state'] == 'supplement'
                else now_iso
            )
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
            else 'Đã yêu cầu bổ sung ảnh hợp đồng mẫu và ảnh mặt tiền nhà trọ rõ nét hơn.'
            if spec['state'] == 'resubmitted'
            else ''
        )
        review_submission_at = (
            utc_iso(now - dt.timedelta(days=1))
            if spec['state'] == 'supplement'
            else utc_iso(now - dt.timedelta(days=2))
            if spec['state'] == 'resubmitted'
            else None
        )
        review_requested_at = (
            now_iso
            if spec['state'] == 'supplement'
            else utc_iso(now - dt.timedelta(days=1))
            if spec['state'] == 'resubmitted'
            else None
        )
        rec(
            pid,
            owner,
            'verificationReview',
            pid,
            {
                'note': review_note,
                'requestedAt': review_requested_at,
                'submissionAt': review_submission_at,
            },
            [],
        )

        # Primary active lease on room 101 (resubmitted property carries renewalStatus=pending).
        rec(
            pid,
            owner,
            'leases',
            lease_id,
            _lease_payload(
                lease_id=lease_id,
                tenant_id=sample_tenant_id,
                property_id=pid,
                room='101',
                tenant_name=sample_tenant_name,
                phone=f'09120003{idx + 1:02d}',
                start_date='2026-08-01T00:00:00.000Z',
                end_date='2027-08-01T00:00:00.000Z',
                monthly_rent=rent1,
                owner_name=spec['ownerName'],
                owner_phone=spec['phone'],
                property_address=spec['address'],
                city=spec['city'],
                bank_account=default_acc,
                renewal_status='pending' if pid == 'op26-02-10' else '',
                renewal_requested_at=(now - dt.timedelta(hours=10)).isoformat() if pid == 'op26-02-10' else None,
                renewal_requested_by=sample_tenant_id if pid == 'op26-02-10' else '',
                renewal_proposed_end_date='2028-02-01T00:00:00.000Z' if pid == 'op26-02-10' else None,
                renewal_reason='Gia hạn thêm 6 tháng để tiếp tục công tác gần khu vực Thủ Đức.' if pid == 'op26-02-10' else '',
            ),
            [sample_tenant_id],
        )
        if pid == 'op26-02-10':
            # Second active lease on room 102 with pending termination request.
            rec(
                pid,
                owner,
                'leases',
                'lease-op26-02-10-102',
                _lease_payload(
                    lease_id='lease-op26-02-10-102',
                    tenant_id='SMP26011',
                    property_id=pid,
                    room='102',
                    tenant_name='Lý Minh Khôi',
                    phone='0912000399',
                    start_date='2026-07-15T00:00:00.000Z',
                    end_date='2027-07-15T00:00:00.000Z',
                    monthly_rent=rent1,
                    owner_name=spec['ownerName'],
                    owner_phone=spec['phone'],
                    property_address=spec['address'],
                    city=spec['city'],
                    bank_account=default_acc,
                    termination_request_status='pending',
                    termination_requested_at=(now - dt.timedelta(hours=5)).isoformat(),
                    termination_requested_by='SMP26011',
                    termination_request_reason='Chuyển nơi làm việc sang chi nhánh Bình Dương đầu tháng tới.',
                ),
                ['SMP26011'],
            )

        # Draft + Terminated sample leases on every op26-02 property (vacant rooms remain available).
        rec(
            pid,
            owner,
            'leases',
            f'sample26-draft-{pid}',
            _lease_payload(
                lease_id=f'sample26-draft-{pid}',
                tenant_id=f'SMPDRF{idx + 1:02d}',
                property_id=pid,
                room='201',
                tenant_name='Nguyễn Hải Đăng',
                phone=f'09150004{idx + 1:02d}',
                start_date=(now + dt.timedelta(days=5)).isoformat(),
                end_date=(now + dt.timedelta(days=370)).isoformat(),
                monthly_rent=rent2,
                owner_name=spec['ownerName'],
                owner_phone=spec['phone'],
                property_address=spec['address'],
                city=spec['city'],
                status='draft',
                note='Bản nháp hợp đồng chờ khách đặt cọc và ký xác nhận.',
                bank_account=default_acc,
            ),
            [],
        )
        rec(
            pid,
            owner,
            'leases',
            f'sample26-term-{pid}',
            _lease_payload(
                lease_id=f'sample26-term-{pid}',
                tenant_id=f'SMPTRM{idx + 1:02d}',
                property_id=pid,
                room='102' if pid != 'op26-02-10' else '202',
                tenant_name='Phan Thị Thanh Tâm',
                phone=f'09160005{idx + 1:02d}',
                start_date='2025-11-01T00:00:00.000Z',
                end_date='2026-10-31T00:00:00.000Z',
                monthly_rent=rent1,
                owner_name=spec['ownerName'],
                owner_phone=spec['phone'],
                property_address=spec['address'],
                city=spec['city'],
                status='terminated',
                note='Đã thanh lý hợp đồng và hoàn cọc đầy đủ.',
                bank_account=default_acc,
                termination_reason='Hết thời hạn thuê và đã bàn giao phòng đúng quy định.',
                terminated_at='2026-10-31T10:00:00.000Z',
            ),
            [],
        )

        # Meter readings across Nov, Oct, Sep.
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
        for p_month, old_e, new_e, old_w, new_w in [
            (period_oct, 930, 1000, 114, 120),
            (period_sep, 865, 930, 108, 114),
        ]:
            rec(
                pid,
                owner,
                'readings',
                f'101:{p_month}',
                {'room': '101', 'period': p_month, 'oldElectric': old_e, 'newElectric': new_e, 'oldWater': old_w, 'newWater': new_w},
                [sample_tenant_id],
            )

        # Nov 2026 invoice + payment.
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
            is_bank = idx % 2 == 1
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
                    'method': 'Chuyển khoản' if is_bank else 'Tiền mặt',
                    'reference': f'CK-{pid.upper()}-11' if is_bank else f'MAU-{pid}-11',
                    'status': pstatus,
                    'approvedAmount': paid if pstatus == 'approved' else None,
                    'reviewedAt': now_iso if pstatus == 'approved' else None,
                    'rejectionReason': None,
                    'proofBytes': receipt_bytes if is_bank else None,
                    'proofName': f'bien-lai-{pid}-11.png' if is_bank else None,
                    'proofUrl': None,
                    'paymentAccountId': default_acc['id'] if is_bank else None,
                },
                [sample_tenant_id],
            )

        # Oct & Sep 2026 historical invoices & approved bank-transfer payments.
        for m_num, m_period, m_due, e_kwh, w_m3 in [
            (10, period_oct, '2026-10-05T17:00:00.000Z', 70, 6),
            (9, period_sep, '2026-09-05T17:00:00.000Z', 65, 6),
        ]:
            m_charges = [
                {'name': 'Tiền thuê phòng', 'amount': rent1},
                {'name': f'Điện · {e_kwh} kWh', 'amount': e_kwh * 3800},
                {'name': f'Nước · {w_m3} m³', 'amount': w_m3 * 16000},
                {'name': 'Internet & vệ sinh', 'amount': 130000},
            ]
            m_total = sum(c['amount'] for c in m_charges)
            m_inv_id = f'sample26-inv-{pid}-{m_num:02d}'
            m_pay_id = f'pay-{m_inv_id}'
            m_paid_at = f'2026-{m_num:02d}-04T09:30:00+07:00'
            m_rev_at = f'2026-{m_num:02d}-04T14:15:00+07:00'
            rec(
                pid,
                owner,
                'invoices',
                m_inv_id,
                {
                    'id': m_inv_id,
                    'leaseId': lease_id,
                    'room': '101',
                    'tenantName': sample_tenant_name,
                    'period': m_period,
                    'dueDate': m_due,
                    'charges': m_charges,
                    'paidAmount': m_total,
                    'cancelled': False,
                    'pendingPaymentId': None,
                    'lastApprovedPaymentId': m_pay_id,
                },
                [sample_tenant_id],
            )
            rec(
                pid,
                owner,
                'payments',
                m_pay_id,
                {
                    'id': m_pay_id,
                    'invoiceId': m_inv_id,
                    'tenantName': sample_tenant_name,
                    'room': '101',
                    'reportedAmount': m_total,
                    'paidAt': m_paid_at,
                    'method': 'Chuyển khoản' if m_num == 10 else 'Tiền mặt',
                    'reference': f'TP-{pid.upper()}-{m_num:02d}',
                    'status': 'approved',
                    'approvedAmount': m_total,
                    'reviewedAt': m_rev_at,
                    'rejectionReason': None,
                    'proofBytes': receipt_bytes if m_num == 10 else None,
                    'proofName': f'unc-{pid}-{m_num:02d}.png' if m_num == 10 else None,
                    'proofUrl': None,
                    'paymentAccountId': default_acc['id'] if m_num == 10 else None,
                },
                [sample_tenant_id],
            )

        # Full members on every op26-02 property (representative + active roommate + pending + rejected + leave request).
        rec(
            pid,
            owner,
            'members',
            f'sample26-rep-{pid}',
            {
                'id': f'sample26-rep-{pid}',
                'leaseId': lease_id,
                'tenantId': sample_tenant_id,
                'name': sample_tenant_name,
                'phone': f'09120003{idx + 1:02d}',
                'joinedAt': '2026-08-01T00:00:00.000Z',
                'isRepresentative': True,
                'status': 'active',
                'rejectionReason': None,
                'requestedBy': sample_tenant_id,
                'requestedAt': '2026-08-01T00:00:00.000Z',
            },
            [sample_tenant_id],
        )
        rec(
            pid,
            owner,
            'members',
            f'sample26-mate-{pid}',
            {
                'id': f'sample26-mate-{pid}',
                'leaseId': lease_id,
                'tenantId': f'SMPM{idx + 1:02d}B',
                'name': 'Đỗ Minh Khang' if idx % 2 == 0 else 'Nguyễn Thảo Vy',
                'phone': f'09081112{idx + 1:02d}',
                'joinedAt': '2026-09-01T00:00:00.000Z',
                'isRepresentative': False,
                'status': 'active',
                'rejectionReason': None,
                'requestedBy': sample_tenant_id,
                'requestedAt': '2026-08-29T09:00:00.000Z',
                'leaveReason': 'Chuyển chỗ làm gần khu công nghệ cao vào đầu tháng sau.' if idx in (0, 3, 6, 9) else None,
                'leaveRequestedAt': (now - dt.timedelta(hours=12)).isoformat() if idx in (0, 3, 6, 9) else None,
                'leaveEffectiveAt': (now + dt.timedelta(days=10)).isoformat() if idx in (0, 3, 6, 9) else None,
                'leaveAcknowledgedAt': None,
            },
            [sample_tenant_id],
        )
        rec(
            pid,
            owner,
            'members',
            f'sample26-pending-{pid}',
            {
                'id': f'sample26-pending-{pid}',
                'leaseId': lease_id,
                'tenantId': f'SMPMEM{idx + 1:02d}',
                'name': 'Trần Minh Quân',
                'phone': f'09088002{idx + 1:02d}',
                'joinedAt': (now + dt.timedelta(days=2)).isoformat(),
                'isRepresentative': False,
                'status': 'pending',
                'rejectionReason': None,
                'requestedBy': sample_tenant_id,
                'requestedAt': (now - dt.timedelta(hours=6)).isoformat(),
            },
            [sample_tenant_id],
        )
        rec(
            pid,
            owner,
            'members',
            f'sample26-rej-{pid}',
            {
                'id': f'sample26-rej-{pid}',
                'leaseId': lease_id,
                'tenantId': f'SMPREJ{idx + 1:02d}',
                'name': 'Lê Hoàng Nam',
                'phone': f'09077002{idx + 1:02d}',
                'joinedAt': (now - dt.timedelta(days=5)).isoformat(),
                'isRepresentative': False,
                'status': 'rejected',
                'rejectionReason': 'Cần bổ sung ảnh CCCD rõ nét trước khi duyệt.',
                'requestedBy': sample_tenant_id,
                'requestedAt': (now - dt.timedelta(days=7)).isoformat(),
            },
            [sample_tenant_id],
        )

        # Full incidents across statuses on every op26-02 property.
        for s_idx, (st, title, cat, urgent) in enumerate([
            ('newly', f'Vòi sen phòng tắm rỉ nhẹ', 'Nước', True),
            ('inProgress', f'Kiểm tra ổ cắm bàn học phòng 101', 'Điện', False),
            ('resolved', f'Bảo dưỡng định kỳ điều hòa phòng 101', 'Điện lạnh', False),
            ('closed', f'Cài lại vân tay cửa cổng chính', 'Khác', False),
        ]):
            inc_id = f'sample26-inc-{pid}-{st}'
            rec(
                pid,
                owner,
                'incidents',
                inc_id,
                {
                    'id': inc_id,
                    'leaseId': lease_id,
                    'reporterId': sample_tenant_id,
                    'reporter': sample_tenant_name,
                    'room': '101',
                    'title': title,
                    'category': cat,
                    'description': f'Yêu cầu xử lý sự cố tại {spec["name"]} · Phòng 101.',
                    'date': (now - dt.timedelta(days=s_idx + 1)).strftime('%d/%m/%Y'),
                    'urgent': urgent,
                    'status': st,
                },
                [sample_tenant_id],
            )

        # Viewings on every op26-02 property; link quick-login tenants on showcase properties.
        linked_viewer = {
            'op26-02-01': ('T0101001', 'Vũ Thanh Vân', '0901100101'),
            'op26-02-04': ('T0102001', 'Vũ Phúc Khang', '0901100102'),
            'op26-02-07': ('T0103001', 'Vũ Đình Long', '0901100103'),
        }.get(pid)
        for v_idx, (vst, rcode) in enumerate([('pending', '102'), ('confirmed', '201'), ('cancelled', '202')]):
            vid = f'sample26-view-{pid}-{vst}'
            v_tid, v_name, v_phone = (
                linked_viewer
                if (linked_viewer is not None and v_idx in (0, 1))
                else (sample_tenant_id, sample_tenant_name, f'09120003{idx + 1:02d}')
            )
            rec(
                pid,
                owner,
                'viewings',
                vid,
                {
                    'id': vid,
                    'propertyId': pid,
                    'tenantId': v_tid,
                    'roomName': f"{spec['name']} · Phòng {rcode}",
                    'address': spec['address'],
                    'startsAt': (now + dt.timedelta(days=v_idx + 1, hours=9 + v_idx)).isoformat(),
                    'customerName': v_name,
                    'phone': v_phone,
                    'personalNeeds': 'Cần phòng yên tĩnh, gần khu tiện ích và có chỗ để xe an toàn.',
                    'status': vst,
                    'attendeeCount': 2 if v_idx == 0 else 1,
                    'roomId': f'{pid}:{rcode}',
                    'createdAt': (now - dt.timedelta(days=1)).isoformat(),
                },
                [v_tid],
            )

        # Active lease chat on every op26-02 property + Discovery chat for quick-login tenants on showcase properties.
        conv_lease_id = f'sample26-chat-{pid}-101'
        conv_lease_key = f'{pid}:conversations:{conv_lease_id}'
        rec(
            pid,
            owner,
            'conversations',
            conv_lease_id,
            {
                'id': conv_lease_id,
                'propertyId': pid,
                'tenantId': sample_tenant_id,
                'ownerUid': owner,
                'leaseId': lease_id,
                'tenantName': sample_tenant_name,
                'room': '101',
                'landlordName': spec['ownerName'],
                'propertyName': spec['name'],
                'messages': [],
                'unread': 1 if idx % 2 == 0 else 0,
                'tenantUnread': 1,
                'lastRoomContext': None,
                'roomContexts': [],
            },
            [sample_tenant_id],
        )
        for m_idx, (from_l, text) in enumerate([
            (False, f'Chào {spec["ownerName"]}, em gửi xác nhận chuyển khoản tiền phòng kỳ tháng 11 ạ.'),
            (True, 'Chào em, anh/chị đã nhận được thông tin và đang đối soát hóa đơn nhé.'),
            (False, 'Dạ em cảm ơn anh/chị ạ.'),
        ]):
            rec(
                pid,
                owner,
                'messages',
                f'{conv_lease_id}:msg-{m_idx}',
                {
                    'id': f'msg-{m_idx}',
                    'text': text,
                    'time': f'08:3{m_idx}',
                    'fromLandlord': from_l,
                    'createdAt': (now - dt.timedelta(hours=5 - m_idx)).isoformat(),
                    'index': m_idx,
                    'conversationId': conv_lease_id,
                    'conversationKey': conv_lease_key,
                },
                [sample_tenant_id],
            )

        if linked_viewer is not None:
            lv_tid, lv_name, _ = linked_viewer
            conv_disc_id = f'sample26-chat-{pid}-201'
            conv_disc_key = f'{pid}:conversations:{conv_disc_id}'
            rec(
                pid,
                owner,
                'conversations',
                conv_disc_id,
                {
                    'id': conv_disc_id,
                    'propertyId': pid,
                    'tenantId': lv_tid,
                    'ownerUid': owner,
                    'leaseId': None,
                    'tenantName': lv_name,
                    'room': '201',
                    'landlordName': spec['ownerName'],
                    'propertyName': spec['name'],
                    'messages': [],
                    'unread': 1,
                    'tenantUnread': 1,
                    'lastRoomContext': {
                        'propertyId': pid,
                        'roomId': f'{pid}:201',
                        'roomName': f"{spec['name']} · Phòng 201",
                        'propertyName': spec['name'],
                        'source': 'discovery',
                    },
                    'roomContexts': [{
                        'propertyId': pid,
                        'roomId': f'{pid}:201',
                        'roomName': f"{spec['name']} · Phòng 201",
                        'propertyName': spec['name'],
                        'source': 'discovery',
                    }],
                },
                [lv_tid],
            )
            for m_idx, (from_l, text) in enumerate([
                (False, f'Anh/chị ơi phòng 201 tại {spec["name"]} có ban công không ạ?'),
                (True, 'Có ban công thoáng và đầy đủ máy lạnh nhé bạn, mời bạn ghé xem phòng.'),
            ]):
                rec(
                    pid,
                    owner,
                    'messages',
                    f'{conv_disc_id}:msg-{m_idx}',
                    {
                        'id': f'msg-{m_idx}',
                        'text': text,
                        'time': f'14:1{m_idx}',
                        'fromLandlord': from_l,
                        'createdAt': (now - dt.timedelta(hours=2 - m_idx)).isoformat(),
                        'index': m_idx,
                        'conversationId': conv_disc_id,
                        'conversationKey': conv_disc_key,
                    },
                    [lv_tid],
                )

        # Announcements for landlord & tenant on every op26-02 property.
        ann_data = _announcements_bundle(pid, spec['name'], sample_tenant_id, now)
        rec(pid, owner, 'announcements', pid, ann_data, [])
        rec(pid, owner, 'tenantAnnouncements', sample_tenant_id, ann_data, [sample_tenant_id])

    # Rich operational records on existing quick-login properties op26-01-01..03.
    op_extras = [
        ('op26-01-01', 'report-demo-owner-1', 'lease-T0101001', 'T0101001', 'Vũ Thanh Vân', '101', 'Nhà trọ Bình Minh', 'Nguyễn Minh Anh', '27 Nguyễn Trãi, Phường Hoàn Kiếm, Thành phố Hà Nội', 'Thành phố Hà Nội', 3000000),
        ('op26-01-02', 'report-demo-owner-2', 'lease-T0102001', 'T0102001', 'Vũ Phúc Khang', '101', 'An Nhiên House', 'Nguyễn Quốc Bảo', '36 Trần Phú, Phường Hồng Hà, Thành phố Hà Nội', 'Thành phố Hà Nội', 3300000),
        ('op26-01-03', 'report-demo-owner-3', 'lease-T0103001', 'T0103001', 'Vũ Đình Long', '101', 'Mộc Lan Residence', 'Nguyễn Thanh Bình', '14 Lý Thường Kiệt, Phường Hai Bà Trưng, Thành phố Hà Nội', 'Thành phố Hà Nội', 3600000),
    ]
    for p_idx, (pid, owner, lid, tid, tname, room, pname, oname, paddr, pcity, prent) in enumerate(op_extras):
        default_acc = _payment_accounts_for(pid, owner)[0]
        rec(
            pid,
            owner,
            'members',
            f'sample26-rep-{pid}',
            {
                'id': f'sample26-rep-{pid}',
                'leaseId': lid,
                'tenantId': tid,
                'name': tname,
                'phone': f'090110010{p_idx + 1}',
                'joinedAt': '2026-08-01T00:00:00.000Z',
                'isRepresentative': True,
                'status': 'active',
                'rejectionReason': None,
                'requestedBy': tid,
                'requestedAt': '2026-08-01T00:00:00.000Z',
            },
            [tid],
        )
        pending_names = ['Trần Minh Quân', 'Nguyễn Ngọc Hân', 'Phạm Gia Bảo']
        rec(
            pid,
            owner,
            'members',
            f'sample26-pending-{pid}',
            {
                'id': f'sample26-pending-{pid}',
                'leaseId': lid,
                'tenantId': f'SMPMEM0{p_idx + 1}',
                'name': pending_names[p_idx],
                'phone': f'090880020{p_idx + 1}',
                'joinedAt': (now + dt.timedelta(days=2)).isoformat(),
                'isRepresentative': False,
                'status': 'pending',
                'rejectionReason': None,
                'requestedBy': tid,
                'requestedAt': (now - dt.timedelta(hours=6)).isoformat(),
            },
            [tid],
        )
        rec(
            pid,
            owner,
            'members',
            f'sample26-rej-{pid}',
            {
                'id': f'sample26-rej-{pid}',
                'leaseId': lid,
                'tenantId': f'SMPREJ0{p_idx + 1}',
                'name': 'Lê Hoàng Nam',
                'phone': f'090770020{p_idx + 1}',
                'joinedAt': (now - dt.timedelta(days=5)).isoformat(),
                'isRepresentative': False,
                'status': 'rejected',
                'rejectionReason': 'Cần bổ sung ảnh CCCD rõ nét trước khi duyệt.',
                'requestedBy': tid,
                'requestedAt': (now - dt.timedelta(days=7)).isoformat(),
            },
            [tid],
        )
        # Active roommate requesting to leave room (appears in both Landlord & Tenant member tabs).
        rec(
            pid,
            owner,
            'members',
            f'sample26-leave-{pid}',
            {
                'id': f'sample26-leave-{pid}',
                'leaseId': lid,
                'tenantId': f'SMPLV0{p_idx + 1}',
                'name': ['Phạm Thảo Nhi', 'Lương Thế Vinh', 'Đinh Bảo Ngọc'][p_idx],
                'phone': f'090660020{p_idx + 1}',
                'joinedAt': '2026-08-15T00:00:00.000Z',
                'isRepresentative': False,
                'status': 'active',
                'rejectionReason': None,
                'requestedBy': tid,
                'requestedAt': '2026-08-14T09:00:00.000Z',
                'leaveReason': 'Chuyển công tác sang quận khác cuối tháng này.',
                'leaveRequestedAt': (now - dt.timedelta(hours=8)).isoformat(),
                'leaveEffectiveAt': (now + dt.timedelta(days=7)).isoformat(),
                'leaveAcknowledgedAt': None,
            },
            [tid],
        )

        # Draft + Terminated sample leases on default properties so Contract filter chips are populated.
        rec(
            pid,
            owner,
            'leases',
            f'sample26-draft-{pid}',
            _lease_payload(
                lease_id=f'sample26-draft-{pid}',
                tenant_id=f'SMP01DRF{p_idx + 1}',
                property_id=pid,
                room='201',
                tenant_name=['Nguyễn Thảo Linh', 'Hoàng Anh Tú', 'Vũ Bảo Trâm'][p_idx],
                phone=f'091700030{p_idx + 1}',
                start_date=(now + dt.timedelta(days=4)).isoformat(),
                end_date=(now + dt.timedelta(days=369)).isoformat(),
                monthly_rent=prent + 300000,
                owner_name=oname,
                owner_phone=f'000100000{p_idx + 1}',
                property_address=paddr,
                city=pcity,
                status='draft',
                note='Hợp đồng nháp chờ khách chuyển cọc giữ phòng 201.',
                bank_account=default_acc,
            ),
            [],
        )
        rec(
            pid,
            owner,
            'leases',
            f'sample26-term-{pid}',
            _lease_payload(
                lease_id=f'sample26-term-{pid}',
                tenant_id=f'SMP01TRM{p_idx + 1}',
                property_id=pid,
                room='102',
                tenant_name=['Lê Quang Minh', 'Trần Bảo Vy', 'Ngô Gia Kiệt'][p_idx],
                phone=f'091800030{p_idx + 1}',
                start_date='2025-10-01T00:00:00.000Z',
                end_date='2026-09-30T00:00:00.000Z',
                monthly_rent=prent,
                owner_name=oname,
                owner_phone=f'000100000{p_idx + 1}',
                property_address=paddr,
                city=pcity,
                status='terminated',
                note='Đã thanh lý hợp đồng đúng hạn và bàn giao chìa khóa.',
                bank_account=default_acc,
                termination_reason='Hết hạn hợp đồng năm học, người thuê tốt nghiệp.',
                terminated_at='2026-09-30T15:00:00.000Z',
            ),
            [],
        )

        # Sep 2026 invoice + approved bank transfer payment + reading on op26-01-01..03 for 3-month trends.
        sep_charges = [
            {'name': 'Tiền thuê phòng', 'amount': prent},
            {'name': 'Điện · 58 kWh', 'amount': 203000},
            {'name': 'Nước · 3 m³', 'amount': 45000},
            {'name': 'Internet và vệ sinh', 'amount': 130000},
        ]
        sep_total = sum(c['amount'] for c in sep_charges)
        sep_inv_id = f'sample26-inv-{pid}-09'
        sep_pay_id = f'pay-{sep_inv_id}'
        rec(
            pid,
            owner,
            'invoices',
            sep_inv_id,
            {
                'id': sep_inv_id,
                'leaseId': lid,
                'room': room,
                'tenantName': tname,
                'period': period_sep,
                'dueDate': '2026-09-05T17:00:00.000Z',
                'charges': sep_charges,
                'paidAmount': sep_total,
                'cancelled': False,
                'pendingPaymentId': None,
                'lastApprovedPaymentId': sep_pay_id,
            },
            [tid],
        )
        rec(
            pid,
            owner,
            'payments',
            sep_pay_id,
            {
                'id': sep_pay_id,
                'invoiceId': sep_inv_id,
                'tenantName': tname,
                'room': room,
                'reportedAmount': sep_total,
                'paidAt': '2026-09-04T10:00:00+07:00',
                'method': 'Chuyển khoản',
                'reference': f'CK-{pid.upper()}-09',
                'status': 'approved',
                'approvedAmount': sep_total,
                'reviewedAt': '2026-09-04T13:30:00+07:00',
                'rejectionReason': None,
                'proofBytes': receipt_bytes,
                'proofName': f'bien-lai-{pid}-09.png',
                'proofUrl': None,
                'paymentAccountId': default_acc['id'],
            },
            [tid],
        )
        rec(
            pid,
            owner,
            'readings',
            f'101:{period_sep}',
            {'room': '101', 'period': period_sep, 'oldElectric': 942, 'newElectric': 1000, 'oldWater': 97, 'newWater': 100},
            [tid],
        )

        # Incidents in inProgress, resolved, closed.
        for s_idx, (st, title, cat, urgent) in enumerate([
            ('inProgress', 'Đèn hành lang tầng 2 nhấp nháy', 'Điện', False),
            ('resolved', 'Bảo trì khóa cửa vân tay cổng chính', 'Khác', True),
            ('closed', 'Vệ sinh định kỳ cục nóng máy lạnh', 'Điện lạnh', False),
        ]):
            inc_id = f'sample26-inc-{pid}-{st}'
            rec(
                pid,
                owner,
                'incidents',
                inc_id,
                {
                    'id': inc_id,
                    'leaseId': lid,
                    'reporterId': tid,
                    'reporter': tname,
                    'room': room,
                    'title': title,
                    'category': cat,
                    'description': f'Yêu cầu xử lý sự cố tại {pname} · Phòng {room}.',
                    'date': (now - dt.timedelta(days=s_idx + 1)).strftime('%d/%m/%Y'),
                    'urgent': urgent,
                    'status': st,
                },
                [tid],
            )

        for v_idx, (vst, rcode) in enumerate([('pending', '102'), ('confirmed', '201'), ('cancelled', '202')]):
            vid = f'sample26-view-{pid}-{vst}'
            rec(
                pid,
                owner,
                'viewings',
                vid,
                {
                    'id': vid,
                    'propertyId': pid,
                    'tenantId': tid,
                    'roomName': f'{pname} · Phòng {rcode}',
                    'address': paddr,
                    'startsAt': (now + dt.timedelta(days=v_idx + 1, hours=10)).isoformat(),
                    'customerName': tname,
                    'phone': f'090110010{p_idx + 1}',
                    'personalNeeds': 'Cần phòng yên tĩnh, có chỗ để xe và ánh sáng tự nhiên.',
                    'status': vst,
                    'attendeeCount': 2 if v_idx == 0 else 1,
                    'roomId': f'{pid}:{rcode}',
                    'createdAt': (now - dt.timedelta(days=1)).isoformat(),
                },
                [tid],
            )

        for r_idx, rcode in enumerate(['102', '201', '202']):
            done = r_idx == 0
            rec(
                pid,
                owner,
                'readings',
                f'{rcode}:{period_nov}',
                {
                    'room': rcode,
                    'period': period_nov,
                    'oldElectric': 820 + r_idx * 35,
                    'newElectric': (875 + r_idx * 40) if done else None,
                    'oldWater': 64 + r_idx * 4,
                    'newWater': (70 + r_idx * 4) if done else None,
                },
                [],
            )

        rec(
            pid,
            owner,
            'readings',
            f'101:{period_oct}',
            {'room': '101', 'period': period_oct, 'oldElectric': 1000, 'newElectric': 1060, 'oldWater': 100, 'newWater': 103},
            [tid],
        )

        conv_id = f'sample26-chat-{pid}-201'
        conv_key = f'{pid}:conversations:{conv_id}'
        rec(
            pid,
            owner,
            'conversations',
            conv_id,
            {
                'id': conv_id,
                'propertyId': pid,
                'tenantId': tid,
                'ownerUid': owner,
                'leaseId': None,
                'tenantName': tname,
                'room': '201',
                'landlordName': oname,
                'propertyName': pname,
                'messages': [],
                'unread': 1,
                'tenantUnread': 1,
                'lastRoomContext': {
                    'propertyId': pid,
                    'roomId': f'{pid}:201',
                    'roomName': f'{pname} · Phòng 201',
                    'propertyName': pname,
                    'source': 'discovery',
                },
                'roomContexts': [{
                    'propertyId': pid,
                    'roomId': f'{pid}:201',
                    'roomName': f'{pname} · Phòng 201',
                    'propertyName': pname,
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
                pid,
                owner,
                'messages',
                f'{conv_id}:msg-{m_idx}',
                {
                    'id': f'msg-{m_idx}',
                    'text': text,
                    'time': f'10:0{m_idx + 2}',
                    'fromLandlord': from_l,
                    'createdAt': (now - dt.timedelta(hours=3 - m_idx)).isoformat(),
                    'index': m_idx,
                    'conversationId': conv_id,
                    'conversationKey': conv_key,
                },
                [tid],
            )

    # Landlord staff documents (management/{ownerUid}).
    for owner_uid, staff_payload in OWNER_STAFF.items():
        add_doc(f'management/{owner_uid}', {'staff': staff_payload})

    # Admin support tickets (created by admin).
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


def build_enrichment(existing_docs, mgmt_fields, now):
    """Build non-destructive updates for existing settings/announcements/admin and role-scoped docs."""
    merged_records = {}
    for path, body in existing_docs.items():
        if path.startswith('rental_records/'):
            merged_records[path] = {k: decode_value(v) for k, v in body.get('fields', {}).items()}

    def _compute_oct_rent(pid):
        invoices = {}
        payments = []
        for path, doc in merged_records.items():
            if doc.get('propertyId') != pid or doc.get('archived'):
                continue
            if doc.get('kind') == 'invoices':
                invoices[doc['data']['id']] = doc['data']
            elif doc.get('kind') == 'payments':
                payments.append(doc['data'])
        total_rent = 0
        for p in payments:
            dt_str = p.get('reviewedAt') or p.get('paidAt') or ''
            if p.get('status') != 'approved' or not dt_str.startswith('2026-10'):
                continue
            inv = invoices.get(p.get('invoiceId'))
            if not inv or inv.get('cancelled'):
                continue
            charges = inv.get('charges') or []
            inv_total = sum(int(c.get('amount') or 0) for c in charges)
            rent = sum(
                int(c.get('amount') or 0)
                for c in charges
                if str(c.get('name', '')).strip().lower() in ('tiền phòng', 'tiền thuê phòng')
            )
            if inv_total > 0 and rent > 0:
                approved = int(p.get('approvedAmount') or 0)
                total_rent += (approved * rent + inv_total // 2) // inv_total
        return total_rent

    record_updates = {}
    # 1. Populate paymentAccounts in existing settings docs ONLY when currently empty.
    for path, doc in list(merged_records.items()):
        if doc.get('kind') != 'settings':
            continue
        pid = doc.get('propertyId', '')
        owner = doc.get('ownerUid', '')
        data = copy.deepcopy(doc.get('data') or {})
        if not data.get('paymentAccounts'):
            data['paymentAccounts'] = _payment_accounts_for(pid, owner)
            data.setdefault('counters', [10000] * 7)
            record_updates[path] = {
                **doc,
                'data': data,
            }

    # 1b. Normalize supplement verification timestamps to UTC '.000Z' so DateTime.toIso8601String() equals reviewSubmissionAt.
    for pid in ('op26-02-03',):
        v_path = f'rental_records/{pid}:verification:{pid}'
        r_path = f'rental_records/{pid}:verificationReview:{pid}'
        v_doc = merged_records.get(v_path)
        r_doc = merged_records.get(r_path)
        if v_doc and r_doc:
            v_data = copy.deepcopy(v_doc.get('data') or {})
            r_data = copy.deepcopy(r_doc.get('data') or {})
            sub_raw = v_data.get('submittedAt')
            rev_sub_raw = r_data.get('submissionAt')
            if sub_raw and rev_sub_raw and (not str(sub_raw).endswith('Z') or not str(rev_sub_raw).endswith('Z')):
                try:
                    sub_utc = utc_iso(dt.datetime.fromisoformat(str(sub_raw)))
                    v_data['submittedAt'] = sub_utc
                    r_data['submissionAt'] = sub_utc
                    if r_data.get('requestedAt'):
                        r_data['requestedAt'] = utc_iso(dt.datetime.fromisoformat(str(r_data['requestedAt'])))
                    record_updates[v_path] = {**v_doc, 'data': v_data}
                    record_updates[r_path] = {**r_doc, 'data': r_data}
                except ValueError:
                    pass

    # 1c. Enable bankTransferEnabled on active leases when disabled so VietQR renders.
    for path, l_doc in list(merged_records.items()):
        if l_doc.get('kind') != 'leases' or l_doc.get('archived'):
            continue
        l_data = copy.deepcopy(l_doc.get('data') or {})
        if l_data.get('status') == 'active' and not l_data.get('bankTransferEnabled'):
            pid = l_doc.get('propertyId', '')
            owner_uid = l_doc.get('ownerUid', '')
            default_acc = _payment_accounts_for(pid, owner_uid)[0]
            l_data['bankTransferEnabled'] = True
            if not l_data.get('bankName'):
                l_data['bankName'] = default_acc['bankName']
            if not l_data.get('bankAccountNumber'):
                l_data['bankAccountNumber'] = default_acc['accountNumber']
            record_updates[path] = {**l_doc, 'data': l_data}

    # 2. Enrich op26-01-01..03 announcements & tenantAnnouncements if fewer than 3 notices.
    for pid, _, tid, _, pname in OWNER_PROPERTY_SPECS:
        owner = [o for p, o, *_ in [(pid, f'report-demo-owner-{pid[-1]}')]][0]
        extra_bundle = _announcements_bundle(pid, pname, tid, now)
        for kind, key, readers in [
            ('announcements', pid, []),
            ('tenantAnnouncements', tid, [tid]),
        ]:
            path = f'rental_records/{pid}:{kind}:{key}'
            doc = merged_records.get(path)
            if not doc:
                continue
            data = copy.deepcopy(doc.get('data') or {})
            sent = list(data.get('sent') or [])
            existing_ids = {n.get('id') for n in sent}
            if len(sent) < 3:
                recipients = dict(data.get('recipients') or {})
                read_by_tenant = dict(data.get('readByTenant') or {})
                landlord_read = list(data.get('landlordRead') or [])
                added = False
                for notice in extra_bundle['sent'][:2]:
                    nid = notice['id']
                    if nid not in existing_ids:
                        sent.append(notice)
                        recipients[nid] = [tid]
                        existing_ids.add(nid)
                        added = True
                if added:
                    data['sent'] = sent
                    data['recipients'] = recipients
                    data['readByTenant'] = read_by_tenant
                    data['landlordRead'] = landlord_read
                    record_updates[path] = {
                        **doc,
                        'tenantIds': doc.get('tenantIds', readers),
                        'data': data,
                    }

    # 3. Admin enrichment (logs, commissionRates, commissionStatements) ONLY if empty/missing.
    admin_obj = copy.deepcopy((mgmt_fields or {}).get('admin', {}))
    admin_updates = {}
    if not admin_obj.get('logs'):
        log_entries = [
            ('Ghi nhận Chủ trọ Nguyễn Quốc Bảo gửi lại hồ sơ xác minh nhà trọ Lộc Vừng Homestay (op26-02-10)', 2, 'Chủ trọ'),
            ('Duyệt nâng cấp gói Plus (99.000 đ) cho Nguyễn Thanh Bình qua thanh toán giả lập', 4, 'Hệ thống'),
            ('Đối soát chứng từ thanh toán thuê phòng kỳ 11/2026 trên 13 nhà trọ', 6, 'Quản trị viên'),
            ('Phản hồi và đóng yêu cầu hỗ trợ sample26-tk-3 về đồng bộ hóa đơn TroPremium', 9, 'Quản trị viên'),
            ('Cập nhật yêu cầu bổ sung ảnh CCCD & sổ hồng cho Gác Gỗ Thảo Điền (op26-02-03)', 14, 'Quản trị viên'),
            ('Xác minh nhà trọ Bình Yên Studio (op26-02-08) · Chủ trọ Nguyễn Thanh Bình', 18, 'Quản trị viên'),
            ('Xác minh nhà trọ Phố Nắng Thủ Dầu Một (op26-02-07) · Chủ trọ Nguyễn Thanh Bình', 20, 'Quản trị viên'),
            ('Xác minh nhà trọ Biển Xanh Sơn Trà (op26-02-04) · Chủ trọ Nguyễn Quốc Bảo', 22, 'Quản trị viên'),
            ('Xác minh nhà trọ Sài Gòn Corner Bình Thạnh (op26-02-01) · Chủ trọ Nguyễn Minh Anh', 25, 'Quản trị viên'),
            ('Cấu hình tài khoản nhận thanh toán gói dịch vụ Vietcombank trên hệ thống', 30, 'Quản trị viên'),
            ('Chốt đối soát hoa hồng kỳ 10/2026 cho Nhà trọ Bình Minh và An Nhiên House', 36, 'Quản trị viên'),
            ('Xác minh nhà trọ Mộc Lan Residence (op26-01-03)', 48, 'Quản trị viên'),
            ('Xác minh nhà trọ An Nhiên House (op26-01-02)', 50, 'Quản trị viên'),
            ('Xác minh nhà trọ Nhà trọ Bình Minh (op26-01-01)', 52, 'Quản trị viên'),
            ('Bật tiếp nhận lịch xem phòng trên mục Khám phá', 60, 'Quản trị viên'),
            ('Khởi tạo danh mục 13 nhà trọ vận hành đa tỉnh thành trên Cloud Firestore', 72, 'Hệ thống'),
        ]
        admin_updates['logs'] = [
            {
                'action': action,
                'at': (now - dt.timedelta(hours=hours)).isoformat(),
                'actor': actor,
            }
            for action, hours, actor in log_entries
        ]

    if not admin_obj.get('commissionRates'):
        admin_updates['commissionRates'] = {
            'op26-01-01': 300,
            'op26-01-02': 350,
            'op26-01-03': 350,
            'op26-02-01': 400,
            'op26-02-04': 400,
            'op26-02-07': 300,
            'op26-02-08': 450,
        }

    if not admin_obj.get('commissionStatements'):
        rates = admin_obj.get('commissionRates') or admin_updates.get('commissionRates', {})
        statements = []
        created_iso = (now - dt.timedelta(days=2)).isoformat()
        for idx, (pid, _, _, _, pname) in enumerate(OWNER_PROPERTY_SPECS):
            rent = _compute_oct_rent(pid) or (3000000 + idx * 300000)
            rate = int(rates.get(pid, 300))
            due = (rent * rate + 5000) // 10000
            receipts = []
            if idx == 0 and due > 0:
                receipts.append({
                    'amount': due,
                    'reference': 'HH-2026-10-OP01',
                    'at': (now - dt.timedelta(days=1)).isoformat(),
                })
            elif idx == 1 and due > 1000:
                receipts.append({
                    'amount': due // 2,
                    'reference': 'HH-2026-10-OP02',
                    'at': (now - dt.timedelta(days=1)).isoformat(),
                })
            statements.append({
                'propertyId': pid,
                'propertyName': pname,
                'month': '2026-10-01T00:00:00.000',
                'rentCollected': rent,
                'rateBasisPoints': rate,
                'createdAt': created_iso,
                'receipts': receipts,
            })
        admin_updates['commissionStatements'] = statements

    # 4. Per-role support tickets (must be created by the owning role user, optionally replied by admin).
    role_tickets = [
        {
            'id': 'sample26-tk-l1',
            'accountKey': 'owner1',
            'accountUid': 'report-demo-owner-1',
            'role': 'landlord',
            'title': 'Kiểm tra kích hoạt gói dịch vụ và hạn mức phòng',
            'content': 'Tôi vừa gửi giao dịch đăng ký nâng cấp gói quản lý cho 4 nhà trọ, nhờ quản trị viên đối soát giúp.',
            'createdAt': (now - dt.timedelta(days=2)).isoformat(),
            'reply': 'Đã đối soát giao dịch gói Go và mở giới hạn quản lý đa nhà trọ cho tài khoản Chủ trọ 1.',
            'closed': True,
        },
        {
            'id': 'sample26-tk-l2',
            'accountKey': 'owner1',
            'accountUid': 'report-demo-owner-1',
            'role': 'landlord',
            'title': 'Nhờ rà soát lại hồ sơ Nhà trọ Ánh Dương (op26-02-02)',
            'content': 'Mình đã tải lên đủ ảnh chân dung, 2 mặt CCCD và giấy tờ chủ quyền, nhờ admin xét duyệt.',
            'createdAt': (now - dt.timedelta(hours=6)).isoformat(),
            'reply': '',
            'closed': False,
        },
        {
            'id': 'sample26-tk-l3',
            'accountKey': 'owner2',
            'accountUid': 'report-demo-owner-2',
            'role': 'landlord',
            'title': 'Xác nhận hồ sơ bổ sung Lộc Vừng Homestay',
            'content': 'Tôi đã cập nhật ảnh mặt tiền mới cho Lộc Vừng Homestay, nhờ quản trị viên duyệt lại.',
            'createdAt': (now - dt.timedelta(hours=3)).isoformat(),
            'reply': '',
            'closed': False,
        },
        {
            'id': 'sample26-tk-t1',
            'accountKey': 'tenant1',
            'accountUid': 'report-demo-tenant-1',
            'role': 'tenant',
            'title': 'Tải biên lai xác nhận thanh toán chuyển khoản tháng 9',
            'content': 'Em đã thanh toán qua ngân hàng cho phòng 101 Nhà trọ Bình Minh và cần kiểm tra trạng thái biên lai.',
            'createdAt': (now - dt.timedelta(days=3)).isoformat(),
            'reply': 'Khoản thu đã được chủ trọ duyệt và lưu biên lai trên mục Lịch sử thanh toán.',
            'closed': True,
        },
        {
            'id': 'sample26-tk-t2',
            'accountKey': 'tenant1',
            'accountUid': 'report-demo-tenant-1',
            'role': 'tenant',
            'title': 'Hỏi về thời gian xác nhận yêu cầu người ở ghép mới',
            'content': 'Em vừa gửi hồ sơ thêm bạn Trần Minh Quân vào phòng 101, nhờ hỗ trợ theo dõi tiến trình duyệt.',
            'createdAt': (now - dt.timedelta(hours=4)).isoformat(),
            'reply': 'Đã chuyển thông báo tới chủ trọ Nhà trọ Bình Minh; dự kiến phản hồi trong ngày.',
            'closed': False,
        },
        {
            'id': 'sample26-tk-t3',
            'accountKey': 'tenant2',
            'accountUid': 'report-demo-tenant-2',
            'role': 'tenant',
            'title': 'Đổi khung giờ hẹn xem phòng tại Biển Xanh Sơn Trà',
            'content': 'Em đã đặt lịch xem phòng 201 và muốn xác nhận giờ hẹn với chủ trọ trước khi di chuyển.',
            'createdAt': (now - dt.timedelta(hours=5)).isoformat(),
            'reply': '',
            'closed': False,
        },
    ]

    # 5. Tenant Favorites in user_state/{uid} so Khám phá -> Đã lưu is pre-populated.
    tenant_favorites = {
        'tenant1': {
            'uid': 'report-demo-tenant-1',
            'favorites': {'ids': ['op26-02-01:201', 'op26-02-04:201', 'op26-01-01:102']},
            'accounts': {'contacts': {}, 'notifications': {}},
        },
        'tenant2': {
            'uid': 'report-demo-tenant-2',
            'favorites': {'ids': ['op26-02-04:102', 'op26-02-08:201', 'op26-01-02:201']},
            'accounts': {'contacts': {}, 'notifications': {}},
        },
        'tenant3': {
            'uid': 'report-demo-tenant-3',
            'favorites': {'ids': ['op26-02-07:201', 'op26-02-09:102', 'op26-01-03:201']},
            'accounts': {'contacts': {}, 'notifications': {}},
        },
    }

    return {
        'record_updates': record_updates,
        'admin_updates': admin_updates,
        'role_tickets': role_tickets,
        'tenant_favorites': tenant_favorites,
    }


def _call_subscription_api(id_token, action, payload=None):
    return http_json(
        SUPABASE_SUBSCRIPTION_URL,
        {'action': action, **(payload or {})},
        token=id_token,
        headers={'apikey': SUPABASE_PUBLISHABLE_KEY},
    )


def sync_demo_subscriptions(admin_token, demo_password):
    """Populate realistic Supabase subscription_orders cleanly through subscription-api."""
    current = _call_subscription_api(admin_token, 'listOrders').get('orders', [])
    by_uid = {}
    for o in current:
        by_uid.setdefault(o['landlordUid'], []).append(o)

    actions_taken = []

    def token_for(key):
        _, email = DEMO_ACCOUNTS[key]
        tok, uid = sign_in_account(email, demo_password)
        return tok, uid

    # 1. Landlord 2: move existing awaiting_payment Plus order -> submitted for Admin queue.
    tok2, uid2 = token_for('owner2')
    open2 = [o for o in by_uid.get(uid2, []) if o['status'] in ('awaiting_payment', 'submitted')]
    awaiting2 = [o for o in open2 if o['status'] == 'awaiting_payment']
    if awaiting2:
        _call_subscription_api(
            tok2,
            'submitPayment',
            {
                'orderId': awaiting2[0]['id'],
                'paymentNote': 'Đã chuyển khoản MB Bank FT2633099123 nâng cấp gói Plus',
            },
        )
        actions_taken.append('owner2:submitPayment')
    elif not open2:
        created = _call_subscription_api(tok2, 'createOrder', {'planId': 'plus'})['order']
        _call_subscription_api(
            tok2,
            'submitPayment',
            {
                'orderId': created['id'],
                'paymentNote': 'Đã chuyển khoản MB Bank FT2633099123 nâng cấp gói Plus',
            },
        )
        actions_taken.append('owner2:create+submitPlus')

    # 2. Landlord 3: approve 1 Plus package via simulated flow (diversifies plan stats) + leave 1 awaiting_payment Ultra.
    tok3, uid3 = token_for('owner3')
    orders3 = by_uid.get(uid3, [])
    has_approved_plus = any(o['status'] == 'approved' and o['planId'] == 'plus' for o in orders3)
    open3 = [o for o in orders3 if o['status'] in ('awaiting_payment', 'submitted')]
    if not has_approved_plus and not open3:
        sim = _call_subscription_api(tok3, 'prepareSimulatedPayment', {'planId': 'plus'})['order']
        _call_subscription_api(tok3, 'simulatePayment', {'orderId': sim['id']})
        actions_taken.append('owner3:simulatePlusApproved')
        _call_subscription_api(tok3, 'createOrder', {'planId': 'ultra'})
        actions_taken.append('owner3:createUltraAwaiting')
    elif not open3:
        _call_subscription_api(tok3, 'createOrder', {'planId': 'ultra'})
        actions_taken.append('owner3:createUltraAwaiting')

    # 3. Landlord 1: create + submit Ultra order so Admin has 2 submitted orders to review.
    tok1, uid1 = token_for('owner1')
    open1 = [o for o in by_uid.get(uid1, []) if o['status'] in ('awaiting_payment', 'submitted')]
    if not open1:
        created1 = _call_subscription_api(tok1, 'createOrder', {'planId': 'ultra'})['order']
        _call_subscription_api(
            tok1,
            'submitPayment',
            {
                'orderId': created1['id'],
                'paymentNote': 'Đã chuyển khoản Vietcombank VCB261188342 đăng ký gói Ultra',
            },
        )
        actions_taken.append('owner1:create+submitUltra')

    return actions_taken


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--admin-email', default='demo-admin@example.com')
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()

    password = os.environ.get('FIREBASE_ADMIN_PASSWORD') or getpass.getpass('Firebase demo password (hidden): ')
    token, admin_uid = sign_in_admin(args.admin_email, password=password)
    existing = {}
    for col in ('rental_properties', 'public_rooms', 'rental_records', 'support_tickets', 'management'):
        existing.update(list_collection(col, token))

    mgmt_path = 'management/system'
    mgmt_live = existing.get(mgmt_path) or http_json(f'{BASE}/{mgmt_path}', token=token)
    mgmt_fields = {k: decode_value(v) for k, v in mgmt_live.get('fields', {}).items()}

    now = dt.datetime.now(dt.timezone(dt.timedelta(hours=7))).replace(microsecond=0)
    additions, new_verified, new_proofs = build_additions(existing, now, admin_uid=admin_uid)
    enrichment = build_enrichment(existing, mgmt_fields, now)

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
    for key, val in enrichment['admin_updates'].items():
        admin_obj[key] = val
        mgmt_changed = True

    new_role_tickets = [t for t in enrichment['role_tickets'] if f"support_tickets/{t['id']}" not in existing]
    print(json.dumps({
        'existingDocsChecked': len(existing),
        'newDocuments': len(additions),
        'newProperties': sum(1 for p in additions if p.startswith('rental_properties/')),
        'newPublicRooms': sum(1 for p in additions if p.startswith('public_rooms/')),
        'newRecords': sum(1 for p in additions if p.startswith('rental_records/')),
        'newStaffDocs': sum(1 for p in additions if p.startswith('management/report-demo-owner-')),
        'newSupportTicketsAdmin': sum(1 for p in additions if p.startswith('support_tickets/')),
        'newSupportTicketsRoles': len(new_role_tickets),
        'recordUpdates': len(enrichment['record_updates']),
        'adminUpdateKeys': sorted(enrichment['admin_updates'].keys()),
        'tenantFavoriteTargets': len(enrichment['tenant_favorites']),
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
    for path, updated_data in sorted(enrichment['record_updates'].items()):
        live_doc = existing.get(path)
        if not live_doc:
            continue
        writes.append({
            'update': {
                'name': f'{doc_prefix}/{path}',
                'fields': {k: wire_value(v) for k, v in updated_data.items()},
            },
            'currentDocument': {'updateTime': live_doc['updateTime']},
        })
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

    # Sign in per demo role ONLY for user-owned collections (support_tickets create, user_state/{uid}).
    user_tokens = {}
    for role_key in {t['accountKey'] for t in new_role_tickets} | set(enrichment['tenant_favorites'].keys()):
        _, email = DEMO_ACCOUNTS[role_key]
        user_tokens[role_key] = sign_in_account(email, password)[0]

    for ticket in new_role_tickets:
        t_token = user_tokens[ticket['accountKey']]
        t_path = f"support_tickets/{ticket['id']}"
        http_json(
            f'{BASE}:commit',
            {
                'writes': [{
                    'update': {
                        'name': f'{doc_prefix}/{t_path}',
                        'fields': {
                            'accountUid': wire_value(ticket['accountUid']),
                            'importBatch': wire_value(BATCH_TAG),
                            'data': wire_value({
                                'id': ticket['id'],
                                'role': ticket['role'],
                                'title': ticket['title'],
                                'content': ticket['content'],
                                'createdAt': ticket['createdAt'],
                                'reply': '',
                                'closed': False,
                            }),
                        },
                    },
                    'currentDocument': {'exists': False},
                }],
            },
            token=t_token,
        )
        if ticket['reply'] or ticket['closed']:
            http_json(
                f'{BASE}:commit',
                {
                    'writes': [{
                        'update': {
                            'name': f'{doc_prefix}/{t_path}',
                            'fields': {'data': wire_value({'reply': ticket['reply'], 'closed': ticket['closed']})},
                        },
                        'updateMask': {'fieldPaths': ['data.reply', 'data.closed']},
                    }],
                },
                token=token,
            )
    if new_role_tickets:
        print(f'Published {len(new_role_tickets)} landlord/tenant support tickets')

    # Populate user_state/{uid} favorites if currently missing or empty.
    fav_applied = 0
    for role_key, fav_payload in enrichment['tenant_favorites'].items():
        u_token = user_tokens[role_key]
        u_path = f"user_state/{fav_payload['uid']}"
        try:
            u_doc = http_json(f'{BASE}/{u_path}', token=u_token)
            u_fields = {k: decode_value(v) for k, v in u_doc.get('fields', {}).items()}
        except urllib.error.HTTPError as exc:
            if exc.code != 404:
                raise
            u_doc = None
            u_fields = {}
        existing_ids = list((u_fields.get('favorites') or {}).get('ids') or [])
        if existing_ids:
            continue
        merged_state = {
            'accounts': u_fields.get('accounts') or fav_payload['accounts'],
            'favorites': fav_payload['favorites'],
        }
        write_op = {
            'update': {
                'name': f'{doc_prefix}/{u_path}',
                'fields': {k: wire_value(v) for k, v in merged_state.items()},
            },
            'currentDocument': {'updateTime': u_doc['updateTime']} if u_doc else {'exists': False},
        }
        http_json(f'{BASE}:commit', {'writes': [write_op]}, token=u_token)
        fav_applied += 1
    print(f'Updated tenant favorites docs: {fav_applied}')

    sub_actions = sync_demo_subscriptions(token, password)
    print(f'Supabase subscription actions: {json.dumps(sub_actions)}')
    print('SEED_ADDITIONAL_SAMPLES_APPLIED')


if __name__ == '__main__':
    main()
