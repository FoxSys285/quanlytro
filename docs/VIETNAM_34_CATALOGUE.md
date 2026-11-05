# Dữ liệu đồ án cho 34 tỉnh/thành

Bộ mới thay thế toàn bộ 60 nhà trọ đã tạo trước đó, theo yêu cầu của người dùng. File nhập liệu là `artifacts/DU_LIEU_680_NHA_TRO_34_TINH.xlsx`; file này có mật khẩu đăng nhập riêng từng chủ trọ và được loại khỏi Git.

Quy mô:

- 34 tỉnh/thành hiện hành, **20 nhà trọ mỗi tỉnh/thành**, tổng 680 nhà.
- 680 chủ trọ, mỗi tài khoản quản lý đúng một nhà. Firebase UID cũng là mã nhà để tương thích quy tắc tạo nhà của ứng dụng.
- 3.740 tầng, 15.034 phòng. Nhà có 1–10 tầng liên tiếp; mỗi tầng có 2–12 phòng.
- 2.338 loại phòng, mỗi nhà có 2–5 loại và mỗi loại đều được sử dụng.
- 3.400 dòng dịch vụ: điện, nước, internet, giữ xe, vệ sinh chung.

Mã phòng giữ nguyên dạng `P.101`, `P.102`, `P.201`. Tầng 10 dùng `P.1001` đến `P.1012`. Phòng liên kết loại phòng qua `roomTypeId` trong cùng `propertyId`. Giá và album nằm trên loại phòng; các phòng cùng loại dùng chung dữ liệu đó theo model của ứng dụng.

Danh mục tỉnh/phường lấy từ API v2 mà ứng dụng đang dùng, đối chiếu tập mã 34 tỉnh theo [Bảng danh mục Chính phủ](https://baochinhphu.vn/bang-danh-muc-va-ma-so-cua-34-tinh-thanh-moi-3321-don-vi-hanh-chinh-cap-xa-moi-102250704153652947.htm). Tên nhà, chủ trọ, số nhà/đường, quy mô, mô tả, tiện ích và giá được **tự tạo phục vụ đồ án**, không khẳng định là nhà thật đã khảo sát. Số điện thoại dùng `0000000000` để tránh gán số của người thật; email thuộc miền `example.com`.

Ảnh được tìm trên Internet qua nguồn công khai Nhà Tốt/Chợ Tốt. Có 198 album với 586 URL ảnh tải được tại thời điểm thu thập; cách phân bổ loại phòng sử dụng 550 URL ảnh khác nhau trong bộ này. `artifacts/NGUON_ANH_680_NHA_TRO.json` và sheet `NguonAnh` ghi URL ảnh, tin gốc và API chi tiết. Ảnh chỉ minh họa cho nhà/loại phòng tự tạo, có thể dùng lại giữa các nhà. Chưa tải ảnh lên Firebase Storage. Không thêm tiền tố `[MẪU]` vào tên hiển thị.

Các sheet Excel:

- `ChuTro`: UID, tên, email, mật khẩu, vai trò, trạng thái, ngày tạo.
- `NhaTro`, `LoaiPhong`, `PhongTro`, `DichVu`: giữ nguyên cấu trúc mẫu nhập liệu.
- `TangNha`: số phòng của từng tầng trong từng nhà.
- `ThongKeTinhThanh`: thống kê nhà/tầng/phòng/loại phòng của từng tỉnh.
- `NguonAnh`, `HuongDan`: nguồn ảnh và cách hiểu dữ liệu.

Firebase đích được đọc từ `.firebaserc` và đối chiếu cấu hình Flutter, hiện là `tropremium-d14ac`. Bộ mới mang `importBatch: vn34-v1`, ID nhà/chủ dạng `vn34-01-001`. Mỗi document có thông tin tự tạo/ảnh minh họa trong metadata. Tạo 17.074 document: 680 `users`, 680 `rental_properties`, 680 `rental_records` loại `settings`, 15.034 `public_rooms`. Mật khẩu chỉ đưa vào Firebase Authentication; Firestore không có mật khẩu. Chưa tạo hợp đồng, người thuê hoặc hóa đơn.

Luồng công cụ:

```powershell
python tool/generate_vietnam_catalogue.py administrative
python tool/generate_vietnam_catalogue.py photos
python tool/generate_vietnam_catalogue.py prepare
python tool/generate_vietnam_catalogue.py build
python tool/generate_vietnam_catalogue.py export
node tool/with_firebase_cli.cjs tool/publish_vietnam_catalogue.py preview
node tool/with_firebase_cli.cjs tool/publish_vietnam_catalogue.py auth
node tool/with_firebase_cli.cjs tool/publish_vietnam_catalogue.py delete-old
node tool/with_firebase_cli.cjs tool/publish_vietnam_catalogue.py publish
node tool/with_firebase_cli.cjs tool/publish_vietnam_catalogue.py verify
```

Bước `administrative` tải `.local-backups/vietnam-34-rentals/administrative-units.json` từ `https://provinces.open-api.vn/api/v2/?depth=2` và kiểm tra tập mã tỉnh trước khi lưu. Dữ liệu riêng, mật khẩu, bản sao lưu và nhật ký nằm trong `.local-backups/vietnam-34-rentals/`, đã được Git bỏ qua. `prepare` chặn chạy lại để không làm thay đổi mật khẩu tài khoản đã tạo.

`delete-old` chỉ xóa các nhà, phòng, bản ghi và tài khoản thuộc bộ `nt60` trong kế hoạch cũ, theo UID/email/propertyId đã đối chiếu và sao lưu. Tài khoản có sẵn ngoài bộ đó được giữ nguyên. Mỗi thao tác xóa Firestore dùng điều kiện phiên bản để tránh xóa nhầm dữ liệu thay đổi đồng thời.

`publish` chia thành các commit tối đa 400 document, giữ trọn mỗi nhà, tài khoản, cấu hình và toàn bộ tin phòng trong cùng một commit. Mỗi document dùng điều kiện `exists: false`. Nếu bị gián đoạn, chạy tiếp `auth`/`publish`; dữ liệu đã khớp được bỏ qua, dữ liệu khác kế hoạch sẽ bị chặn. Không có transaction chung cho toàn bộ 680 nhà hoặc giữa Auth và Firestore. Vì vậy phải xem nhật ký nếu một bước bị lỗi; không tự xóa/ghi đè để chạy lại.

Kiểm tra gồm các ràng buộc trên toàn bộ 680 nhà, roundtrip XLSX, mã phòng có dấu chấm qua codec thật của app, đọc lại toàn bộ document Firebase, đăng nhập các tài khoản mới và xác nhận bộ cũ đã được xóa. Báo cáo hoàn tất ở `artifacts/BAO_CAO_680_NHA_TRO.json` chỉ được tạo sau khi kiểm tra đạt.

```powershell
python -m unittest discover -s test -p test_rental_import.py
python -m unittest discover -s test -p test_vietnam_catalogue.py
python tool/rental_import.py artifacts/DU_LIEU_680_NHA_TRO_34_TINH.xlsx
```
