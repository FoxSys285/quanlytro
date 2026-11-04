# Thu thập và nhập nhà trọ, phòng trọ

File: [MAU_THU_THAP_NHA_TRO.xlsx](../artifacts/MAU_THU_THAP_NHA_TRO.xlsx).

Điền bốn sheet `NhaTro`, `LoaiPhong`, `PhongTro`, `DichVu`; đọc `HuongDan` và ví dụ riêng trong `ViDu`. Bốn sheet nhập liệu ban đầu trống. Các dòng ví dụ không được import. Không nhập CCCD, tài khoản, mật khẩu, hợp đồng hoặc hóa đơn vào mẫu này.

## Quan hệ dữ liệu

- `NhaTro.propertyId` là mã nhà duy nhất. Các sheet còn lại nối bằng `propertyId`.
- `NhaTro.ownerUid` phải là UID thật của Firebase Authentication, có hồ sơ `users/{uid}` với `role: landlord`, `disabled: false`.
- `LoaiPhong.roomTypeId` duy nhất trong một nhà. `PhongTro.roomTypeId` phải trỏ đúng loại của cùng nhà. Giá tháng/album ảnh đặt theo loại, không lặp lại từng phòng.
- `PhongTro.code` duy nhất trong nhà. Diện tích 6–500 m², tầng 1–30, sức chứa 1–20, đều là số nguyên theo model hiện tại.
- `DichVu.id` duy nhất trong nhà. Mỗi nhà phải có `electricity`, `water` đang hoạt động. `basis`: `Theo chỉ số`, `Theo phòng`, `Theo người`, `Cố định`.
- Tiền nhập số nguyên VNĐ; không gõ dấu phân cách. Điện thoại/ID để dạng Text để giữ số 0 đầu. URL ảnh phải là HTTPS; nhiều ảnh/tiện ích ngăn bằng `|`, tối đa 12 ảnh mỗi loại.

Importer chỉ thêm **nhà mới**, không cập nhật nhà đang có, không ghi đè phòng/hợp đồng của người thuê. Phòng mới chưa có hợp đồng nên ban đầu là phòng trống. Tạo hợp đồng và liên kết `tenantId` bằng nghiệp vụ trong app sau khi có khách thuê.

## Kiểm tra và xuất

Chạy từ thư mục dự án. Nếu chưa có thư viện đọc XLSX:

```powershell
python -m pip install --target .dart_tool/import_dependencies openpyxl
python tool/rental_import.py artifacts/MAU_THU_THAP_NHA_TRO.xlsx
```

Mặc định chỉ kiểm tra, không sửa SQLite hoặc Firebase. File trống hợp lệ để thu thập nhưng chưa được export. Sau khi điền:

```powershell
python tool/rental_import.py artifacts/MAU_THU_THAP_NHA_TRO.xlsx --export .dart_tool/rental_import
```

Xuất `rental_import.json` (snapshot + map chủ sở hữu) và `cloud_documents.json`. Dart bridge gọi trực tiếp `encodeCloudDocuments` của app để tránh hai schema khác nhau. `dart` phải có trong PATH. Không xuất bảng `users`, không tự cấp vai trò.

## Firebase

Dùng tài khoản Firebase quản trị đã được cấp quyền. Thay `admin@example.com` bằng email của bạn, chạy trong terminal và nhập mật khẩu tại lời nhắc ẩn. Không đưa mật khẩu vào lệnh, workbook, file hoặc chat. Công cụ lấy API key công khai từ `lib/firebase_options.dart`, đăng nhập Firebase, kiểm tra đúng UID và hồ sơ `users/{uid}` có `role: admin`, `disabled: false`. Token chỉ giữ trong bộ nhớ đến khi lệnh kết thúc, không tạo file đăng nhập.

```powershell
python tool/publish_cloud_documents.py --source .dart_tool/rental_import/cloud_documents.json --create-only --admin-email admin@example.com
python tool/publish_cloud_documents.py --source .dart_tool/rental_import/cloud_documents.json --create-only --admin-email admin@example.com --apply
```

Lệnh đầu xem trước, lệnh thứ hai mới ghi. Mỗi lệnh yêu cầu đăng nhập lại. Nếu đã có access token hợp lệ trong biến môi trường `FIREBASE_ACCESS_TOKEN`, có thể bỏ `--admin-email`; không ghi token vào file. Publisher xác nhận hồ sơ chủ trọ, chặn toàn bộ nếu bất kỳ document đích nào đã tồn tại, dùng `exists: false` để ngăn ghi đè khi có người khác đồng thời tạo cùng mã. Mỗi đợt tối đa 450 document để commit nguyên tử; workbook lớn hơn phải chia theo nhà trước khi export. Có bản sao lưu và đọc lại kiểm tra sau khi ghi. Không dùng lệnh publish cũ bỏ `--create-only` cho dữ liệu thu thập mới.

Đối chiếu API chính thức: [Firebase đăng nhập Email/Password qua REST](https://firebase.google.com/docs/reference/rest/auth#section-sign-in-email-password), [Firebase ID token và Firestore REST](https://firebase.google.com/docs/firestore/use-rest-api).

Các collection đích là `rental_properties`, `public_rooms` và bản ghi `settings` trong `rental_records`. Firebase ở chế độ xác thực theo vai trò mới là nguồn dùng chung; SQLite mỗi UID là cache, được nạp lại từ server khi đăng nhập.

## SQLite cục bộ

Chỉ dùng với DB nằm **trong workspace**, đã được app tạo và có `portfolio`. Đóng app đang dùng file trước khi nhập. Không tự mở/sửa DB ngoài workspace, không tạo tài khoản mới:

```powershell
python tool/rental_import.py artifacts/MAU_THU_THAP_NHA_TRO.xlsx --sqlite .dart_tool/du_lieu_thu.db
python tool/rental_import.py artifacts/MAU_THU_THAP_NHA_TRO.xlsx --sqlite .dart_tool/du_lieu_thu.db --apply-sqlite
```

Lệnh đầu không ghi. Lệnh thứ hai sao lưu file DB trước, mở transaction và chỉ nối các nhà mới vào document `portfolio`; giữ nguyên các document đăng nhập, thông báo, hội thoại và dữ liệu cũ. Không cần nhập cache SQLite thủ công khi đã nhập thành công Firebase thật.

## Kiểm tra công cụ

```powershell
python -m unittest discover -s test -p test_rental_import.py
```

Kiểm tra workbook trống/đã điền, quan hệ mã, dữ liệu không hợp lệ, công thức, roundtrip qua codec Firestore, dry-run SQLite, backup, ngăn import trùng nhà đã có hợp đồng và đăng nhập admin bằng mock (chặn tài khoản khác vai trò/bị khóa/sai UID; không lưu mật khẩu hoặc token). Chưa tự publish dữ liệu người dùng hoặc kiểm thử Excel desktop trong phiên tạo mẫu.
