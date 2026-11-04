# Chuyển bản demo sang Firebase Authentication

Mặc định dùng Firebase thật: xác thực trước khi đọc dữ liệu riêng, vai trò lấy từ `users/{uid}` trên server; không đăng nhập bằng tài khoản demo khi Firebase từ chối. SQLite được tách theo UID; web dùng Firestore trực tiếp. Không tự tạo hay nâng vai trò từ ứng dụng. Cờ `--dart-define=USE_FIREBASE_AUTH=false` chỉ dành đối chiếu bản cũ trước khi khóa collection legacy.

## 1. Bật và tạo tài khoản

Mở [Authentication của project](https://console.firebase.google.com/project/doantro-caf4b/authentication/providers) → Get started (nếu có) → Email/Password → bật công tắc đầu tiên → Save. Không cần bật Email link.

Trong Authentication → Users, tự tạo ba tài khoản: chủ trọ, người thuê và quản trị viên; tự chọn mật khẩu. Sao chép **UID**, không gửi mật khẩu vào chat hay đưa vào mã nguồn.

Tạo `.dart_tool/demo_data/provisioning.json` (chỉ UID, không có mật khẩu):

```json
{
  "landlordUid": "UID_CUA_CHU_TRO",
  "tenantUid": "UID_CUA_NGUOI_THUE",
  "adminUid": "UID_CUA_QUAN_TRI"
}
```

Tài khoản người thuê mẫu được liên kết với mã nghiệp vụ `tenant-demo` (Minh Anh). Các tài khoản khác cần hồ sơ `users/{uid}` với `role`, `disabled: false`, và `tenantId` đúng mã người thuê. Một chủ trọ mẫu quản lý 10 nhà hiện có; chủ trọ khác được cấp đúng `ownerUid` cho nhà của mình.

## 2. Sao lưu và chuyển dữ liệu

Đóng app trên emulator trước khi chuyển để tránh app cũ lưu lại dữ liệu đang mở. Các file sao lưu và UID nằm trong `.dart_tool/` đã được Git bỏ qua. Dùng dữ liệu hiện tại, không bổ sung bản mẫu:

```powershell
python tool/prepare_firebase_migration.py
flutter test --no-pub tool/export_cloud_data_test.dart
python tool/publish_cloud_documents.py
python tool/publish_cloud_documents.py --apply
```

Chỉ khi cần **bổ sung dữ liệu minh họa** mới dùng luồng cũ bên dưới:

```powershell
python tool/update_demo_firestore.py
flutter test --no-pub tool/export_cloud_data_test.dart
python tool/publish_cloud_documents.py
```

Hai lệnh Python trên chỉ xem trước, chưa ghi dữ liệu. Khi đã kiểm tra UID và bản xem trước:

```powershell
python tool/update_demo_firestore.py --apply
flutter test --no-pub tool/export_cloud_data_test.dart
python tool/publish_cloud_documents.py --apply
```

Các document cũ được giữ nguyên để đối chiếu. Bản chuyển tạo:

- `public_rooms/{id}`: từng phòng với ảnh, giá, diện tích, tiện ích, trạng thái công bố/trống; không có CCCD, hợp đồng hoặc lịch sử thu tiền.
- `rental_properties/{id}`: thông tin công khai và cấu hình phòng.
- `rental_records/{id}`: từng hợp đồng, hóa đơn, thanh toán, thành viên, sự cố, chỉ số, lịch xem, hội thoại và tin nhắn riêng. Có `ownerUid`, `tenantIds` để truy vấn và kiểm tra quyền.
- `users/{uid}`: vai trò do người quản trị cấp; client không được sửa.
- `user_state/{uid}`, `management/{uid}`, `support_tickets/{id}`: tùy chọn cá nhân, quản lý và hỗ trợ.

Nếu **không có** `provisioning.json`, bước export chỉ tạo danh mục công khai để bản demo tìm phòng từng trang; không tạo tài khoản hay cấp quyền.

## 3. Kiểm tra rồi áp dụng Rules

Build/chạy chế độ Firebase thật:

```powershell
flutter run -d emulator-5554 --dart-define=USE_FIREBASE_AUTH=true
```

Đăng nhập bằng từng tài khoản vừa tạo. Sau khi đã chuyển dữ liệu và xác nhận đăng nhập được, vào Firestore → Rules, thay nội dung bằng [firestore.rules](../firestore.rules) rồi Publish. Hoặc dùng Firebase CLI đã đăng nhập của chính m:

```powershell
firebase deploy --only firestore:rules --project doantro-caf4b
```

Không publish Rules này trước khi hoàn tất tài khoản và dữ liệu: Rules sẽ chặn toàn bộ `app_documents` cũ, nên bản APK demo không còn đồng bộ được. Chỉ bản chạy với `USE_FIREBASE_AUTH=true` dùng các collection mới.

## Kiểm tra cục bộ

[tool/firestore_rules_test.cjs](../tool/firestore_rules_test.cjs) thử quyền trên project giả `demo-quanlytro`: người lạ không đọc dữ liệu riêng, người thuê không đọc người khác hoặc tự duyệt thanh toán, chủ trọ không sửa nhà của chủ khác, tài khoản bị khóa không truy cập, client không tự nâng vai trò. Tin nhắn là document riêng và không được viết lại lịch sử.

Trong phiên triển khai này, Firebase Emulator được chạy từ JAR chính thức trong `.dart_tool/firebase_emulators/`, với `jdk.net.unixdomain.tmpdir` và `java.io.tmpdir` trỏ vào `.dart_tool/jtmp` để tương thích Windows. Sau khi emulator mở cổng 8080:

```powershell
node tool/firestore_rules_test.cjs
```

Dependency Node cho kiểm tra nằm trong `.dart_tool/firebase_tools/`; không phải dependency của APK. `flutter analyze` và `flutter test` kiểm tra phần Flutter.

## Giới hạn hiện tại

Tìm trọ dùng cursor Firestore và đọc lô 32 document, lấy tối đa 8 kết quả/trang. Giá/diện tích được sắp xếp phía server. Tìm chuỗi con và phối hợp nhiều bộ lọc được kiểm tra trong từng lô; tìm rất hẹp có thể phải quét nhiều lô. Đây không phải công cụ tìm kiếm toàn văn.

Chế độ Firebase thật yêu cầu kết nối khi đăng nhập và tải dữ liệu riêng. Không dùng dữ liệu cục bộ của tài khoản khác hoặc quay về mật khẩu demo khi server từ chối. Listener nhận thay đổi theo quyền và cập nhật store tại chỗ, giữ nhà đang mở; không thay bản chỉnh sửa chưa lưu. Mỗi lần lưu là một transaction (tối đa 400 document), hợp đồng/hóa đơn/thanh toán kiểm tra phiên bản nghiêm ngặt; các trường độc lập khác có thể hợp nhất. Khi cùng sửa một trường, tải lại dữ liệu trước khi sửa tiếp. Ảnh quá lớn cần được thu nhỏ, không nhét file nhiều MB vào document Firestore.

Tài liệu đối chiếu: [Firebase Email/Password](https://firebase.google.com/docs/auth/flutter/password-auth), [Rules và Authentication](https://firebase.google.com/docs/rules/rules-and-auth), [Firestore cursor](https://firebase.google.com/docs/firestore/query-data/query-cursors), [Google Maps URL](https://developers.google.com/maps/documentation/urls/get-started).
