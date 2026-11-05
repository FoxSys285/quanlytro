# Bộ 60 nhà trọ tham khảo cho đồ án

File kết quả: `artifacts/DU_LIEU_60_NHA_TRO.xlsx`. Mẫu gốc `artifacts/MAU_THU_THAP_NHA_TRO.xlsx` được giữ nguyên. Workbook kết quả có mật khẩu tài khoản thử nghiệm nên đã được loại khỏi Git. Không chia sẻ công khai workbook này.

Danh mục lấy các trường giá, diện tích, đường/phường và ảnh từ API tin đăng công khai Nhà Tốt. Sheet `NguonDuLieu` ghi từng mã tin, URL, endpoint thu thập và thời điểm lấy dữ liệu. Chia đều 20 mục miền Bắc, 20 miền Trung/Tây Nguyên và 20 miền Nam; bao phủ Hà Nội, Hải Phòng, Huế, Đà Nẵng, Khánh Hòa, Đắk Lắk, Lâm Đồng, TP. Hồ Chí Minh, Cần Thơ, Đồng Nai và An Giang theo nhãn nguồn.

Đây là **bộ dữ liệu thử nghiệm có dẫn nguồn**. Mỗi tin tạo một hồ sơ nhà, một loại phòng và một phòng đại diện; chưa xác minh tổng số tòa nhà thật, quyền sở hữu, địa chỉ đầy đủ hoặc tình trạng còn phòng. Phường/khu vực được giữ theo nguồn, có thể là đơn vị hành chính cũ. Không sử dụng danh tính hay thông tin đăng nhập của người đăng tin thật.

Sheet `ChuTro` có `ownerUid`, `displayName`, `email`, `password`, `role`, `disabled`, `createdAt`, `photoURL`, `isDemo`, `firebaseStatus`. Có 60 chủ trọ thử nghiệm với email thuộc miền `example.com`, mật khẩu ngẫu nhiên riêng từng tài khoản và `role: landlord`. `ownerUid` liên kết chính xác Firebase Authentication UID, `users/{uid}` và nhà trọ. `photoURL` để trống, không giả ảnh chân dung.

Điện thoại `0000000000`, mã phòng `P101`, tầng 1, sức chứa 2 người và phí điện 4.000 đồng/kWh, nước 15.000 đồng/m³ đều là giá trị giả lập. Các mô tả và sheet hướng dẫn ghi rõ điều này. Chưa tạo người thuê, hợp đồng, hóa đơn hoặc giao dịch thật. Ảnh dùng URL từ CDN Nhà Tốt; chưa tải lên Firebase Storage.

Firebase đích được đọc từ `.firebaserc` và đối chiếu `lib/firebase_options.dart`, hiện là `tropremium-d14ac`. Không sử dụng địa chỉ project legacy trong các script cũ. Công cụ mới chỉ tạo các ID bắt đầu bằng `nt60-` và giữ nguyên dữ liệu cũ.

Các collection được thêm:

- `users`: 60 hồ sơ chủ trọ; **không có trường mật khẩu**. `createdAt` là Firestore Timestamp.
- `rental_properties`: 60 nhà với thông tin phòng, loại phòng và dịch vụ.
- `public_rooms`: 60 phòng đại diện, có giá/diện tích/album và nhãn dữ liệu mẫu.
- `rental_records`: 60 document `settings`, chưa có dữ liệu người thuê.

Tổng cộng 60 tài khoản Authentication và 240 document Firestore mới. Mật khẩu do Firebase Authentication xử lý. Tất cả document mới có `isDemo: true`, `importBatch: nt60-v1`. Các document danh mục còn có nguồn tham khảo và cờ chưa xác minh quyền sở hữu/tình trạng còn phòng.

Công cụ `tool/collect_nationwide_rentals.py` giữ kế hoạch, mật khẩu, nhật ký tạo Auth và bản sao lưu riêng trong `.local-backups/nationwide-rentals/`, đã được Git bỏ qua. `tool/with_firebase_cli.cjs` sử dụng phiên Firebase CLI sẵn có, giữ token trong bộ nhớ/biến môi trường tiến trình con; không in token.

Luồng thực hiện gồm `collect`, `collect-regions`, `prepare`, `check-photos`, `build`, `export`, `cloud-preview`, `cloud-apply`, `cloud-verify`. Ba bước cuối chạy qua:

```powershell
node tool/with_firebase_cli.cjs tool/collect_nationwide_rentals.py cloud-preview
node tool/with_firebase_cli.cjs tool/collect_nationwide_rentals.py cloud-apply
node tool/with_firebase_cli.cjs tool/collect_nationwide_rentals.py cloud-verify
```

Không chạy lại `cloud-apply` sau một đợt nhập thành công: công cụ chặn document trùng để tránh ghi đè. Nếu quá trình tạo Auth bị gián đoạn trước commit Firestore, nhật ký cho phép tiếp tục đúng các tài khoản đã tạo. Không có transaction chung giữa Auth và Firestore; Auth có thể được tạo một phần nếu lỗi mạng. Firestore dùng một commit nguyên tử cho 240 document với điều kiện `exists: false` cho từng document.

`cloud-verify` đọc lại toàn bộ document để đối chiếu, kiểm tra dữ liệu cũ còn nguyên, thử mật khẩu của cả 60 tài khoản, đọc hồ sơ bằng token chủ trọ và kiểm tra truy vấn đúng chủ sở hữu. Báo cáo không chứa mật khẩu ở `artifacts/BAO_CAO_60_NHA_TRO.json`. Trạng thái `Đã xác minh` trong `ChuTro` chỉ nói về việc tạo tài khoản/dữ liệu Firebase, không phải xác minh chủ trọ thật.

Nguồn đối chiếu: [Nhà Tốt](https://www.nhatot.com/thue-phong-tro), [Firebase Admin user management](https://firebase.google.com/docs/auth/admin/manage-users), [Firestore commit](https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/commit).
