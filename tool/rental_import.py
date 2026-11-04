"""Collect rental catalogues in XLSX; validate by default, never import tenants.

python tool/rental_import.py artifacts/MAU_THU_THAP_NHA_TRO.xlsx
python tool/rental_import.py filled.xlsx --export .dart_tool/rental_import
"""
import argparse
from contextlib import closing
import datetime as dt
import json
from pathlib import Path
import re
import shutil
import sqlite3
import subprocess
import sys
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
sys.path.insert(0, str(ROOT / '.dart_tool/import_dependencies'))
try:
    from openpyxl import Workbook, load_workbook
    from openpyxl.styles import Alignment, Font, PatternFill
    from openpyxl.worksheet.datavalidation import DataValidation
    from openpyxl.worksheet.table import Table, TableStyleInfo
except ImportError:
    raise SystemExit('Install: python -m pip install --target .dart_tool/import_dependencies openpyxl')

SCHEMA = {
    'NhaTro': ['propertyId', 'ownerUid', 'name', 'address', 'city', 'ward', 'ownerName', 'phone', 'description', 'amenities', 'imageUrl'],
    'LoaiPhong': ['propertyId', 'roomTypeId', 'name', 'monthlyRent', 'photoUrls'],
    'PhongTro': ['propertyId', 'code', 'floor', 'roomTypeId', 'area', 'capacity'],
    'DichVu': ['propertyId', 'id', 'name', 'unit', 'basis', 'price', 'active'],
}
EXAMPLES = {
    'NhaTro': ['nha-001', 'THAY_BANG_UID_CHU_TRO', 'Nhà trọ minh họa', 'Địa chỉ thực tế cần khảo sát', 'TP. Hồ Chí Minh', 'Phường thực tế', 'Tên chủ trọ', '0900000000', 'Mô tả nhà trọ', 'Wifi|Bãi xe|Camera', ''],
    'LoaiPhong': ['nha-001', 'studio', 'Studio', 3000000, ''],
    'PhongTro': ['nha-001', 'P101', 1, 'studio', 24, 2],
    'DichVu': ['nha-001', 'electricity', 'Điện', 'kWh', 'Theo chỉ số', 4000, True],
}
GUIDE = [
    ['THU THẬP NHÀ TRỌ / PHÒNG TRỌ', 'Mẫu nhập danh mục — không nhập tài khoản hoặc người thuê'],
    ['1. Điền dữ liệu', 'Điền 4 sheet NhaTro, LoaiPhong, PhongTro, DichVu từ hàng 2. Không đổi tên cột.'],
    ['2. Khóa liên kết', 'propertyId giống nhau giữa 4 sheet; roomTypeId của phòng phải có trong LoaiPhong cùng nhà.'],
    ['3. Chủ sở hữu', 'ownerUid là UID thật trong Firebase Authentication; users/{uid} phải có role=landlord, disabled=false.'],
    ['4. Mã định danh', 'propertyId / roomTypeId / code / id: chữ không dấu, số, dấu gạch ngang hoặc gạch dưới; không dùng khoảng trắng.'],
    ['5. Số tiền / diện tích', 'Nhập số nguyên: VNĐ không dấu chấm/phẩy. monthlyRent 0–1000000000; area 6–500 m²; floor 1–30; capacity 1–20.'],
    ['6. Ảnh / tiện ích', 'Các URL ảnh HTTPS và tiện ích phân cách bằng |. Tối đa 12 ảnh/loại. Ảnh cùng loại phòng dùng chung album.'],
    ['7. Dịch vụ bắt buộc', 'Mỗi nhà cần electricity và water. Điện: kWh / Theo chỉ số. Nước: m3 / Theo chỉ số hoặc tháng / Theo phòng.'],
    ['8. active', 'TRUE hoặc FALSE. basis: Theo chỉ số, Theo phòng, Theo người, Cố định. Giá 0–1000000000.'],
    ['9. An toàn dữ liệu', 'Importer chỉ thêm nhà MỚI; không ghi đè nhà/phòng đã có. Không nhập hợp đồng, CCCD, mật khẩu, số dư hoặc trạng thái thuê.'],
    ['10. Trạng thái phòng', 'Nhà mới chưa có hợp đồng nên phòng mới là phòng trống. Tạo hợp đồng đúng tenantId trong app khi có người thuê.'],
    ['11. Ví dụ', 'Sheet ViDu chỉ để đọc, KHÔNG được importer nhập. Thay UID minh họa bằng UID thật khi tự điền.'],
    ['12. Kiểm tra', 'python tool/rental_import.py artifacts/MAU_THU_THAP_NHA_TRO.xlsx — mặc định chỉ kiểm tra, không ghi DB/Firebase.'],
    ['13. Xuất bản nhập', 'python tool/rental_import.py FILE_DA_DIEN.xlsx --export .dart_tool/rental_import — xuất snapshot + Firestore JSON qua codec của app.'],
    ['14. SQLite / Firebase', 'Xem docs/DATA_IMPORT.md. SQLite dùng --sqlite PATH --apply-sqlite; Firebase dùng publisher --create-only, --apply chỉ khi đã xem trước.'],
    ['Nguồn cấu trúc', 'lib/pages/landlord/{properties,room_types,rooms,services}/models; lib/data/rental_cloud_codec.dart; lib/data/local_database.dart'],
]


