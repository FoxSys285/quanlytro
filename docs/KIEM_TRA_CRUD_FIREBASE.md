# CRUD nhà trọ và đồng bộ Firebase — 05/11/2026

Kết quả: 30 kiểm tra Flutter đạt (gồm xuất payload live), analyzer không có lỗi,
build APK debug với `USE_FIREBASE_AUTH=true` thành công. Kiểm tra live cuối cùng
`crud-check-1793866941582362` trả về `CREATE_READ_BACK_OK`, `UPDATE_READ_BACK_OK`,
`RECORD_ONLY_LIVE_UPDATE_OK`, `ARCHIVE_READ_BACK_OK` và
`LIVE_PROPERTY_CRUD_VERIFIED`. Chứng cứ trong `.local-backups/firestore/`.

Việc nhập 250 bản ghi minh họa trước đây không chứng minh CRUD trong ứng dụng.
Phiên này đọc luồng giao diện → model → AppPersistence → repository Firestore,
sửa các lỗi cụ thể và kiểm tra riêng trên Firebase thật.

## Thay đổi

- Danh sách nhà trọ luôn có nút thêm, kể cả tài khoản đang quản lý một nhà.
- Thêm/sửa/xóa tại danh sách và sửa thông tin chi tiết chờ thao tác lưu hoàn
  tất; lỗi server hiện rõ, không báo đã lưu Firebase trước khi server xác nhận.
- Đăng nhập phải tải dữ liệu Firebase trước khi mở phần chỉnh sửa; bỏ bộ nhà
  trọ mẫu tạm và cơ chế nuốt lỗi tải ban đầu. Các lần đọc nghiệp vụ yêu cầu
  `Source.server`.
- Nhà mới chỉ có danh sách phòng, loại phòng và dịch vụ ban đầu. Không tự thêm
  hợp đồng, hóa đơn, khoản thu, tài khoản ngân hàng hay ảnh mẫu. Giữ đủ bốn loại
  phòng ban đầu, không tự bỏ loại theo thứ tự nhà.
- Listener theo dõi cả `rental_records`: chủ trọ theo `ownerUid`, người thuê
  theo `tenantIds`, admin theo quyền. Thay đổi chỉ ở hóa đơn, khoản thu, thành
  viên, sự cố hoặc tin nhắn cũng kích hoạt tải lại dữ liệu.

## Cơ chế lưu

`RentalPortfolio` nhận thông báo thay đổi từ từng nhà trọ và được
`AppPersistence` theo dõi. Bộ lưu chung xuất các document qua
`encodeCloudDocuments`; repository chỉ ghi phần thay đổi và dùng transaction
của Firebase SDK để kiểm tra xung đột. Vì vậy sửa phòng, giá loại phòng và dịch
vụ cũng được xuất sang nhà trọ và danh mục phòng tương ứng.

Xóa nhà trọ là **lưu trữ**: đánh dấu `archived: true`, ẩn các phòng công khai,
không xóa vật lý lịch sử. Model chặn xóa nhà có hợp đồng/hóa đơn và chặn xóa
nhà cuối cùng. Không thay đổi Rules, vai trò, tài khoản hoặc dữ liệu người thuê
đang có.

## Kiểm tra

`test/property_crud_test.dart` kiểm tra quyền truy cập nút thêm, dữ liệu nhà mới,
lỗi tải Firebase, chờ ghi thành công và hiển thị lỗi ghi. Các bài kiểm tra sẵn
có kiểm tra CRUD phòng/loại phòng, hợp đồng → hóa đơn → duyệt thu, lưu/khôi phục,
hợp nhất dữ liệu và giao diện ở 390/1280 px.

```powershell
flutter analyze --no-pub
flutter test --no-pub test/property_crud_test.dart test/demo_portfolio_workflow_test.dart test/cloud_catalog_codec_test.dart test/cloud_merge_test.dart test/admin_live_data_test.dart test/portfolio_ui_test.dart test/cloud_auth_boundary_test.dart test/local_persistence_test.dart
```

Kiểm tra live tạo payload từ model/codec thật của app:

```powershell
flutter test --no-pub test/property_crud_test.dart --dart-define=PROPERTY_CRUD_EXPORT=true
node tool/check_live_property_crud.cjs --apply
```

Công cụ Node dùng Firebase SDK đã cài trong `.dart_tool/firebase_tools`.
Email/mật khẩu admin được cung cấp qua môi trường tiến trình
`CRUD_ADMIN_EMAIL`/`CRUD_ADMIN_PASSWORD`; không đưa vào file hoặc mã nguồn.
Chỉ thao tác mã riêng `crud-check-*`; giữ bản kế hoạch và kết quả đọc lại ở
`.local-backups/firestore/<mã kiểm tra>/`.

Mỗi nhà kiểm thử gồm document nhà trọ, hai phòng công khai và cấu hình nghiệp
vụ. Kiểm tra tạo → đọc lại → sửa tên/giá → đọc lại → lưu trữ → đọc lại. Sau kiểm
tra, nhà và cấu hình được lưu trữ, hai phòng có `published/available: false`.
Kiểm tra bổ sung chỉ sửa một record cấu hình để xác nhận listener Firestore
nhận thay đổi mà không cần sửa document nhà trọ.

Phạm vi live là Firebase SDK bằng tài khoản **admin**, gán chủ sở hữu là UID
chủ trọ đang tồn tại. Chưa thao tác tay từng màn CRUD bằng tài khoản chủ trọ
trên Android; không coi kiểm tra codec/SDK là đã hoàn tất kiểm thử giao diện
trên thiết bị. Các module khác vẫn dùng bộ tự lưu chung; chưa khẳng định mọi
thao tác CRUD của toàn bộ ứng dụng đã được chạy live riêng từng trường hợp.
