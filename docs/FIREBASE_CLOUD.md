# Chuyển bản demo sang Firebase Authentication

Mặc định dùng Firebase thật: xác thực trước khi đọc dữ liệu riêng, vai trò lấy từ `users/{uid}` trên server; không đăng nhập bằng tài khoản demo khi Firebase từ chối. SQLite được tách theo UID; web dùng Firestore trực tiếp. Không tự tạo hay nâng vai trò từ ứng dụng. Cờ `--dart-define=USE_FIREBASE_AUTH=false` chỉ dành đối chiếu bản cũ trước khi khóa collection legacy.

## Project hiện tại

Project đích là `tropremium-d14ac`, đặt làm mặc định trong `.firebaserc`. FlutterFire đã đăng ký app Android (`com.example.quanlytro`), Web và Windows; cấu hình Android nằm ở `android/app/google-services.json`, cấu hình Dart ở `lib/firebase_options.dart`. Repo hiện chưa có target iOS/macOS.

Project này bắt đầu trống. Bật Email/Password Authentication và tạo Firestore database trong Console. Storage có thể cấu hình sau. Tạo tài khoản admin đầu tiên trong Authentication, rồi tạo `users/{uid}` với `email`, `displayName`, `role: admin`, `disabled: false`; sau đó deploy Firestore Rules:

```powershell
firebase login
firebase use tropremium-d14ac
firebase deploy --only firestore:rules --project tropremium-d14ac
```

Để cấu hình lại app trên máy khác, chạy `flutterfire configure --project=tropremium-d14ac --platforms=android,web,windows --yes`. Vì project mới được chọn để bắt đầu sạch, bỏ qua các lệnh Python nhập bộ dữ liệu legacy ở phần 2.

## 1. Bật và tạo tài khoản

Mở [Authentication của project](https://console.firebase.google.com/project/tropremium-d14ac/authentication/providers) → Get started (nếu có) → Email/Password → bật công tắc đầu tiên → Save. Không cần bật Email link.

Tài khoản đầu tiên có quyền admin phải được tạo thủ công bằng Firebase Authentication và hồ sơ `users/{uid}` trong Firebase Console/Admin SDK (`role: admin`, `disabled: false`). Đây là điểm tin cậy ban đầu; ứng dụng không cho phép người dùng tự cấp quyền admin.

Sau khi deploy Rules, người dùng có thể tự đăng ký bằng email và chọn vai trò Người thuê; tích checkbox **Đăng ký với tài khoản chủ trọ** để đăng ký vai trò Chủ trọ. Firestore Rules chỉ cho tài khoản tự tạo hồ sơ của chính mình với một trong hai vai trò này; client không thể tự cấp quyền admin. Hồ sơ người thuê nhận mã `tenant-{uid}` để chia sẻ với Chủ trọ khi lập hợp đồng. Không cần admin duyệt tài khoản; admin vẫn duyệt xác minh nhà trọ trước khi tin đăng được công khai. Chủ trọ chưa có nhà được mở màn hình tạo hồ sơ đầu tiên; nhà và phòng mới lưu theo `ownerUid` Firebase.

Chỉ cần deploy Firestore Rules để bật đăng ký và đồng bộ hồ sơ. Nếu bật Firebase Storage sau này, cấu hình bucket và Storage Rules riêng; xem [Firebase Storage setup](https://firebase.google.com/docs/storage/flutter/start) và [Firebase pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans).

```powershell
firebase deploy --only firestore:rules --project tropremium-d14ac
```

Ảnh nhà và loại phòng được đọc công khai để hiển thị tin đăng. Ảnh minh chứng thanh toán được giới hạn cho admin, chủ nhà và người thuê có hóa đơn liên quan. Mỗi ảnh tối đa 10 MB; Firestore chỉ lưu URL/thông tin tham chiếu, còn tệp nằm trong Storage.

Để chuyển bộ dữ liệu mẫu có sẵn, vẫn dùng UID admin/landlord/tenant trong `.dart_tool/demo_data/provisioning.json` như bên dưới. Sao chép **UID**, không gửi mật khẩu vào chat hay đưa vào mã nguồn.

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
firebase deploy --only firestore:rules --project tropremium-d14ac
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