def workspace_path(raw):
    path = Path(raw).resolve()
    if not path.is_relative_to(ROOT):
        raise ValueError(f'Đường dẫn phải nằm trong workspace: {path}')
    return path


def create_template(path):
    book = Workbook()
    book.remove(book.active)
    for name, headers in SCHEMA.items():
        sheet = book.create_sheet(name)
        sheet.append(headers)
        for _ in range(100):
            sheet.append([None] * len(headers))
        sheet.freeze_panes = 'C2'
        table = Table(displayName=name + 'Input', ref=f'A1:{sheet.cell(1, len(headers)).column_letter}101')
        table.tableStyleInfo = TableStyleInfo(name='TableStyleMedium2', showRowStripes=True)
        sheet.add_table(table)
        for column in sheet.columns:
            key = column[0].value
            sheet.column_dimensions[column[0].column_letter].width = 25 if key not in ('description', 'address', 'photoUrls', 'imageUrl') else 48
            for cell in column[1:]:
                cell.font = Font(name='Calibri', size=11, color='1261A0')
                if key not in ('monthlyRent', 'price', 'floor', 'area', 'capacity', 'active'):
                    cell.number_format = '@'
        for cell in sheet[1]:
            cell.font = Font(name='Calibri', size=11, bold=True, color='FFFFFF')
            cell.fill = PatternFill('solid', fgColor='126B5D')
            cell.alignment = Alignment(vertical='center')
        sheet.row_dimensions[1].height = 28
        sheet.sheet_view.showGridLines = False
    for name, field, lo, hi in [('LoaiPhong', 'monthlyRent', 0, 1000000000), ('PhongTro', 'floor', 1, 30), ('PhongTro', 'area', 6, 500), ('PhongTro', 'capacity', 1, 20), ('DichVu', 'price', 0, 1000000000)]:
        col = book[name].cell(1, SCHEMA[name].index(field) + 1).column_letter
        rule = DataValidation(type='whole', operator='between', formula1=lo, formula2=hi, allow_blank=True)
        rule.showErrorMessage = True
        rule.errorTitle = 'Số nguyên không hợp lệ'
        rule.error = f'Nhập số nguyên từ {lo} đến {hi}.'
        book[name].add_data_validation(rule)
        rule.add(f'{col}2:{col}10001')
    for field, choices in [('basis', 'Theo chỉ số,Theo phòng,Theo người,Cố định'), ('active', 'TRUE,FALSE')]:
        col = book['DichVu'].cell(1, SCHEMA['DichVu'].index(field) + 1).column_letter
        rule = DataValidation(type='list', formula1=f'"{choices}"', allow_blank=True)
        rule.showErrorMessage = True
        book['DichVu'].add_data_validation(rule)
        rule.add(f'{col}2:{col}10001')
    guide = book.create_sheet('HuongDan')
    for row in GUIDE:
        guide.append(row)
    example = book.create_sheet('ViDu')
    for name, headers in SCHEMA.items():
        example.append([name + ' — KHÔNG NHẬP TỰ ĐỘNG'])
        example.append(headers)
        example.append(EXAMPLES[name])
        if name == 'DichVu':
            example.append(['nha-001', 'water', 'Nước', 'm3', 'Theo chỉ số', 15000, True])
        example.append([])
    for sheet in (guide, example):
        sheet.freeze_panes = 'A2'
        sheet.sheet_view.showGridLines = False
        for row in sheet:
            for cell in row:
                cell.font = Font(name='Calibri', size=11, color='243A43')
                cell.alignment = Alignment(vertical='top', wrap_text=True)
            sheet.row_dimensions[row[0].row].height = 43 if sheet == guide else 32
        if sheet == guide:
            sheet.column_dimensions['A'].width = 32
            sheet.column_dimensions['B'].width = 113
        else:
            for column in sheet.columns:
                sheet.column_dimensions[column[0].column_letter].width = 24
            sheet.column_dimensions['B'].width = 38
        for cell in sheet[1]:
            cell.fill = PatternFill('solid', fgColor='126B5D')
            cell.font = Font(name='Calibri', size=12, bold=True, color='FFFFFF')
    path.parent.mkdir(parents=True, exist_ok=True)
    book.save(path)


