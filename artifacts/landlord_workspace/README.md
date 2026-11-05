# Giao diện Chủ trọ

Bốn màn hình sử dụng cùng nền xanh, phần chào tài khoản, thẻ kính, màu nhấn và thanh điều hướng với trang Nhà trọ.

| Màn hình | Ảnh xem trước | Nội dung |
| --- | --- | --- |
| Tổng quan | [Đầu trang](dashboard.png), [Sự cố và phòng còn nợ](dashboard_reports.png) | Bảng thống kê chuyển từ Nhà trọ; lối tắt; hồ sơ xác minh; sự cố; phòng chưa đóng tiền; tiến độ thu tiền và công cụ quản lý. |
| Thu chi | [Đầu trang](finance.png), [Danh sách phòng](finance_rooms.png) | Bộ chọn tháng, tìm phòng/người thuê, lọc trạng thái, phân trang, xem hóa đơn, lập và hủy hóa đơn. |
| Tin nhắn | [Danh sách trò chuyện](messages.png) | Tìm người thuê/phòng/nội dung, lọc chưa đọc, bắt đầu trò chuyện, đọc và gửi tin nhắn. |
| Chi tiết phòng | [Trang chi tiết](room_details.png) | Appbar quay lại và thông báo; thư viện ảnh; thông tin phòng/nhà trọ; hợp đồng/thành viên; liên hệ; thanh toán; sự cố; sửa/xóa phòng. |
| Chi tiết nhà trọ | [Đầu trang](property_details.png), [Danh sách phòng](property_rooms.png), [Loại phòng](property_room_types.png) | Khung mới với appbar, ảnh/địa chỉ, hai tab xanh; bỏ các banner cũ và thanh công cụ nổi; toàn trang cuộn liền mạch. |

Bản sửa chi tiết nhà trọ: `flutter analyze --no-pub` không có vấn đề; 49 kiểm thử liên quan đạt. Đã kiểm tra hai tab ở chiều rộng 320/390/844/1280 px, xoay ngang, chế độ sáng/tối, giữ bộ lọc khi đổi tab và quay lại bằng nút Android. Các thao tác thêm/sửa/xóa phòng và loại phòng, chọn ảnh, tìm kiếm, sơ đồ tầng, ghi điện nước và sao chép danh sách được giữ lại. Xuất ảnh bằng `flutter test --no-pub tool/capture_property_detail_test.dart`; ảnh dùng dữ liệu kiểm thử 15 phòng/1 loại phòng.

Thu chi hiển thị đỏ khi còn dư nợ và xanh lá khi hóa đơn của tháng đã đóng đủ. Thanh toán một phần vẫn là còn nợ. Phòng trống và phòng chưa lập hóa đơn có trạng thái riêng. Hóa đơn đã hủy và hóa đơn của tháng tương lai không được tính vào dư nợ của tháng đang xem; nợ chưa trả từ tháng trước vẫn được tính. Dữ liệu và màu thẻ cập nhật sau khi chủ trọ duyệt thanh toán.

Các ảnh sử dụng bộ dữ liệu kiểm thử tại `test/support/landlord_redesign_fixture.dart` để thể hiện đủ trạng thái; dữ liệu tài khoản thật được giữ nguyên. Bộ kiểm thử không kết nối Firebase trực tiếp.

Kiểm tra hoàn tất:

- `flutter analyze --no-pub`: không có vấn đề.
- 50 kiểm thử liên quan đều đạt, bao gồm bố cục 320/390/1280 px, sáng/tối, trạng thái công nợ, cập nhật sau duyệt thanh toán, lập hóa đơn đúng phòng, gửi/đọc tin nhắn, sửa mã phòng, appbar thông báo, quay lại, thanh điều hướng và drawer.
- Xuất lại ảnh: `flutter test --no-pub tool/capture_landlord_workspace_test.dart`.
