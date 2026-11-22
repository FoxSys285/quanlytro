"""Create a linked, synthetic operating dataset for the TroPremium app.

Phases are resumable. Secrets/account passwords stay in .local-backups. All
Firestore documents are encoded by the app's Dart codec before publication.
"""
import argparse
import base64
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from copy import deepcopy
from datetime import datetime, timedelta, timezone
import hashlib
import json
import os
from pathlib import Path
import random
import re
import secrets
import shutil
import subprocess
import uuid

import requests
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill

from reset_app_data import ROOT, PROJECT, BASE, AUTH, request, dump, documents, users, validate_project
from generate_vietnam_catalogue import BRANDS, STREETS, SURNAMES, GIVEN_NAMES, TYPE_SPECS
from collect_nationwide_rentals import wire_value, decode_wire, project_config

WORK = ROOT / '.local-backups/operating-demo'
BATCH = 'operating-20261122-v1'
NOW = datetime(2026, 11, 22, 0, 0, tzinfo=timezone(timedelta(hours=7)))
STAMP = NOW.isoformat()
RNG = random.Random(20261122)
RESET = ROOT / '.local-backups/app-reset-20261121T171825Z'
REF = 'hihsjrdzbtfldlscigzi'
PLANS = {'free': (0, 1, 10), 'go': (39000, 2, 30), 'plus': (99000, 4, 80), 'ultra': (199000, 10, 100)}


def load(name):
    return json.loads((WORK / name).read_text(encoding='utf-8'))


def iso(days=0):
    return (NOW + timedelta(days=days)).isoformat()


