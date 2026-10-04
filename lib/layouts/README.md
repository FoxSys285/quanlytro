# Khung điều hướng theo vai trò

- `role_layout.dart` chứa khung dùng chung: AppBar, Drawer, bottom navigation, menu tài khoản và vùng nội dung.
- `tenant_layout.dart`, `landlord_layout.dart`, `admin_layout.dart` khai báo màu, thông tin header và các mục điều hướng riêng cho từng role.
- Mỗi layout nhận `pageBuilder(context, destination)`. Nối ID destination với màn hình trong `lib/pages/` tại đây khi nhóm triển khai nội dung.
- `RoleLayoutPreview` trong `lib/main.dart` chỉ để xem thử ba layout. Thay nó bằng điều hướng sau đăng nhập khi auth được làm.

Các layout không chứa nghiệp vụ hoặc dữ liệu giả cho từng màn hình. Mặc định chỉ hiện vùng giữ chỗ để nhóm tự xây phần body.
