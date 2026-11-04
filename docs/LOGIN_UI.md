# Giao diện đăng nhập

Màn hình: `lib/pages/shared/auth/login_page.dart`. Hình trang trí được vẽ bằng Flutter trong `login_artwork.dart`; nhận diện thương hiệu dùng `AppLogo` chung của ứng dụng. Bố cục dọc trên điện thoại, hai cột từ 860 px, có thể cuộn khi mở bàn phím hoặc tăng cỡ chữ.

Đăng nhập email và tài khoản mẫu vẫn sử dụng `LocalAuth`. Đã bỏ Apple, giữ Google và số điện thoại ở hai cột bằng nhau (hai phương thức này vẫn chưa kết nối xác thực). Chữ “Hoặc đăng nhập bằng” được căn giữa theo chiều ngang với hai đường kẻ đối xứng, kể cả khi phóng to chữ.

## Đăng ký và khôi phục mật khẩu

- `register_page.dart`: email, mật khẩu, xác nhận mật khẩu và đồng ý điều khoản; kiểm tra email, mật khẩu tối thiểu 8 ký tự gồm chữ và số; thông báo thành công/lỗi; quay lại đăng nhập với email đã điền.
- `forgot_password_page.dart`: nhập email, gửi liên kết, thông báo kiểm tra hộp thư, gửi lại sau 60 giây hoặc đổi email.
- `auth_flow_widgets.dart`: bố cục, trường nhập, nút và thông báo dùng chung, cùng tông xanh với màn hình đăng nhập.
- Trong chế độ `USE_FIREBASE_AUTH=true`, tạo tài khoản bằng Firebase Authentication và gửi email khôi phục thật. Sau đăng ký, phiên Firebase được đăng xuất; quản trị viên phải cấp `users/{uid}` và liên kết dữ liệu theo [hướng dẫn Firebase](FIREBASE_CLOUD.md) trước khi tài khoản đăng nhập được. Ứng dụng không tự cấp vai trò hoặc thay đổi Firestore Rules.
- Bản dùng thử không tạo tài khoản email hoặc gửi thư; biểu mẫu hiển thị rõ giới hạn này và không báo thành công giả.
- Google và số điện thoại tiếp tục hiển thị thông báo chưa hỗ trợ.

## Ảnh đầu trang

- Tệp: `assets/images/login_hero.png`.
- Tạo bằng công cụ imagegen tích hợp, không dùng CLI.
- Prompt cuối cùng:

```text
Use case: photorealistic-natural. Asset type: background photograph for the hero of a Vietnamese rental management app login. Primary request: a beautiful contemporary white three-storey apartment villa with glass balconies, dark slender window frames, lush sunlit green trees and garden, blue sky with soft white clouds, close to an architectural real estate photograph. Composition: landscape 3:2, villa occupying the right half, seen from slightly below at a three-quarter angle, left half is bright airy pale mint sky and soft foliage with open negative space for text that will be added by the app. Crisp attractive white facade, natural morning sunlight, welcoming fresh peaceful mood. Colors: white, light sky blue, emerald foliage, very pale mint. No text, no letters, no logos, no watermark, no UI, no people. Whole building visible with roof near top right and garden at bottom.
```

## Kiểm tra

```sh
flutter analyze
flutter test test/login_ui_test.dart test/auth_flows_test.dart test/firebase_account_flows_test.dart test/cloud_auth_boundary_test.dart test/local_auth_test.dart
```

Kiểm thử gồm căn giữa, chuyển trang, đăng nhập/đăng xuất; biểu mẫu khi chữ lớn và bàn phím mở; xác nhận mật khẩu và điều khoản; trạng thái lỗi/thành công; giới hạn gửi lại; adapter Firebase dùng đối tượng giả (không gửi thư thật hay tạo tài khoản thật trong kiểm thử).
