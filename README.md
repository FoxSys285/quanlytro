# TroPremium

Ứng dụng Flutter quản lý nhà trọ với ba vai trò: Chủ trọ, Người thuê và Quản trị viên. **Mặc định dùng Firebase Authentication + Firestore theo vai trò**; SQLite là cache riêng theo UID trên thiết bị. Bản web đọc Firestore trực tiếp.

## Chạy ứng dụng

```sh
flutter pub get
flutter run
```

SQLite hỗ trợ Android, iOS và máy tính Windows/Linux/macOS. Trình duyệt dùng Firebase, không mở SQLite.

## Tài khoản và phân quyền

Tài khoản thật được tạo trong Firebase Authentication; quyền lấy từ `users/{uid}` trên server. Người đăng ký chọn Chủ trọ hoặc Người thuê; yêu cầu xuất hiện trong **Quản trị viên → Người dùng & tài khoản → Yêu cầu**. Chỉ backend mới cấp role. Hồ sơ Người thuê mới nhận mã ngẫu nhiên gồm 8 chữ in hoa và số để Chủ trọ liên kết khi lập hợp đồng. Chủ trọ chưa có nhà sẽ được hướng dẫn tạo hồ sơ đầu tiên; dữ liệu được lưu Firestore theo UID/owner/tenant. Xem [thiết lập Firebase](docs/FIREBASE_CLOUD.md) và [kết quả kiểm tra 3 role](docs/ROLE_SYNC_AUDIT.md).

Thông tin dưới đây chỉ áp dụng bản cũ chạy chủ động với `--dart-define=USE_FIREBASE_AUTH=false`, cần dữ liệu SQLite có sẵn. Không dùng bản này sau khi Rules đã khóa collection cũ.

| Vai trò | Email | Mật khẩu ban đầu |
|---|---|---|
| Chủ trọ | landlord@tro.local | Tro@2026 |
| Người thuê | tenant@tro.local | Tro@2026 |
| Quản trị viên | admin@tro.local | Tro@2026 |

Chọn vai trò trên màn hình đăng nhập để điền tài khoản mẫu. Có thể đổi mật khẩu trong Cài đặt. Mật khẩu lưu bằng PBKDF2-HMAC-SHA256 với salt riêng; phiên đăng nhập kết thúc khi đóng ứng dụng. Đây là tài khoản cục bộ cho bản SQLite, chưa phải Firebase Authentication.

## Dữ liệu và chức năng

Dữ liệu Firebase phục vụ đồ án gồm **680 nhà trọ, 15.034 phòng, 2.338 loại phòng và 680 chủ trọ**, phân bố đúng 20 nhà ở mỗi tỉnh/thành trong danh mục 34 tỉnh/thành hiện hành. Nhà/chủ/phòng được tự tạo theo yêu cầu; ảnh minh họa lấy từ Internet. Xem [cấu trúc bộ dữ liệu và cách nhập Firebase](docs/VIETNAM_34_CATALOGUE.md). Ứng dụng tải dữ liệu đã được cấp quyền, không tự tạo nhà, hợp đồng hay tài khoản khi đăng nhập.

- Chủ trọ: chuyển nhà đang quản lý; thêm/sửa nhà và phòng; quản lý loại phòng, dịch vụ, hợp đồng, thành viên, chỉ số điện nước, hóa đơn, thanh toán, tài khoản nhận tiền, sự cố, nhân viên và thông báo.
- Người thuê mẫu Minh Anh: tìm/lọc phòng theo khu vực, giá, diện tích, điện nước; yêu thích và đặt lịch; xem hợp đồng/hóa đơn; gửi thanh toán; đề nghị thêm thành viên; báo và xác nhận sự cố; nhắn tin và gửi hỗ trợ.
- Quản trị viên: thống kê, duyệt yêu cầu đăng ký, khóa/mở tài khoản, xem hồ sơ người thuê, xác minh nhà trọ, ẩn/hiện tin đăng, phản hồi hỗ trợ, xem nhật ký quản trị và bật/tắt tiếp nhận lịch xem phòng.
- Loại phòng có album tối đa 12 ảnh: chọn nhiều ảnh từ thư viện, đặt ảnh bìa hoặc xóa ảnh trong **Loại phòng → Chỉnh sửa**. Các phòng cùng loại tự dùng chung album ở danh sách phòng của chủ trọ, mục khám phá và chi tiết của người thuê. Đổi loại phòng sẽ đổi album tương ứng; giá hợp đồng vẫn giữ nguyên.
- Bộ 680 nhà sử dụng 550 URL ảnh minh họa khác nhau, phân theo loại phòng, từ kho 198 album Internet đã kiểm tra. Sheet `NguonAnh` và `artifacts/NGUON_ANH_680_NHA_TRO.json` lưu nguồn. Các phòng cùng loại dùng chung album. App còn có 101 WebP đi kèm cho bộ dữ liệu cục bộ cũ. [Nguồn ảnh và cách cập nhật qua API](docs/ROOM_PHOTO_SOURCES.md).
- Tìm trọ hỗ trợ sắp xếp giá/diện tích tăng giảm, lọc diện tích nhập số và tiện ích; giữ bộ lọc khi quay lại. Màn chi tiết phòng/nhà trọ có nút mở Google Maps và sao chép URL tìm địa chỉ, không cần API key.
- Phân trang: Tìm trọ 8 phòng/trang, quản lý phòng 12 phòng/trang, hóa đơn và hợp đồng 10 mục/trang, người thuê 10 nhóm phòng hoặc yêu cầu/trang. Đổi tìm kiếm/bộ lọc sẽ về trang đầu. Chat AI đã gỡ; tin nhắn chủ trọ/người thuê vẫn giữ.
- Thông tin, ảnh, tin nhắn, trạng thái đọc, yêu thích, thiết lập và nghiệp vụ được giữ khi khởi động lại. Dữ liệu mẫu chỉ tạo khi chưa có cơ sở dữ liệu.

Chi tiết quy mô, kiến trúc lưu trữ và cách kiểm tra: [SQLite và dữ liệu mẫu](docs/SQLITE_VA_DU_LIEU_MAU.md).

Đăng nhập Firebase và Rules theo vai trò: [các bước chuyển dữ liệu và cấp UID](docs/FIREBASE_CLOUD.md). Mẫu thu thập nhà/phòng và lệnh kiểm tra/import: [hướng dẫn Excel](docs/DATA_IMPORT.md).

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
