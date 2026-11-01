# SQLite và dữ liệu mẫu

Cập nhật ngày 31/10/2026. Tài liệu này mô tả bản SQLite hiện tại; các mô tả “chỉ lưu trong phiên”, “một nhà trọ” hoặc “chưa có đăng nhập/database” trong tài liệu cũ đã được thay thế.

## Quy mô ban đầu

| Nhà trọ | Số tầng | Phòng/tầng | Tổng phòng | Loại phòng |
|---|---:|---:|---:|---:|
| Mây House | 5 | 8 | 40 | 4 |
| Nhà Nâu | 3 | 6 | 18 | 3 |
| Ban Mai Residence | 6 | 10 | 60 | 4 |
| Thanh Xuân House | 4 | 8 | 32 | 3 |
| An Nhiên Home | 8 | 12 | 96 | 4 |
| Gác Mộc | 3 | 7 | 21 | 3 |
| Cỏ May Studio | 5 | 9 | 45 | 4 |
| Bình Yên House | 4 | 6 | 24 | 3 |
| Nhà Xinh Thảo Điền | 7 | 10 | 70 | 4 |
| Tân Bình Home | 6 | 8 | 48 | 3 |
| **Tổng** | | | **454** | **35** |

Đây là dữ liệu giả lập để thử nghiệp vụ, địa chỉ và thông tin người thuê không phải thông tin xác minh thực tế. Mỗi nhà có bộ dữ liệu riêng cho phòng, bảng giá, hợp đồng, người ở, hóa đơn, thanh toán và chỉ số. Phòng đang thuê lấy giá từ hợp đồng; phòng trống lấy giá loại phòng.

Người thuê mẫu là Minh Anh, mã `tenant-demo`, hợp đồng tại Mây House/phòng A.302. Tài khoản chủ trọ mẫu quản lý toàn bộ danh mục. Hồ sơ người thuê khác dùng để quản lý hợp đồng và thống kê, chưa phải các tài khoản có thể đăng nhập riêng.

## Lưu trữ

- `lib/data/local_database.dart`: ranh giới `RentalRepository` và bản SQLite `SqliteRentalRepository`.
- `lib/data/app_persistence.dart`: khôi phục trước khi mở giao diện, theo dõi thay đổi, xếp hàng ghi tuần tự, lưu trong transaction, báo lỗi và cho thử lưu lại.
- `lib/pages/landlord/rental_portfolio.dart`: danh mục nhiều nhà trọ, dữ liệu mẫu, codec nghiệp vụ, CRUD phòng và chuẩn bị chỉ số theo kỳ.
- Database phiên bản 1: `quanlytro_v1.db` trong thư mục database riêng do hệ điều hành cấp cho ứng dụng.
- Bảng `app_documents(id, payload, updated_at)` chứa các bản chụp JSON có kiểu: danh mục/nghiệp vụ, hội thoại, lịch xem, tài khoản, nhân viên, yêu thích, quản trị và thông báo theo nhà. Đây là SQLite dạng document, chưa phải lược đồ quan hệ từng bảng nghiệp vụ.
- Ảnh nằm trong bản chụp cục bộ. Dữ liệu được ghi sau thao tác và chờ hoàn thành khi ứng dụng chuyển nền. Lỗi lưu hiển thị trên giao diện; ứng dụng không tự xóa database hoặc ghi đè bằng dữ liệu mẫu khi đọc lỗi.
- Đóng/mở ứng dụng giữ dữ liệu; gỡ ứng dụng/xóa dữ liệu ứng dụng sẽ xóa database theo cơ chế của hệ điều hành.

## Kiểm tra thủ công

1. Đăng nhập `landlord@tro.local` / `Tro@2026`, mở Nhà trọ: danh mục có 10 nhà và thống kê 454 phòng.
2. Chọn An Nhiên Home từ bộ chọn trên cùng: 8 tầng, 96 phòng. Lọc theo tầng/trạng thái và sửa diện tích hoặc loại phòng của một phòng trống.
3. Chuyển Nhà Nâu: bảng giá và phòng không bị thay đổi theo nhà vừa sửa. Khởi động lại, đăng nhập và kiểm tra thay đổi vẫn còn.
4. Thêm nhà mới, nhập số tầng/phòng mỗi tầng, kiểm tra phòng tạo tự động. Không có người thuê hoặc hóa đơn giả được thêm vào nhà mới. Có thể xóa nhà mới khi chưa phát sinh hợp đồng.
5. Chọn Mây House, sửa giá Studio hoặc ảnh nhà. Đăng xuất rồi vào `tenant@tro.local`: Khám phá lấy giá/ảnh mới; hóa đơn và điều khoản hợp đồng cũ giữ dữ liệu đã thỏa thuận.
6. Trong tài khoản người thuê, đề nghị thêm thành viên. Đăng nhập chủ trọ để duyệt hoặc từ chối; kiểm tra sức chứa và kết quả phía người thuê.
7. Gửi tin nhắn, mở để đọc, thêm yêu thích, đặt lịch hoặc gửi thanh toán. Khởi động lại để kiểm tra lịch sử và trạng thái.
8. Đăng nhập `admin@tro.local`, ẩn tin một nhà trọ. Người thuê không còn thấy phòng của nhà đó trong Khám phá. Bật lại để hiển thị.
9. Gửi hỗ trợ từ trang Trợ giúp; tài khoản admin phản hồi; tài khoản đã gửi đọc được phản hồi. Kiểm tra nhật ký quản trị.
10. Đổi mật khẩu trong Cài đặt; đăng xuất, thử mật khẩu cũ và mới. Khởi động lại để kiểm tra mật khẩu mới vẫn có hiệu lực.

## Kiểm tra tự động

Bộ kiểm thử có các luồng cũ, kiểm tra quy mô/liên kết dữ liệu, cách ly hai nhà, chống trùng mã phòng, bảo vệ loại phòng đang dùng, đóng/mở tệp SQLite, khôi phục ảnh/thanh toán/thành viên/chỉ số, tự lưu và khôi phục trạng thái toàn ứng dụng, mật khẩu/phân quyền tài khoản cục bộ. Giao diện danh mục và quản trị được kiểm tra ở chiều rộng 390 và 1280 px.

## Giai đoạn sau

Firebase Authentication/Firestore, quy tắc bảo mật, đồng bộ nhiều thiết bị và upload ảnh Supabase **chưa triển khai**, theo phạm vi hiện tại. Có thể bổ sung repository cloud tại ranh giới lưu trữ hiện có; không có khóa Firebase/Supabase hoặc yêu cầu cấu hình cloud trong bản này.

Ứng dụng chưa tích hợp đối soát ngân hàng, push notification hoặc định vị GPS. Thanh toán được chủ trọ đối chiếu thủ công; thông báo và trao đổi dùng chung dữ liệu trên thiết bị; tìm phòng lọc theo địa chỉ đã lưu. Xác minh nhà trọ của admin là trạng thái quản lý nội bộ.
