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
- Ảnh mẫu gồm 101 WebP đi kèm app (khoảng 2,21 MiB), trong đó 83 ảnh lấy từ 28 album qua endpoint JSON Nhà Tốt/Chợ Tốt. Loại phòng ở từng nhà dùng các album khác nhau, 2–3 ảnh/album. Ảnh tự chọn và album đã xóa hết được giữ nguyên. [Nguồn ảnh và cách cập nhật qua API](docs/ROOM_PHOTO_SOURCES.md).
- Tìm trọ hỗ trợ sắp xếp giá/diện tích tăng giảm, lọc diện tích nhập số và tiện ích; giữ bộ lọc khi quay lại. Màn chi tiết phòng/nhà trọ có nút mở Google Maps và sao chép URL tìm địa chỉ, không cần API key.
- Phân trang: Tìm trọ 8 phòng/trang, quản lý phòng 12 phòng/trang, hóa đơn và hợp đồng 10 mục/trang, người thuê 10 nhóm phòng hoặc yêu cầu/trang. Đổi tìm kiếm/bộ lọc sẽ về trang đầu. Chat AI đã gỡ; tin nhắn chủ trọ/người thuê vẫn giữ.
- Thông tin, ảnh, tin nhắn, trạng thái đọc, yêu thích, thiết lập và nghiệp vụ được giữ khi khởi động lại. Dữ liệu mẫu chỉ tạo khi chưa có cơ sở dữ liệu.

Chi tiết quy mô, kiến trúc lưu trữ và cách kiểm tra: [SQLite và dữ liệu mẫu](docs/SQLITE_VA_DU_LIEU_MAU.md).

Đăng nhập Firebase và Rules theo vai trò: [các bước chuyển dữ liệu, cấp UID và bật chế độ thật](docs/FIREBASE_CLOUD.md). Chưa publish Rules khóa dữ liệu cũ khi tài khoản thật chưa được chuẩn bị.

## Kiểm tra và đóng gói

```sh
flutter analyze
flutter test
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Bổ sung dữ liệu minh họa cho Firestore hiện có (thanh toán, sự cố, ở ghép, tin nhắn và yêu cầu hỗ trợ):

```sh
python tool/update_demo_firestore.py
python tool/update_demo_firestore.py --apply
```

Lệnh đầu chỉ tạo bản xem trước. Lệnh `--apply` sao lưu vào `.dart_tool/demo_data/`, chỉ cập nhật ba document `portfolio`, `conversations`, `admin`, giữ nguyên tài khoản và dữ liệu cũ. Ghi nguyên tử kèm điều kiện phiên bản; nếu dữ liệu bị thay đổi trong lúc chuẩn bị, Firestore từ chối toàn bộ lần ghi. Nên đóng app trước khi chạy để tránh ứng dụng đang mở lưu lại bản dữ liệu cũ. Không commit các bản sao lưu chứa dữ liệu cá nhân.

Đặc tả nghiệp vụ mục tiêu: [Thiết kế nghiệp vụ](docs/THIET_KE_NGHIEP_VU.md). Tài liệu đồng bộ phiên bản trước: [Đồng bộ chủ trọ/người thuê](docs/DONG_BO_CHU_TRO_NGUOI_THUE.md).
