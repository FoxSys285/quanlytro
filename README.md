# Quản lý trọ

Ứng dụng Flutter quản lý nhà trọ với ba vai trò: Chủ trọ, Người thuê và Quản trị viên. Phiên bản hiện tại dùng **SQLite trên thiết bị**, chưa kết nối Firebase hoặc Supabase.

## Chạy ứng dụng

```sh
flutter pub get
flutter run
```

SQLite hỗ trợ Android, iOS và máy tính Windows/Linux/macOS. Bản hiện tại không chạy cơ sở dữ liệu trên trình duyệt.

## Tài khoản mẫu

| Vai trò | Email | Mật khẩu ban đầu |
|---|---|---|
| Chủ trọ | landlord@tro.local | Tro@2026 |
| Người thuê | tenant@tro.local | Tro@2026 |
| Quản trị viên | admin@tro.local | Tro@2026 |

Chọn vai trò trên màn hình đăng nhập để điền tài khoản mẫu. Có thể đổi mật khẩu trong Cài đặt. Mật khẩu lưu bằng PBKDF2-HMAC-SHA256 với salt riêng; phiên đăng nhập kết thúc khi đóng ứng dụng. Đây là tài khoản cục bộ cho bản SQLite, chưa phải Firebase Authentication.

## Dữ liệu và chức năng

Lần mở đầu tạo **10 nhà trọ, 454 phòng**, mỗi nhà có 3–4 loại phòng, 3–8 tầng, 6–12 phòng mỗi tầng. Có sẵn hợp đồng hiệu lực, người thuê, hóa đơn, công nợ, thanh toán chờ duyệt, điện nước, thông báo và lịch xem phòng.

- Chủ trọ: chuyển nhà đang quản lý; thêm/sửa nhà và phòng; quản lý loại phòng, dịch vụ, hợp đồng, thành viên, chỉ số điện nước, hóa đơn, thanh toán, tài khoản nhận tiền, sự cố, nhân viên và thông báo.
- Người thuê mẫu Minh Anh: tìm/lọc phòng theo khu vực, giá, diện tích, điện nước; yêu thích và đặt lịch; xem hợp đồng/hóa đơn; gửi thanh toán; đề nghị thêm thành viên; báo và xác nhận sự cố; nhắn tin và gửi hỗ trợ.
- Quản trị viên: thống kê, xem hồ sơ người thuê, khóa/mở tài khoản cục bộ, đánh dấu xác minh nhà trọ, ẩn/hiện tin đăng, phản hồi hỗ trợ, xem nhật ký quản trị và bật/tắt tiếp nhận lịch xem phòng.
- Loại phòng có album tối đa 12 ảnh: chọn nhiều ảnh từ thư viện, đặt ảnh bìa hoặc xóa ảnh trong **Loại phòng → Chỉnh sửa**. Các phòng cùng loại tự dùng chung album ở danh sách phòng của chủ trọ, mục khám phá và chi tiết của người thuê. Đổi loại phòng sẽ đổi album tương ứng; giá hợp đồng vẫn giữ nguyên.
- Ảnh nhà trọ, album loại phòng và minh chứng thanh toán chọn từ máy được lưu cục bộ. Không tải lên máy chủ. Ảnh tham khảo của các loại phòng được tải online từ URL ảnh gốc tìm trên web; cần có mạng để tải. Album mẫu cũ tự chuyển sang URL mới, album người dùng tự thêm và album đã xóa hết ảnh được giữ nguyên. [Nguồn ảnh](docs/ROOM_PHOTO_SOURCES.md).
- Thông tin, ảnh, tin nhắn, trạng thái đọc, yêu thích, thiết lập và nghiệp vụ được giữ khi khởi động lại. Dữ liệu mẫu chỉ tạo khi chưa có cơ sở dữ liệu.

Chi tiết quy mô, kiến trúc lưu trữ và cách kiểm tra: [SQLite và dữ liệu mẫu](docs/SQLITE_VA_DU_LIEU_MAU.md).

## Kiểm tra và đóng gói

```sh
flutter analyze
flutter test
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Đặc tả nghiệp vụ mục tiêu: [Thiết kế nghiệp vụ](docs/THIET_KE_NGHIEP_VU.md). Tài liệu đồng bộ phiên bản trước: [Đồng bộ chủ trọ/người thuê](docs/DONG_BO_CHU_TRO_NGUOI_THUE.md).
