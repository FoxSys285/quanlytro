# Đăng nhập email, Google và số điện thoại

## Chức năng trong ứng dụng

- Đăng ký email: cả chủ trọ và người thuê đều phải nhập họ tên, email, số di động Việt Nam, mật khẩu và đồng ý điều khoản. Số điện thoại được chuẩn hóa thành `+84…` trong `users/{uid}`.
- Đăng nhập: nhập email và mật khẩu; hoặc nhập số điện thoại để chuyển sang OTP. Hai nút Google và Số điện thoại đã nối với Firebase.
- Tài khoản Google hoặc số điện thoại mới phải hoàn thiện họ tên, số điện thoại và chọn chủ trọ/người thuê. Không có lựa chọn đăng ký admin.
- Tài khoản email đã có: đăng nhập bằng email, vào **Cài đặt → Liên kết số điện thoại**, xác minh OTP một lần. Firebase liên kết số vào cùng UID; những lần sau có thể đăng nhập bằng email hoặc OTP.
- Số điện thoại chỉ nhập trong biểu mẫu là thông tin liên hệ, chưa phải số đăng nhập đã xác minh. Không tìm tài khoản theo số liên hệ để tránh nhận nhầm tài khoản.
- OTP có kiểm tra định dạng, xử lý mã sai/hết hạn, giới hạn gửi lại 60 giây và thông báo lỗi mạng/hạn mức. Android và web dùng API Firebase tương ứng. Windows không hỗ trợ các luồng Google/SMS này trong bản hiện tại.

## Trạng thái Firebase đã kiểm tra

Dự án: `tropremium-d14ac`.

- Đã bật Phone, cho phép SMS đến `VN`, giữ nguyên trạng thái thanh toán.
- Đã đăng ký SHA-1 và SHA-256 của chứng chỉ debug Android đang dùng trên máy này. Bản phát hành có chứng chỉ khác cần đăng ký thêm dấu vân tay tương ứng.
- Đã bổ sung số còn thiếu cho **682 hồ sơ chủ trọ** và **680 nhà trọ**. Đọc lại xác nhận dữ liệu khác được giữ nguyên. Báo cáo: `artifacts/BAO_CAO_BO_SUNG_SO_DIEN_THOAI.json`.
- Số sinh ngẫu nhiên chỉ là thông tin liên hệ mẫu (`phoneIsSynthetic: true`, `phoneVerified: false`). Không gắn các số này vào Firebase Authentication; nút gọi ở chi tiết phòng không gọi số mẫu.
- Bản sao lưu và kế hoạch cập nhật nằm trong `.local-backups/landlord-phone-backfill/`, được Git bỏ qua. Không chạy lại trình xuất danh mục cũ để thay thế dữ liệu vừa bổ sung.

## Các bước cần hoàn tất bên ngoài code

1. **Firestore Rules:** thay đổi trong `firestore.rules` cho phép lưu số liên hệ khi tạo hồ sơ và cho phép người dùng cập nhật số đăng nhập khi token Firebase đã xác minh đúng số đó. Không cho đổi vai trò, trạng thái khóa hoặc hồ sơ người khác. Đã kiểm tra trên emulator. Triển khai thật đang chờ người dùng xác nhận vì hệ thống duyệt tự động đã chặn lệnh triển khai thay đổi quyền truy cập.

   Sau khi có xác nhận:

   ```powershell
   firebase deploy --only firestore:rules --project tropremium-d14ac --non-interactive
   ```

2. **Google:** mở [Firebase Authentication](https://console.firebase.google.com/project/tropremium-d14ac/authentication/providers), bật Google và chọn email hỗ trợ. Dự án hiện chưa có cấu hình OAuth Google. Sau khi bật, tải lại `google-services.json` cho Android và thay vào `android/app/google-services.json`. File phải có OAuth client loại `3` (web client). Build lại app. Xem [hướng dẫn Firebase](https://firebase.google.com/docs/auth/flutter/federated-auth) và [cấu hình Android của google_sign_in](https://pub.dev/packages/google_sign_in_android).

3. **SMS thật:** trạng thái đọc được là `billingEnabled: false`. Firebase hiện yêu cầu gói Blaze để gửi SMS xác thực thật. Chủ dự án cần tự quyết định bật thanh toán; tác vụ này không nâng gói và không gửi SMS. Có thể thử luồng bằng số kiểm thử khai báo trong Firebase Console trước. Xem [hạn mức chính thức](https://firebase.google.com/docs/auth/limits) và [kiểm thử Phone Authentication](https://firebase.google.com/docs/auth/flutter/phone-auth#testing).

4. **Kiểm tra trên thiết bị:** chọn tài khoản Google thật; đăng ký email có số điện thoại; liên kết OTP; đăng xuất; đăng nhập bằng chính số đó; xác nhận UID và dữ liệu nhà trọ/hợp đồng vẫn giữ nguyên. Chưa thực hiện được bước tương tác này do Google OAuth và thanh toán SMS còn thiếu.

## Kiểm tra trong mã nguồn

```powershell
flutter analyze lib/data/account_provider.dart lib/data/firebase_account_gateway.dart lib/data/local_auth.dart lib/data/auth_validation.dart lib/pages/shared/auth lib/pages/shared/settings/account_settings_page.dart lib/pages/shared/profile/account_store.dart lib/pages/landlord/properties
flutter test test/provider_auth_test.dart test/login_ui_test.dart test/auth_flows_test.dart test/firebase_account_flows_test.dart test/cloud_auth_boundary_test.dart test/local_auth_test.dart test/account_staff_test.dart test/tenant_identity_sync_test.dart test/tenant_room_details_test.dart
python -m unittest discover -s test -p test_landlord_phone_backfill.py
```

Kiểm tra Firestore Rules riêng bằng emulator cổng 8086, dự án `demo-auth`, sau đó chạy `python tool/auth_rules_check.py`. Script này chỉ gửi yêu cầu đến `127.0.0.1`, kiểm tra đăng ký hai vai trò, hồ sơ phone-only, chống giả mạo số xác minh, chống nâng quyền và chống đọc/sửa hồ sơ người khác.

Một test có sẵn ngoài luồng đăng nhập, `property_crud_test.dart` / `Cloud login cannot substitute seeded properties when Firebase fails`, đang thất bại vì kỳ vọng `initializeAsync()` ném lỗi trong khi triển khai hiện tại chạy đồng bộ nền. Tác vụ này không chỉnh luồng đồng bộ đó.