def read_rows(path):
    book = load_workbook(path, data_only=False, read_only=True)
    result = {}
    try:
        for name, headers in SCHEMA.items():
            if name not in book.sheetnames:
                raise ValueError(f'Thiếu sheet {name}')
            rows = book[name].iter_rows()
            actual = [c.value for c in next(rows)]
            while actual and actual[-1] is None:
                actual.pop()
            if actual != headers:
                raise ValueError(f'{name}: tên/thứ tự cột không đúng mẫu')
            result[name] = []
            for number, cells in enumerate(rows, 2):
                if all(c.value is None for c in cells):
                    continue
                if any(c.data_type == 'f' for c in cells):
                    raise ValueError(f'{name} dòng {number}: không dùng công thức trong dữ liệu nhập')
                if any(c.value is not None for c in cells[len(headers):]):
                    raise ValueError(f'{name} dòng {number}: dữ liệu nằm ngoài cột mẫu')
                row = {key: cells[i].value if i < len(cells) else None for i, key in enumerate(headers)}
                row['_row'] = f'{name} dòng {number}'
                result[name].append(row)
    finally:
        book.close()
    return result


def text(row, key, optional=False):
    value = row.get(key)
    if optional and (value is None or value == ''):
        return ''
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{row['_row']}: {key} phải là chuỗi không rỗng (định dạng Text)")
    return value.strip()


def identifier(row, key):
    value = text(row, key)
    if not re.fullmatch(r'[A-Za-z0-9_-]{1,100}', value):
        raise ValueError(f"{row['_row']}: {key} chỉ gồm chữ không dấu, số, _ hoặc -; tối đa 100 ký tự")
    return value


def integer(row, key, lo, hi):
    value = row[key]
    if isinstance(value, bool) or not isinstance(value, (int, float)) or int(value) != value or not lo <= value <= hi:
        raise ValueError(f"{row['_row']}: {key} phải là số nguyên {lo}–{hi}")
    return int(value)


def urls(row, key):
    raw = text(row, key, optional=True)
    values = [part.strip() for part in raw.split('|') if part.strip()]
    if len(values) > 12:
        raise ValueError(f"{row['_row']}: tối đa 12 ảnh")
    for value in values:
        parsed = urlparse(value)
        if parsed.scheme != 'https' or not parsed.hostname or parsed.username or parsed.password:
            raise ValueError(f"{row['_row']}: {key} cần URL HTTPS công khai")
    return values