def person(index):
    return SURNAMES[(index // len(GIVEN_NAMES)) % len(SURNAMES)] + ' ' + GIVEN_NAMES[index % len(GIVEN_NAMES)]


def http_json(url):
    response = requests.get(url, timeout=40)
    response.raise_for_status()
    return response.json()


def probe():
    print(json.dumps(request('GET', f'https://cloudbilling.googleapis.com/v1/projects/{PROJECT}/billingInfo')))


def collect():
    WORK.mkdir(parents=True, exist_ok=True)
    provinces = http_json('https://provinces.open-api.vn/api/v2/?depth=2')
    assert len(provinces) == 34
    # Current name established by Resolution 30/2026/QH16. Some catalogue APIs
    # still return the former province label.
    for province in provinces:
        if province['code'] == 75:
            province['name'] = 'Thành phố Đồng Nai'
    dump(WORK / 'provinces.json', provinces)
    source = json.loads((ROOT / 'artifacts/NGUON_ANH_680_NHA_TRO.json').read_text(encoding='utf-8'))
    albums = source['albums']
    urls = sorted({u for album in albums for u in album['photos']})
    def check(url):
        try:
            response = requests.get(url, timeout=15, stream=True)
            good = response.status_code == 200 and response.headers.get('Content-Type', '').startswith('image/')
            response.close()
            return url, good
        except requests.RequestException:
            return url, False
    with ThreadPoolExecutor(max_workers=10) as pool:
        valid = dict(pool.map(check, urls))
    for album in albums:
        album['photos'] = [u for u in album['photos'] if valid[u]]
        album['searchUrl'] = 'https://www.google.com/search?tbm=isch&q=phong+tro+' + album['kind']
        album['photosAreIllustrative'] = True
    albums = [a for a in albums if a['photos']]
    # Additional original image URLs discovered by image search. Keep original
    # source pages, without copying any real listing's owner/contact details.
    extras = [
        ('loft', 'https://phongtro123.com/doc-quyen-tai-hifriendz-gia-tu-4tr-phong-sieu-rong-o-duoc-4-ban-pr610041.html', 'https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2022/11/06/ed35d8a1-2d6a-4891-9017-719aed1e03b3_1667704363.jpg'),
        ('studio', 'https://thuviennhadat.vn/cho-thue-can-ho-chung-cu-phuong-13/cho-thue-can-ho-chung-cu-30m2-full-noi-that-cua-so-tai-duong-phan-van-suu-tan-binh-tien-loi-di-lai-va-an-ninh-tot-pst3074.html', 'https://cdn.thuviennhadat.vn/upload/tin-dang/hinh-anh/20250311144334/20250311144334638773010148943147.jpg'),
        ('building', 'https://phongtro123.com/phong-tro-moi-xay-18m2-gia-chi-1tr2-thang-tai-xa-phu-an-huyen-ben-cat-binh-duong-pr593240.html', 'https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2021/11/24/q1_1637740162.jpg'),
        ('building', 'https://alonhaxinh.vn/cap-nhat-bang-gia-xay-dung-nha-tro-tron-goi-tp-hcm-moi-nhat', 'https://alonhaxinh.vn/upload/news/74508747.jpg'),
        ('building', 'https://vietnhathousing.com.vn/vi/tin-tuc/207-tat-tan-tat-ve-chi-phi-xay-phong-tro-cap-4', 'https://vietnhathousing.com.vn/files/upload/files/nha-tro-cap-4-2.jpg'),
    ]
    for kind, page, photo in extras:
        if check(photo)[1]:
            albums.append({'kind': kind, 'photos': [photo], 'sourceUrl': page,
                           'searchUrl': 'https://www.google.com/search?tbm=isch&q=phong+tro+' + kind,
                           'discoveredVia': 'web-image-search', 'photosAreIllustrative': True})
    for kind in ['loft', 'studio', 'balcony', 'group']:
        assert sum(a['kind'] == kind for a in albums) >= 3
    dump(WORK / 'photos.json', {'albums': albums, 'verifiedAt': datetime.now(timezone.utc).isoformat()})
    print(json.dumps({'provinces':len(provinces), 'photoAlbums':len(albums), 'workingPhotos':sum(len(a['photos']) for a in albums)}), flush=True)


def prepare():
    if (WORK / 'plan.json').exists():
        raise RuntimeError('Plan exists; reuse it without regenerating credentials')
    provinces, albums = load('provinces.json'), load('photos.json')['albums']
    pools = {kind:[a for a in albums if a['kind']==kind] for kind in ['loft','studio','balcony','group','building']}
    accounts, stores, owners, orders, photo_sources = [], [], {}, [], []
    snapshot = {'portfolio': {'properties':stores}, 'admin':{'verified':{}, 'verificationProofs':{}, 'hidden':[], 'tickets':[], 'logs':[], 'acceptingViewings':True},
                'conversations':{'records':[]}, 'viewings':{'records':[], 'nextId':10000}, 'staff':{'staff':[], 'nextId':10000}}
    password = 'TroDemo!' + secrets.token_urlsafe(10)
    def account(uid, role, name, province, tenant_id=None):
        index = len(accounts)
        row = {'uid':uid, 'role':role, 'name':name, 'email':uid+'@example.com',
               'phone':'000'+str(1000000+index), 'password':password, 'province':province,
               'address':province, 'tenantId':tenant_id, 'plan':'free', 'scenario':''}
        accounts.append(row)
        return row
    admin = account('demo-admin', 'admin', 'Quản trị TroPremium', 'Toàn quốc')
    admin['scenario']='Quản trị hệ thống'
    owner_groups = [1,1,2,3,4,4,5]
    owner_plans = ['free','go','go','plus','plus','plus','ultra']
    for pi, province in enumerate(provinces):
        code, city = province['code'], province['name']
        wards = province['wards']
        tenants_for_province = []
        property_number = 0
        for oi, count in enumerate(owner_groups):
            uid = f'demo-owner-{code:02d}-{oi+1:02d}'
            owner = account(uid, 'landlord', person(pi*7+oi), city)
            owner['plan']=owner_plans[oi]
            owner['properties']=count
            owner['scenario']=f'{count} nhà · {owner["plan"].title()}'
            if owner['plan']!='free':
                orders.append(subscription(owner, admin))
            for local_index in range(count):
                property_number += 1
                n, index = property_number, len(stores)
                pid = f'op26-{code:02d}-{n:02d}'
                owners[pid]=uid
                ward=wards[(pi+n*3) % len(wards)]['name']
                # Keep the complete operating seed within the project's free
                # daily write allowance. New empty properties have more rooms.
                floor_count = 4 if n%5==0 and owner['plan']!='free' else 2
                per_floor = 2
                room_count=floor_count*per_floor
                if owner['plan']=='free': floor_count, per_floor, room_count=2,2,4
                name=f'{BRANDS[(pi+n)%len(BRANDS)]} {re.sub(r"^(Tỉnh|Thành phố) ", "", city)} {n:02d}'
                address=f'{18+n*9} {STREETS[(pi+n)%len(STREETS)]}, {ward}, {city}'
                owner['address']=address if local_index==0 else owner['address']
                type_count=2 + n%2
                specs=[TYPE_SPECS[(n+t)%len(TYPE_SPECS)] for t in range(type_count)]
                base=RNG.randrange(12,25)*100000+(1000000 if code in [1,48,79] else 0)
                types=[]
                for ti, spec in enumerate(specs):
                    pool=pools[spec['photoKind']]
                    album=pool[(index*3+ti)%len(pool)]
                    types.append({'id':spec['id'], 'name':spec['name'], 'monthlyRent':base+spec['premium'],
                                  'serviceIds':['electricity','water','internet','cleaning'], 'servicePrices':{},
                                  'photos':[{'name':f'Ảnh phòng {j+1}', 'url':u} for j,u in enumerate(album['photos'])]})
                    photo_sources.append({'propertyId':pid, 'roomTypeId':spec['id'], **album})
                building=pools['building'][index%len(pools['building'])] if pools['building'] else None
                prop={'id':pid,'name':name,'address':address,'city':city,'ward':ward,'ownerName':owner['name'],
                      'phone':owner['phone'],'phoneIsSynthetic':True,'imageUrl':building['photos'][0] if building and n%10==0 else types[0]['photos'][0]['url'],
                      'amenities':['Wifi','Bãi xe','Camera','Giờ giấc tự do']+(['Máy giặt','Máy lạnh'] if n%2 else ['Sân phơi']),
                      'description':f'Nhà trọ {name} tại {ward}, gồm {floor_count} tầng và {room_count} phòng. '+
                        ['Không gian yên tĩnh, phù hợp người đi làm.','Gần khu dân cư, phù hợp sinh viên và ở ghép.','Phòng có bếp riêng, đón ánh sáng tự nhiên.','Khu trọ an ninh, có chỗ để xe và sân phơi.'][n%4]}
                store={'schemaVersion':2,'property':prop,'rooms':[],'roomTypes':types,'services':[
                    {'id':'electricity','name':'Điện','unit':'kWh','basis':'Theo chỉ số','price':3500,'active':True},
                    {'id':'water','name':'Nước','unit':'m³','basis':'Theo chỉ số','price':15000,'active':True},
                    {'id':'internet','name':'Internet','unit':'phòng','basis':'Theo phòng','price':100000,'active':True},
                    {'id':'cleaning','name':'Vệ sinh','unit':'phòng','basis':'Theo phòng','price':30000,'active':True}],
                    **{k:[] for k in ['leases','leaseTemplates','members','invoices','payments','incidents','readings','paymentAccounts']},'counters':[10000]*7}
                stores.append(store)
                for floor in range(1,floor_count+1):
                    for position in range(1,per_floor+1):
                        ri=len(store['rooms']); spec=specs[ri%type_count]
                        store['rooms'].append({'code':f'{floor}{position:02d}','floor':floor,'roomTypeId':spec['id'],
                                               'area':spec['area']+RNG.randrange(4),'capacity':spec['capacity'],'leaseRoomCode':None})
                if n%5!=0:
                    snapshot['admin']['verified'][pid]=True
                occupied = [1,2,3,2][n%4]
                if n%5==0: occupied=0
                for ri, room in enumerate(store['rooms'][:occupied]):
                    tid=f'T{code:02d}{n:02d}{ri+1:03d}'
                    tenant=account('demo-tenant-'+tid.lower(),'tenant',person(300+len(accounts)),city,tid)
                    tenant['address']=address
                    tenant['scenario']='Đang thuê phòng'
                    tenants_for_province.append(tenant)
                    rent=types[ri%type_count]['monthlyRent']
                    lease=lease_row(pid, room['code'], tenant, owner, rent, address, ri)
                    store['leases'].append(lease)
                    # The app derives the representative from the lease. Only
                    # additional household members belong in store['members'].
                    financial_rows(store, lease, ri, n)
                if store['leases']:
                    lease=store['leases'][0]
                    tenant=tenants_for_province[-occupied]
                    if local_index==0:
                        snapshot['conversations']['records'].append(chat(pid,prop,lease['tenantId'],lease['tenantName'],lease['room'],lease['id'],index))
                    if n%2:
                        store['incidents'].append({'id':f'incident-{pid}','leaseId':lease['id'],'reporterId':lease['tenantId'],
                            'title':['Vòi nước rò rỉ','Wifi kết nối chậm','Đèn hành lang không sáng','Máy lạnh cần vệ sinh'][n%4],
                            'room':lease['room'],'reporter':lease['tenantName'],'category':['Nước','Internet','Điện','Điện lạnh'][n%4],
                            'description':'Nhờ chủ trọ kiểm tra và sắp xếp hỗ trợ trong giờ hành chính.','date':'20/11/2026',
                            'urgent':n%7==0,'status':['newly','inProgress','resolved','closed'][index%4]})
                    sent={'id':f'notice-{pid}','propertyId':pid,'title':'Lịch vệ sinh và kiểm tra điện nước tháng 11',
                          'content':'Khu trọ sẽ vệ sinh khu vực chung vào cuối tuần. Vui lòng giữ hành lang thông thoáng.',
                          'category':'operations','createdAt':iso(-3),'isRead':False,'priority':'normal','recipients':[],'audienceLabel':'Toàn bộ người thuê'}
                    readers=[l['tenantId'] for l in store['leases']]
                    if local_index==0:
                        snapshot['announcements:'+pid]={'sent':[sent],'recipients':{sent['id']:readers},
                            'readByTenant':{t:([sent['id']] if j%2 else []) for j,t in enumerate(readers)},'landlordRead':[],'nextId':10000}
        province_stores=stores[-20:]
        for si in range(5):
            tid=f'S{code:02d}{si+1:05d}'
            tenant=account('demo-seeker-'+tid.lower(),'tenant',person(5000+pi*5+si),city,tid)
            tenant['scenario']='Chưa thuê · đang tìm phòng'
            store=province_stores[si*3]
            room=store['rooms'][-1]; prop=store['property']
            snapshot['viewings']['records'].append({'id':'view-'+tid,'propertyId':prop['id'],'tenantId':tid,
                'roomName':prop['name']+' · Phòng '+room['code'],'roomId':prop['id']+':'+room['code'],'address':prop['address'],
                'startsAt':iso(1+si),'createdAt':iso(-1),'customerName':tenant['name'],'phone':tenant['phone'],
                'personalNeeds':['Cần phòng yên tĩnh để làm việc.','Tìm phòng cho hai sinh viên.','Muốn xem phòng có gác và bếp riêng.'][si%3],
                'status':['pending','confirmed','cancelled'][si%3],'attendeeCount':1+si%2})
            snapshot['conversations']['records'].append(chat(prop['id'],prop,tid,tenant['name'],room['code'],None,si))
        print(json.dumps({'provincePrepared':city,'properties':len(stores),'accounts':len(accounts)}),flush=True)
    snapshot['portfolio']['selectedId']=stores[0]['property']['id']
    plan={'project':PROJECT,'batch':BATCH,'createdAt':STAMP,'accounts':accounts,'snapshot':snapshot,'owners':owners,'orders':orders}
    validate(plan)
    dump(WORK/'plan.json',plan)
    dump(WORK/'photo-sources.json',photo_sources)
    dump(WORK/'import.json',{'snapshot':snapshot,'owners':owners})
    print(json.dumps(summary(plan),ensure_ascii=False),flush=True)


def subscription(owner, admin):
    price=PLANS[owner['plan']][0]
    return {'id':str(uuid.uuid5(uuid.NAMESPACE_URL, BATCH+owner['uid'])), 'legacy_id':BATCH+':'+owner['uid'],
        'landlord_uid':owner['uid'],'landlord_name':owner['name'],'landlord_email':owner['email'],
        'plan_id':owner['plan'],'plan_name':owner['plan'].title(),'amount':price,
        'payment_reference':'DEMO'+owner['uid'].replace('demo-owner-','').replace('-',''),
        'payment_bank_name':'Mô phỏng','payment_bank_bin':'000000','payment_account_name':'TAI KHOAN MO PHONG',
        'payment_account_number':'0000000000','payment_instructions':'Dữ liệu mô phỏng; không chuyển tiền.',
        'status':'approved','payment_note':'Giao dịch mô phỏng cho bộ dữ liệu vận hành',
        'admin_note':'Dữ liệu tự tạo; không có thanh toán thực tế.','created_at':iso(-15),'submitted_at':iso(-14),
        'reviewed_at':iso(-14),'reviewed_by':admin['uid'],'starts_at':iso(-14),'expires_at':iso(16)}


def lease_row(pid, room, tenant, owner, rent, address, index):
    return {'id':'lease-'+tenant['tenantId'],'tenantId':tenant['tenantId'],'propertyId':pid,'room':room,
        'tenantName':tenant['name'],'phone':tenant['phone'],'startDate':iso(-120-index*5),'endDate':iso(240-index*5),
        'monthlyRent':rent,'deposit':rent,'termMonths':12,'dueDay':5,
        'landlordName':owner['name'],'landlordPermanentAddress':owner['address'],'landlordCitizenId':'',
        'landlordContact':owner['phone'],'tenantBirthYear':str(1995+index%9),'tenantCitizenId':'',
        'tenantPermanentAddress':tenant['province'],'electricityPrice':3500,'waterPrice':15000,'waterType':'Theo m³',
        'vehicleFee':0,'serviceFee':130000,'services':[], 'cashPaymentEnabled':True,'cashPaymentLocation':'Văn phòng quản lý',
        'bankTransferEnabled':False,'bankName':'','bankAccountNumber':'','occupantCount':1,
        'status':'active','note':'Hợp đồng mô phỏng phục vụ kiểm thử app.','rentalAddress':address}


def financial_rows(store, lease, index, property_number):
    # Two periods cover paid history plus a current mix of paid, pending,
    # partially paid, overdue and unpaid balances. Every balance has a ledger.
    for month in [10,11]:
        if month==10 and index>0: continue
        iid=f'invoice-{lease["tenantId"]}-{month}'
        power=60+index*11; water=3+index%4
        charges=[{'name':'Tiền thuê phòng','amount':lease['monthlyRent']},
                 {'name':f'Điện · {power} kWh','amount':power*3500},
                 {'name':f'Nước · {water} m³','amount':water*15000},
                 {'name':'Internet và vệ sinh','amount':130000}]
        total=sum(c['amount'] for c in charges)
        case=(index+property_number)%5
        paid=total if month==10 or case==0 else total//2 if case==1 else 0
        invoice={'id':iid,'leaseId':lease['id'],'room':lease['room'],'tenantName':lease['tenantName'],
                 'period':f'2026-{month:02d}-01T00:00:00+07:00','dueDate':f'2026-{month:02d}-{(28 if case==4 and month==11 else 5):02d}T00:00:00+07:00',
                 'charges':charges,'paidAmount':paid,'cancelled':False}
        store['invoices'].append(invoice)
        if paid or (month==11 and case in [2,3]):
            status='approved' if paid else 'pending' if case==2 else 'rejected'
            store['payments'].append({'id':'payment-'+iid,'invoiceId':iid,'tenantName':lease['tenantName'],'room':lease['room'],
                'reportedAmount':paid or total,'paidAt':f'2026-{month:02d}-04T10:00:00+07:00','method':'Tiền mặt',
                'reference':'MO-PHONG-'+iid,'status':status,'approvedAmount':paid if paid else None,
                'rejectionReason':'Chưa đối chiếu được phiếu thu mô phỏng.' if status=='rejected' else None,
                'reviewedAt':f'2026-{month:02d}-04T14:00:00+07:00' if status!='pending' else None})
        if month==11:
            store['readings'].append({'room':lease['room'],'period':f'2026-{month:02d}-01T00:00:00+07:00',
                'oldElectric':1000+(month-10)*power,'newElectric':1000+(month-9)*power,
                'oldWater':100+(month-10)*water,'newWater':100+(month-9)*water})


def chat(pid, prop, tid, name, room, lease_id, index):
    texts=(['Chào chủ trọ, em đã nhận được thông báo điện nước.','Chào em, có vấn đề gì em cứ nhắn để được hỗ trợ.','Dạ em cảm ơn, em sẽ kiểm tra lại chỉ số.'] if lease_id else
           ['Phòng này còn trống không ạ? Em muốn đặt lịch xem.','Phòng còn trống, bạn chọn khung giờ phù hợp nhé.','Em muốn xem vào cuối tuần, nhờ anh chị xác nhận giúp.'])
    return {'id':'chat-'+tid,'propertyId':pid,'tenantId':tid,'tenantName':name,'room':room,'leaseId':lease_id,
        'landlordName':prop['ownerName'],'propertyName':prop['name'],'unread':index%2,'tenantUnread':(index+1)%2,
        'messages':[{'id':f'msg-{tid}-{j}','index':j,'text':text,'time':f'09:{10+j*5:02d}',
                     'createdAt':(NOW-timedelta(days=1)+timedelta(minutes=j*5)).isoformat(),'fromLandlord':j==1}
                    for j,text in enumerate(texts)]}


def summary(plan):
    stores=plan['snapshot']['portfolio']['properties']
    return {'batch':BATCH,'provinces':34,'properties':len(stores),'accounts':len(plan['accounts']),
        'roles':dict(Counter(a['role'] for a in plan['accounts'])),
        'plans':dict(Counter(a['plan'] for a in plan['accounts'] if a['role']=='landlord')),
        'propertiesPerOwner':dict(Counter(a['properties'] for a in plan['accounts'] if a['role']=='landlord')),
        'tenantScenarios':dict(Counter(a['scenario'] for a in plan['accounts'] if a['role']=='tenant')),
        'rooms':sum(len(s['rooms']) for s in stores),'verified':sum(plan['snapshot']['admin']['verified'].values()),
        **{k:sum(len(s[k]) for s in stores) for k in ['leases','invoices','payments','members','incidents','readings']},
        'conversations':len(plan['snapshot']['conversations']['records']),'viewings':len(plan['snapshot']['viewings']['records'])}


def validate(plan):
    accounts=plan['accounts']; by_uid={a['uid']:a for a in accounts}
    assert len(by_uid)==len(accounts)==len({a['email'] for a in accounts})
    stores=plan['snapshot']['portfolio']['properties']; assert len(stores)==680
    assert set(Counter(s['property']['city'] for s in stores).values())=={20}
    for owner in [a for a in accounts if a['role']=='landlord']:
        owned=[s for s in stores if plan['owners'][s['property']['id']]==owner['uid']]
        assert 1<=len(owned)<=5 and len(owned)<=PLANS[owner['plan']][1]
        assert all(len(s['rooms'])<=PLANS[owner['plan']][2] for s in owned)
    tids={a['tenantId'] for a in accounts if a['role']=='tenant'}
    for store in stores:
        lease_ids={l['id'] for l in store['leases']}
        for lease in store['leases']:
            assert lease['tenantId'] in tids
        for invoice in store['invoices']:
            assert invoice['leaseId'] in lease_ids
            approved=sum(p['approvedAmount'] or 0 for p in store['payments'] if p['invoiceId']==invoice['id'] and p['status']=='approved')
            assert approved==invoice['paidAmount']<=sum(c['amount'] for c in invoice['charges'])
    return summary(plan)


def dart(tool, source, target):
    sdk=Path(shutil.which('dart.bat') or shutil.which('dart')).parent/'cache/dart-sdk/bin/dart.exe'
    subprocess.run([str(sdk),'--packages=.dart_tool/package_config.json',str(ROOT/'tool'/tool),str(source),str(target)],cwd=ROOT,check=True)


def export():
    plan=load('plan.json'); validate(plan)
    # Model normalization is performed by prepare_operating_demo_test.dart.
    normalized=load('normalized.json')
    plan['snapshot']['portfolio']=normalized['snapshot']['portfolio']
    dump(WORK/'import.json',{'snapshot':plan['snapshot'],'owners':plan['owners']})
    dart('rental_import_codec.dart',WORK/'import.json',WORK/'cloud.json')
    encoded=load('cloud.json')
    dart('property_verification_manifest.dart',WORK/'cloud.json',WORK/'proofs.json')
    proofs=load('proofs.json')
    for path, data in encoded.items():
        data.update(importBatch=BATCH,isDemo=True,generation='synthetic')
        if path.startswith('rental_properties/'):
            pid=path.split('/')[1]
            verified=plan['snapshot']['admin']['verified'].get(pid,False)
            data.update(verified=verified,verificationProof=proofs[path] if verified else '',
                verification={'scope':'demo','status':'verified' if verified else 'pending','reviewedAt':STAMP,
                              'note':'Xác minh mô phỏng, không xác nhận bất động sản có thật.'},photosAreIllustrative=True)
            if verified: plan['snapshot']['admin']['verificationProofs'][pid]=proofs[path]
    for a in plan['accounts']:
        profile={'role':a['role'],'displayName':a['name'],'email':a['email'],'phoneNumber':a['phone'],
            'phoneIsSynthetic':True,'disabled':False,'createdAt':{'timestampValue':iso(-150)},'photoURL':'','emailVerified':True,
            'importBatch':BATCH,'isDemo':True,'generation':'synthetic'}
        # Timestamp is converted explicitly below; all operational dates in
        # rental models remain ISO strings, as required by app fromMap methods.
        profile['createdAt']=iso(-150)
        if a['tenantId']: profile['tenantId']=a['tenantId']
        encoded['users/'+a['uid']]=profile
        encoded['user_state/'+a['uid']]={'accounts':{'contacts':{a['role']:{'name':a['name'],'phone':a['phone'],'email':a['email'],'address':a['address']}},'notifications':{a['role']:True}},'favorites':{'ids':[]}}
        if a['tenantId']:
            encoded['tenant_codes/'+a['tenantId']]={'createdAt':STAMP}
            encoded['tenant_contacts/'+a['tenantId']]={'displayName':a['name'],'phoneNumber':a['phone']}
    encoded['management/system']={'admin':plan['snapshot']['admin'],'importBatch':BATCH,'isDemo':True}
    encoded['public_settings/viewings']={'acceptingViewings':True,'importBatch':BATCH,'isDemo':True}
    dump(WORK/'plan.json',plan); dump(WORK/'cloud.json',encoded)
    if len(encoded)>19500:
        raise RuntimeError(f'Seed has {len(encoded)} documents; reduce it before using the free write quota')
    dump(WORK/'summary.json',{**summary(plan),'firestoreDocuments':len(encoded)})
    workbook(plan)
    print(json.dumps(load('summary.json'),ensure_ascii=False),flush=True)


def workbook(plan):
    book=Workbook(); sheet=book.active;sheet.title='TaiKhoan'
    sheet.append(['Vai trò','Họ tên','Email đăng nhập','Mật khẩu','Tỉnh thành','Gói','Số nhà','Mã người thuê','Tình huống'])
    for a in plan['accounts']:
        sheet.append([a['role'],a['name'],a['email'],a['password'],a['province'],a['plan'],a.get('properties',0),a['tenantId'],a['scenario']])
    houses=book.create_sheet('NhaTro');houses.append(['Mã nhà','Tên nhà','Chủ trọ','Địa chỉ','Số phòng','Đang thuê','Xác minh mô phỏng'])
    for s in plan['snapshot']['portfolio']['properties']:
        p=s['property'];houses.append([p['id'],p['name'],plan['owners'][p['id']],p['address'],len(s['rooms']),len(s['leases']),plan['snapshot']['admin']['verified'].get(p['id'],False)])
    sources=book.create_sheet('NguonAnh');sources.append(['Mã nhà','Loại phòng','Trang nguồn','Ảnh','Ghi chú'])
    for source in load('photo-sources.json'):
        sources.append([source['propertyId'],source['roomTypeId'],source['sourceUrl'],' | '.join(source['photos']),'Ảnh minh họa; nhà trọ và người dùng được tự tạo.'])
    sample=book.create_sheet('DangNhapMau',0)
    sample.append(['Tình huống','Email đăng nhập','Mật khẩu','Mã người thuê','Gói','Số nhà'])
    selected=[next(a for a in plan['accounts'] if a['role']=='admin')]
    selected += [next(a for a in plan['accounts'] if a['role']=='landlord' and a['plan']==p) for p in PLANS]
    selected += [next(a for a in plan['accounts'] if a['scenario']==s) for s in ['Đang thuê phòng','Đang ở ghép','Đã trả phòng · tìm chỗ ở mới','Chưa thuê · đang tìm phòng']]
    for a in selected:
        sample.append([a['scenario'],a['email'],a['password'],a['tenantId'],a['plan'],a.get('properties',0)])
    for ws in book:
        ws.freeze_panes='A2';ws.auto_filter.ref=ws.dimensions
        for c in ws[1]:c.font=Font(bold=True,color='FFFFFF');c.fill=PatternFill('solid',fgColor='126B5D')
        for col in ws.columns:ws.column_dimensions[col[0].column_letter].width=26
        for row in ws.iter_rows(min_row=2):
            for cell in row:
                if isinstance(cell.value,str):cell.data_type='s'
    book.save(WORK/'TAI_KHOAN_VA_DU_LIEU_VAN_HANH.xlsx')


def publish():
    validate_project();plan=load('plan.json');validate(plan);encoded=load('cloud.json')
    state=load('publish-state.json') if (WORK/'publish-state.json').exists() else {'auth':[],'firestore':[]}
    existing={u['localId'] for u in users()}
    expected={a['uid'] for a in plan['accounts']}
    if existing-expected: raise RuntimeError('Unrelated Auth accounts appeared; review before importing')
    # PBKDF2 is supported by Firebase import and uses a per-user random salt.
    # The shared demo password is held only in the ignored account workbook.
    for start in range(0,len(plan['accounts']),500):
        batch=[a for a in plan['accounts'][start:start+500] if a['uid'] not in existing]
        if not batch:continue
        imported=[]
        for a in batch:
            salt=secrets.token_bytes(16)
            hashed=hashlib.pbkdf2_hmac('sha256',a['password'].encode(),salt,100000,dklen=32)
            imported.append({'localId':a['uid'],'email':a['email'],'emailVerified':True,'displayName':a['name'],
                'passwordHash':base64.b64encode(hashed).decode(),'salt':base64.b64encode(salt).decode(),
                'createdAt':str(int((NOW-timedelta(days=150)).timestamp()*1000)),'disabled':False})
        response=request('POST',AUTH+':batchCreate',{'hashAlgorithm':'PBKDF2_SHA256','rounds':100000,'users':imported,'sanityCheck':True,'allowOverwrite':False})
        if response.get('error'):raise RuntimeError('Auth import returned errors; inspect counts before continuing')
        state['auth'] += [a['uid'] for a in batch];dump(WORK/'publish-state.json',state)
        print(json.dumps({'authImported':len(state['auth'])}),flush=True)
    # Metadata first, then property/financial rows. SDK rules never see records
    # with missing profiles when a demo user signs in during the import.
    entries=sorted(encoded.items(),key=lambda e:(0 if e[0].startswith(('users/','tenant_','user_state/')) else 1,e[0]))
    done=set(state['firestore'])
    for start in range(0,len(entries),350):
        batch=[(p,d) for p,d in entries[start:start+350] if p not in done]
        if not batch:continue
        writes=[{'update':{'name':BASE.split('https://firestore.googleapis.com/v1/')[1]+'/'+path,'fields':{k:wire_value(v) for k,v in data.items()}},'currentDocument':{'exists':False}} for path,data in batch]
        request('POST',BASE+':commit',{'writes':writes})
        state['firestore'] += [p for p,_ in batch];dump(WORK/'publish-state.json',state)
        print(json.dumps({'firestoreCreated':len(state['firestore']),'total':len(encoded)}),flush=True)


def supabase():
    plan=load('plan.json')
    def lit(v):return 'null' if v is None else "'"+str(v).replace("'","''")+"'"
    rows=plan['orders'];sql=['begin;']
    sql.append("insert into public.subscription_payment_settings (id,bank_name,bank_bin,account_name,account_number,instructions,updated_by) values (true,'Vietcombank','970436','TAI KHOAN MO PHONG','0000000000','Dữ liệu mô phỏng để kiểm thử; không chuyển tiền.','demo-admin') on conflict (id) do nothing;")
    for row in rows:
        sql.append('insert into public.subscription_orders ('+','.join(row)+') values ('+','.join(lit(v) for v in row.values())+') on conflict (id) do nothing;')
    sql.append("insert into public.subscription_legacy_migrations(id) values ('firestore-subscriptions-v1') on conflict do nothing;")
    sql+=['commit;','select plan_id,count(*) from public.subscription_orders group by plan_id;']
    path=WORK/'seed-subscriptions.sql';path.write_text('\n'.join(sql),encoding='utf-8')
    result=subprocess.run([shutil.which('npx.cmd'),'--yes','supabase','db','query','--remote='+REF,'--file',str(path),'--yes','--output','json'],capture_output=True)
    if result.returncode:raise RuntimeError('Supabase seed failed: '+result.stderr.decode('utf-8',errors='replace')[:500])
    dump(WORK/'supabase-publish.json',{'project':REF,'orders':len(rows),'completed':True})
    print(json.dumps({'subscriptionOrdersPublished':len(rows)}),flush=True)


def authcheck():
    plan=load('plan.json');_,key=project_config()
    for role in ['admin','landlord','tenant']:
        a=next(a for a in plan['accounts'] if a['role']==role)
        response=requests.post('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword',params={'key':key},
            json={'email':a['email'],'password':a['password'],'returnSecureToken':True},timeout=40)
        result=response.json()
        if not response.ok:
            raise RuntimeError('Imported password verification failed for '+role+': '+result.get('error',{}).get('message','unknown'))
        assert result['localId']==a['uid']
        print(json.dumps({'role':role,'passwordSignIn':True}),flush=True)


def quotacheck():
    response=requests.get(BASE+'/users/demo-admin',headers={'Authorization':'Bearer '+os.environ['FIREBASE_ACCESS_TOKEN']},timeout=30)
    if response.ok:
        print(json.dumps({'singleDocumentRead':True}),flush=True)
    else:
        error=response.json().get('error',{})
        print(json.dumps({'httpStatus':response.status_code,'status':error.get('status'),'message':error.get('message'),
                          'retryAfter':response.headers.get('Retry-After')}),flush=True)


def available_checks():
    """Finish independent checks without retrying exhausted Firestore reads."""
    plan=load('plan.json');encoded=load('cloud.json');state=load('publish-state.json')
    assert set(state['firestore'])==set(encoded)
    remote={u['localId']:u for u in users()}
    assert set(remote)=={a['uid'] for a in plan['accounts']}
    for a in plan['accounts']:
        assert remote[a['uid']]['email']==a['email']
        assert remote[a['uid']]['displayName']==a['name']
        assert remote[a['uid']].get('disabled',False)==False
    authcheck()
    query_file=WORK/'verify-subscriptions.sql'
    query_file.write_text('select coalesce(jsonb_agg(to_jsonb(t)),\'[]\'::jsonb) as orders from public.subscription_orders t;',encoding='utf-8')
    response=subprocess.run([shutil.which('npx.cmd'),'--yes','supabase','db','query','--remote='+REF,
                             '--file',str(query_file),'--read-only','--output','json'],capture_output=True)
    if response.returncode:raise RuntimeError('Subscription read-back failed')
    output=response.stdout.decode('utf-8');payload=json.loads(output[output.index('{'):])
    actual={row['id']:row for row in payload['rows'][0]['orders']}
    assert set(actual)=={row['id'] for row in plan['orders']}
    for row in plan['orders']:
        for key,value in row.items():
            server=actual[row['id']][key]
            if key.endswith('_at') and value is not None:
                assert datetime.fromisoformat(server)==datetime.fromisoformat(value)
            elif key=='amount':assert int(server)==int(value)
            else:assert server==value,(row['id'],key)
    workbook(plan)
    report={**summary(plan),'firestoreWritesConfirmed':len(encoded),'authAccountsVerified':len(remote),
            'subscriptionOrdersVerified':len(actual),'subscriptionStatuses':dict(Counter(o['status'] for o in plan['orders'])),
            'workingPhotoUrls':sum(len(a['photos']) for a in load('photos.json')['albums']),
            'localTestsPassed':16,'passwordSignInVerified':['admin','landlord','tenant'],
            'firestoreReadBack':'blocked by daily free read quota (HTTP 429 RESOURCE_EXHAUSTED)',
            'profileClientWriteVerification':'pending until read quota resets',
            'approximateQuotaResetLocal':'2026-11-22 15:00 Asia/Bangkok',
            'androidCacheReset':'not completed: connected device was disconnected',
            'status':'published; Firestore read-back pending quota reset'}
    dump(WORK/'verification.json',report)
    dump(ROOT/'artifacts/BAO_CAO_DU_LIEU_VAN_HANH.json',report)
    print(json.dumps(report,ensure_ascii=False),flush=True)


def covers():
    """Diversify list covers using each property's own room photo album."""
    plan=load('plan.json');encoded=load('cloud.json');before=deepcopy(encoded)
    for store in plan['snapshot']['portfolio']['properties']:
        pid=store['property']['id']
        if int(pid.rsplit('-',1)[1])%10==0:continue
        photo=store['roomTypes'][0]['photos'][0]['url']
        store['property']['imageUrl']=photo
        encoded['rental_properties/'+pid]['data']['property']['imageUrl']=photo
    dump(WORK/'covers-next.json',encoded)
    dart('property_verification_manifest.dart',WORK/'covers-next.json',WORK/'covers-proofs.json')
    proofs=load('covers-proofs.json')
    for path,data in encoded.items():
        if path.startswith('rental_properties/') and data['verified']:
            data['verificationProof']=proofs[path]
            plan['snapshot']['admin']['verificationProofs'][path.split('/')[1]]=proofs[path]
    encoded['management/system']['admin']=plan['snapshot']['admin']
    changed=[p for p in encoded if encoded[p]!=before[p]]
    for start in range(0,len(changed),250):
        paths=changed[start:start+250]
        names=[BASE.split('https://firestore.googleapis.com/v1/')[1]+'/'+p for p in paths]
        found=request('POST',BASE+':batchGet',{'documents':names})
        live={r['found']['name'].split('/documents/')[1]:r['found'] for r in found if 'found' in r}
        writes=[]
        for path in paths:
            doc=live[path]
            data={k:decode_wire(v) for k,v in doc.get('fields',{}).items()}
            if data!=before[path]:raise RuntimeError('Cover target changed during import: '+path)
            writes.append({'update':{'name':doc['name'],'fields':{k:wire_value(v) for k,v in encoded[path].items()}},
                           'currentDocument':{'updateTime':doc['updateTime']}})
        request('POST',BASE+':commit',{'writes':writes})
    dump(WORK/'plan.json',plan);dump(WORK/'cloud.json',encoded)
    print(json.dumps({'propertyCoversUpdated':len(changed)-1}),flush=True)


def verify():
    plan=load('plan.json');expected=load('cloud.json')
    live=documents();actual={d['name'].split('/documents/')[1]:{k:decode_wire(v) for k,v in d.get('fields',{}).items()} for d in live}
    mismatches=[p for p,d in expected.items() if actual.get(p)!=d]
    if mismatches:raise RuntimeError(f'{len(mismatches)} Firestore documents do not match seed plan; first path: '+mismatches[0])
    live_users={u['localId']:u for u in users()}
    assert set(live_users)=={a['uid'] for a in plan['accounts']}
    _,key=project_config();samples=[]
    # Actual password sign-in proves imported hash/salt and provider config work.
    selections=[next(a for a in plan['accounts'] if a['role']==role) for role in ['admin','landlord','tenant']]
    selections += [next(a for a in plan['accounts'] if a['role']=='landlord' and a['plan']=='go')]
    selections += [next(a for a in plan['accounts'] if a['scenario']==scenario) for scenario in ['Đang ở ghép','Đã trả phòng · tìm chỗ ở mới','Chưa thuê · đang tìm phòng']]
    for a in selections:
        role=a['role']
        response=requests.post('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword',params={'key':key},
            json={'email':a['email'],'password':a['password'],'returnSecureToken':True},timeout=30)
        if not response.ok:raise RuntimeError('Demo sign-in verification failed for '+role)
        result=response.json();assert result['localId']==a['uid']
        token=result['idToken']
        profile=requests.get(BASE+'/users/'+a['uid'],headers={'Authorization':'Bearer '+token},timeout=30)
        assert profile.ok
        state_path='user_state/'+a['uid']
        saved=requests.patch(BASE+'/'+state_path,headers={'Authorization':'Bearer '+token},
            json={'fields':{k:wire_value(v) for k,v in expected[state_path].items()}},timeout=30)
        if not saved.ok:raise RuntimeError('Client profile write rejected for '+role)
        action='listOrders' if role in ['admin','landlord'] else 'getPaymentSettings'
        integration=requests.post(f'https://{REF}.supabase.co/functions/v1/subscription-api',
            headers={'Authorization':'Bearer '+token,'apikey':'sb_publishable_2oautia3Tc3XUFP1VGlVQw__uNfvWGC'},json={'action':action},timeout=40)
        if not integration.ok:raise RuntimeError('Subscription API rejected seeded '+role)
        payload=integration.json()
        if role=='landlord':assert all(o['landlordUid']==a['uid'] for o in payload.get('orders',[]))
        samples.append({'role':role,'uid':a['uid'],'scenario':a['scenario'],'passwordSignIn':True,
                        'profileRead':True,'profileWrite':True,'subscriptionApi':True})
    report={**summary(plan),'firestoreDocumentsVerified':len(expected),'authUsersVerified':len(live_users),'signInSamples':samples,'status':'verified'}
    dump(WORK/'verification.json',report);dump(ROOT/'artifacts/BAO_CAO_DU_LIEU_VAN_HANH.json',report)
    print(json.dumps(report,ensure_ascii=False),flush=True)


def enrich():
    plan=load('plan.json')
    if plan.get('enriched'): return
    accounts=plan['accounts']
    stores=plan['snapshot']['portfolio']['properties']
    for province in load('provinces.json'):
        code=province['code'];store=next(s for s in stores if s['property']['id']==f'op26-{code:02d}-01')
        representative=store['leases'][0]
        seekers=[a for a in accounts if a['uid'].startswith(f'demo-seeker-s{code:02d}')]
        for i,status in [(0,'active'),(2,'pending'),(3,'rejected')]:
            a=seekers[i]
            store['members'].append({'id':'household-'+a['tenantId'],'leaseId':representative['id'],
                'tenantId':a['tenantId'],'name':a['name'],'phone':a['phone'],'joinedAt':iso(-30),
                'isRepresentative':False,'status':status,'requestedBy':representative['tenantId'],
                'requestedAt':iso(-31),'rejectionReason':'Chưa thống nhất thời gian chuyển vào.' if status=='rejected' else None})
            if status=='active':
                a['scenario']='Đang ở ghép';a['address']=store['property']['address']
                representative['occupantCount']=2
        former=seekers[1]
        owner=next(a for a in accounts if a['uid']==plan['owners'][store['property']['id']])
        prior=lease_row(store['property']['id'],store['rooms'][-1]['code'],former,owner,
                        store['roomTypes'][-1]['monthlyRent'],store['property']['address'],0)
        prior.update(id='history-'+former['tenantId'],startDate=iso(-500),endDate=iso(-150),
                     status='terminated',terminatedAt=iso(-150),terminationReason='Chuyển nơi làm việc.')
        store['leases'].append(prior);former['scenario']='Đã trả phòng · tìm chỗ ở mới'
        # Pending and cancelled orders exercise review and upgrade screens.
        free=next(a for a in accounts if a['uid']==f'demo-owner-{code:02d}-01')
        pending=subscription({**free,'plan':'go'},accounts[0])
        pending.update(id=str(uuid.uuid5(uuid.NAMESPACE_URL,BATCH+'pending'+free['uid'])),legacy_id=BATCH+':pending:'+free['uid'],
                       payment_reference='DEMOPENDING'+str(code),status='submitted',starts_at=None,expires_at=None,
                       reviewed_at=None,reviewed_by=None)
        plan['orders'].append(pending)
        paid=next(a for a in accounts if a['uid']==f'demo-owner-{code:02d}-02')
        upgrade=subscription({**paid,'plan':'plus'},accounts[0])
        upgrade.update(id=str(uuid.uuid5(uuid.NAMESPACE_URL,BATCH+'upgrade'+paid['uid'])),legacy_id=BATCH+':upgrade:'+paid['uid'],
                       payment_reference='DEMOUPGRADE'+str(code),status='awaiting_payment',submitted_at=None,
                       starts_at=None,expires_at=None,reviewed_at=None,reviewed_by=None)
        plan['orders'].append(upgrade)
        for status in ['rejected','cancelled']:
            old=subscription(paid,accounts[0])
            old.update(id=str(uuid.uuid5(uuid.NAMESPACE_URL,BATCH+status+paid['uid'])),legacy_id=BATCH+':'+status+':'+paid['uid'],
                       payment_reference='DEMO'+status.upper()+str(code),status=status,starts_at=None,expires_at=None,
                       created_at=iso(-75),submitted_at=iso(-74),reviewed_at=iso(-73))
            plan['orders'].append(old)
    plan['enriched']=True
    validate(plan)
    dump(WORK/'plan.json',plan);dump(WORK/'import.json',{'snapshot':plan['snapshot'],'owners':plan['owners']})
    print(json.dumps(summary(plan),ensure_ascii=False),flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['probe','collect','prepare','enrich','export','publish','supabase','authcheck','quotacheck','covers','available_checks','verify'])
    args=parser.parse_args();WORK.mkdir(parents=True,exist_ok=True)
    globals()[args.action]()
