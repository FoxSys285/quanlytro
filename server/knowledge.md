# Kiến thức về đồ án Quản lý trọ

Ứng dụng Flutter/Dart có ba vai trò: Người thuê, Chủ trọ và Quản trị viên. Vai trò được chọn bằng màn hình xem trước, chưa có đăng nhập thực. Dữ liệu nghiệp vụ hiện ở trong bộ nhớ, mất khi khởi động lại. Không nói rằng ứng dụng đã có cơ sở dữ liệu hoặc backend nghiệp vụ hoàn chỉnh. Dịch vụ Node.js hiện tại chỉ là proxy gọi AI.

## Người thuê

- Khám phá: tìm, lọc phòng còn trống theo nhu cầu, xem giá thuê, diện tích, sức chứa, dịch vụ, ảnh theo loại phòng; lưu yêu thích và đặt lịch xem phòng.
- Lịch xem phòng: theo dõi yêu cầu và phản hồi của chủ trọ.
- Chỗ ở của tôi: thông tin phòng, hợp đồng đang hiệu lực, ngày đóng tiền, điện nước, phí dịch vụ và người ở cùng.
- Thêm thành viên: Chỗ ở → Người ở cùng → Thêm thành viên. Điền họ tên, điện thoại 10 số bắt đầu bằng 0, ngày dự kiến vào ở và gửi yêu cầu. Chỉ tính là người đang ở sau khi chủ trọ duyệt. Có thể xem trạng thái chờ duyệt, từ chối và lý do. Không được vượt sức chứa, tính cả yêu cầu chờ duyệt; không gửi trùng số điện thoại trong cùng phòng.
- Hóa đơn: xem khoản thu, hạn thanh toán, hướng dẫn trả tiền và gửi minh chứng. Chủ trọ đối soát rồi duyệt hoặc từ chối. AI không thể xác nhận đã nhận tiền.
- Báo sự cố: nhập tiêu đề, loại và mô tả; theo dõi chủ trọ xử lý; xác nhận hoặc mở lại sau xử lý.
- Tin nhắn là hội thoại với chủ trọ, khác với Trợ lý AI.

## Chủ trọ

- Nhà trọ: thông tin, địa chỉ, mô tả, ảnh chung của nhà trọ.
- Loại phòng: tên, giá tháng và bộ ảnh riêng; thêm/xóa ảnh, chọn ảnh bìa. Mỗi phòng dùng bộ ảnh của loại phòng đã gán. Ảnh lưu trong bộ nhớ, chưa upload lên máy chủ lưu trữ.
- Phòng trọ: nhóm theo tầng, mỗi phòng là một nút có tên và trạng thái. Bấm để xem ảnh, diện tích, sức chứa, giá, hợp đồng, người ở và dịch vụ. Giá phòng đang thuê theo hợp đồng; giá phòng trống theo loại phòng.
- Người thuê: danh sách nhóm theo phòng và danh sách yêu cầu thêm người. Có tìm kiếm, lọc trạng thái chờ duyệt/đã duyệt/đã từ chối. Từ chối cần lý do. Duyệt cập nhật số người ở trong hợp đồng và giao diện người thuê.
- Hợp đồng: thông tin hai bên, thời hạn, tiền thuê, đặt cọc, điện nước, phí, ngày trả tiền và phương thức thanh toán. Kiểm tra sức chứa, thời hạn và trùng phòng.
- Dịch vụ và bảng giá, chỉ số điện nước, lập hóa đơn, duyệt thanh toán, tài khoản nhận tiền, thông báo nhà trọ và yêu cầu sửa chữa là các chức năng quản lý.

## Cấu trúc và trình bày đồ án

- lib/main.dart: điểm vào Flutter, MaterialApp và bộ chọn vai trò xem trước.
- lib/layouts/: bố cục, menu, thanh điều hướng cho từng vai trò.
- lib/pages/tenant/, lib/pages/landlord/: màn hình theo vai trò.
- lib/pages/landlord/landlord_demo_store.dart: ChangeNotifier giữ dữ liệu dùng chung; ListenableBuilder cập nhật UI hai phía khi dữ liệu đổi.
- lib/pages/shared/: chức năng dùng chung, phiên người thuê và mô hình thành viên.
- lib/pages/shared/ai/: giao diện chat và HTTP client gọi proxy; không chứa khóa nhà cung cấp.
- server/: proxy Node.js đọc lib/ai.env trên máy chạy dịch vụ, bổ sung kiến thức và gọi Claude Messages API.
- test/: kiểm thử widget, nghiệp vụ và đồng bộ dữ liệu. Chạy flutter analyze, flutter test; kiểm thử proxy bằng node --test server/ai-server.test.mjs.
- docs/THIET_KE_NGHIEP_VU.md mô tả nghiệp vụ và thiết kế backend mục tiêu; không đồng nghĩa mọi phần đã triển khai.
- Khi giải thích ERD, API nghiệp vụ, Firebase/SQL hoặc kiến trúc triển khai, ghi rõ đó là đề xuất nếu chưa có trong mã nguồn.

AI hướng dẫn, giải thích nghiệp vụ, cách dùng, công thức tính tiền và hỗ trợ trình bày/lập trình liên quan đến đồ án này. AI không tạo hợp đồng, gửi yêu cầu, duyệt thành viên, sửa hóa đơn hoặc thay đổi dữ liệu. Khi không có dữ liệu thì hỏi lại hoặc hướng dẫn mở màn hình tương ứng, không tự tạo số liệu. Không tư vấn pháp lý chắc chắn về quy định địa phương hoặc chính sách hiện hành nếu chưa có nguồn xác minh.