def build_snapshot(rows):
    stores, owners = {}, {}
    for row in rows['NhaTro']:
        key = identifier(row, 'propertyId')
        if key in stores:
            raise ValueError(f'Trùng propertyId: {key}')
        uid = text(row, 'ownerUid')
        if '/' in uid or uid.startswith('THAY_') or len(uid) > 128:
            raise ValueError(f"{row['_row']}: ownerUid phải là UID Firebase thật")
        image = urls(row, 'imageUrl')
        if len(image) > 1:
            raise ValueError(f"{row['_row']}: imageUrl chỉ có một ảnh bìa")
        prop = {'id': key, **{k: text(row, k, optional=k == 'description') for k in ['name', 'address', 'city', 'ward', 'ownerName', 'phone', 'description']},
                'amenities': [v.strip() for v in text(row, 'amenities', optional=True).split('|') if v.strip()],
                'imageUrl': image[0] if image else '', 'imageBytes': None, 'imageName': None}
        if not re.fullmatch(r'\+?[0-9 ()-]{8,20}', prop['phone']):
            raise ValueError(f"{row['_row']}: phone không hợp lệ")
        stores[key] = {'property': prop, **{k: [] for k in ['rooms', 'roomTypes', 'services', 'leases', 'invoices', 'payments', 'paymentAccounts', 'members', 'incidents', 'readings']}, 'counters': [1] * 7}
        owners[key] = uid
    seen = set()
    for name in ['LoaiPhong', 'PhongTro', 'DichVu']:
        for row in rows[name]:
            property_id = identifier(row, 'propertyId')
            if property_id not in stores:
                raise ValueError(f"{row['_row']}: propertyId chưa có trong NhaTro")
            store = stores[property_id]
            key_field = {'LoaiPhong': 'roomTypeId', 'PhongTro': 'code', 'DichVu': 'id'}[name]
            key = identifier(row, key_field)
            duplicate = (name, property_id.casefold(), key.casefold())
            if duplicate in seen:
                raise ValueError(f"{row['_row']}: trùng {key_field} trong cùng nhà")
            seen.add(duplicate)
            if name == 'LoaiPhong':
                store['roomTypes'].append({'id': key, 'name': text(row, 'name'), 'monthlyRent': integer(row, 'monthlyRent', 0, 1000000000),
                    'photos': [{'name': f'Ảnh {i + 1}', 'url': url} for i, url in enumerate(urls(row, 'photoUrls'))]})
            elif name == 'PhongTro':
                room_type = identifier(row, 'roomTypeId')
                if room_type not in {t['id'] for t in store['roomTypes']}:
                    raise ValueError(f"{row['_row']}: roomTypeId chưa có trong LoaiPhong của nhà")
                store['rooms'].append({'code': key, 'roomTypeId': room_type, 'floor': integer(row, 'floor', 1, 30),
                    'area': integer(row, 'area', 6, 500), 'capacity': integer(row, 'capacity', 1, 20), 'leaseRoomCode': None})
            else:
                active = row['active']
                if isinstance(active, str) and active.upper() in ('TRUE', 'FALSE'):
                    active = active.upper() == 'TRUE'
                if not isinstance(active, bool):
                    raise ValueError(f"{row['_row']}: active cần TRUE hoặc FALSE")
                basis = text(row, 'basis')
                if basis not in ['Theo chỉ số', 'Theo phòng', 'Theo người', 'Cố định']:
                    raise ValueError(f"{row['_row']}: basis không đúng danh sách")
                store['services'].append({'id': key, 'name': text(row, 'name'), 'unit': text(row, 'unit'), 'basis': basis,
                    'price': integer(row, 'price', 0, 1000000000), 'active': active})
    for key, store in stores.items():
        if not store['rooms']:
            raise ValueError(f'{key}: cần ít nhất một phòng')
        services = {s['id']: s for s in store['services']}
        if not {'electricity', 'water'} <= services.keys():
            raise ValueError(f'{key}: thiếu dịch vụ electricity hoặc water')
        if any(not services[k]['active'] for k in ('electricity', 'water')):
            raise ValueError(f'{key}: electricity và water phải active=TRUE')
    snapshot = {'portfolio': {'selectedId': next(iter(stores), ''), 'properties': list(stores.values())}}
    return snapshot, owners


def import_sqlite(path, snapshot, apply=False):
    if not path.exists():
        raise ValueError('SQLite đích phải là file đã được app tạo; không tự tạo tài khoản/DB mới')
    connection = sqlite3.connect(path)
    try:
        connection.execute('BEGIN IMMEDIATE')
        row = connection.execute("SELECT payload FROM app_documents WHERE id='portfolio'").fetchone()
        if row is None:
            raise ValueError('SQLite đích chưa có portfolio; mở app/cấp dữ liệu tài khoản trước')
        saved = json.loads(row[0])
        existing = {s['property']['id'] for s in saved['properties']}
        incoming = {s['property']['id'] for s in snapshot['portfolio']['properties']}
        if incoming & existing:
            raise ValueError('Chỉ thêm nhà mới; mã nhà đã tồn tại: ' + ', '.join(sorted(incoming & existing)))
        if apply:
            # Backup from a separate connection so an open transaction never blocks backup().
            backup = path.with_name(path.name + '.' + dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ') + '.bak')
            with closing(sqlite3.connect(path)) as source, closing(sqlite3.connect(backup)) as target:
                source.backup(target)
            saved['properties'].extend(snapshot['portfolio']['properties'])
            connection.execute("UPDATE app_documents SET payload=?, updated_at=? WHERE id='portfolio'",
                               (json.dumps(saved, ensure_ascii=False), dt.datetime.now(dt.timezone.utc).isoformat()))
            connection.commit()
            return backup
        connection.rollback()
    finally:
        connection.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('workbook', nargs='?', default='artifacts/MAU_THU_THAP_NHA_TRO.xlsx')
    parser.add_argument('--create-template', action='store_true')
    parser.add_argument('--export', metavar='WORKSPACE_DIR')
    parser.add_argument('--sqlite', metavar='WORKSPACE_DB')
    parser.add_argument('--apply-sqlite', action='store_true')
    args = parser.parse_args()
    path = workspace_path(args.workbook)
    if args.create_template:
        create_template(path)
        print(f'TEMPLATE_CREATED: {path}')
        return
    snapshot, owners = build_snapshot(read_rows(path))
    stores = snapshot['portfolio']['properties']
    print(f'VALID: {len(stores)} nhà, {sum(len(s["rooms"]) for s in stores)} phòng; không nhập tài khoản/người thuê.')
    if args.apply_sqlite and not args.sqlite:
        raise ValueError('--apply-sqlite cần --sqlite PATH')
    if args.sqlite:
        backup = import_sqlite(workspace_path(args.sqlite), snapshot, apply=args.apply_sqlite)
        print(f'SQLITE_IMPORTED; backup={backup}' if backup else 'SQLITE_PREVIEW_ONLY')
    if args.export:
        if not stores:
            raise ValueError('Workbook đang trống; điền dữ liệu trước khi export')
        output = workspace_path(args.export)
        output.mkdir(parents=True, exist_ok=True)
        source = output / 'rental_import.json'
        source.write_text(json.dumps({'snapshot': snapshot, 'owners': owners}, ensure_ascii=False), encoding='utf-8')
        dart = shutil.which('dart')
        if not dart:
            raise ValueError('Cần dart trong PATH để dùng codec Firestore của app')
        subprocess.run([dart, 'run', 'tool/rental_import_codec.dart', str(source), str(output / 'cloud_documents.json')], cwd=ROOT, check=True)
        print(f'EXPORTED: {output}; chưa ghi Firebase')
    elif not args.apply_sqlite:
        print('PREVIEW_ONLY: không ghi SQLite hoặc Firebase')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, OSError) as error:
        raise SystemExit(f'IMPORT_REJECTED: {error}')
