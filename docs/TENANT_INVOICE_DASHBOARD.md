# Trang Hóa đơn và Thanh toán

Giao diện theo ảnh tham chiếu: thanh tiêu đề và chuông thông báo, ảnh nhà và hóa đơn trên nền xanh nhạt, hóa đơn hiện tại, bốn ô thao tác, ba giao dịch gần nhất, banner và thanh điều hướng bốn mục.

- Tiền cần trả lấy từ `invoice.remaining`, kỳ và hạn lấy từ hóa đơn thật; ảnh lấy theo loại phòng trong kho dữ liệu.
- Ưu tiên hóa đơn còn phải trả đến hạn trước, có danh sách chọn khi còn nhiều hóa đơn. Hóa đơn đã hủy hoặc đã trả hết không còn xuất hiện như khoản cần trả.
- Nút thanh toán mở luồng gửi thanh toán hiện có; khi có yêu cầu chờ chủ trọ xác nhận, nút bị khóa để tránh gửi trùng. Duyệt một phần cập nhật số dư và cho phép trả phần còn lại.
- Các ô thao tác mở chi tiết hóa đơn, phương thức tiền mặt/chuyển khoản và VietQR, lịch sử đầy đủ, hoặc trang hỗ trợ. Lịch sử có thêm mục tất cả hóa đơn để xem cả hóa đơn đã trả hoặc đã hủy.
- QR trong phương thức thanh toán dùng tài khoản nhận tiền hiện tại của chủ trọ, số tiền còn phải trả và mã hóa đơn; dùng lại `VietQrService`, không cần API key. QR được tải khi mở phương thức thanh toán.
- Các giao dịch hiển thị đúng trạng thái chờ xác nhận, thành công hoặc bị từ chối. Không thêm giao dịch nạp ví hoặc ngày thanh toán giả. Hóa đơn nhập cũ có số tiền đã xác nhận nhưng không có bản ghi giao dịch hiển thị theo kỳ thanh toán.
- Đi từ Chỗ ở của tôi đến hóa đơn trong cùng khung điều hướng; thanh dưới có Khám phá, Chỗ ở của tôi, Tin nhắn và Thông báo. Hợp đồng thuê được mở từ Chỗ ở của tôi hoặc menu. Các chấm và số chưa đọc lấy từ dữ liệu thật.

## Ảnh đầu trang

`assets/images/tenant_invoices_hero.png` được tạo bằng công cụ `image_gen` tích hợp (built-in), nền không trong suốt; đã khai báo trong `pubspec.yaml`.

Prompt:

Use case: stylized-concept
Asset type: wide landscape 16:9 background for the Bills and Payments header of a Vietnamese rental housing mobile app.
Primary request: beautiful soft realistic 3D mobile finance illustration on the RIGHT 45 percent: a small white two-story rental house with a teal gray pitched roof, a leafy green tree on each side, a slightly tilted upright ivory invoice sheet in front of the house with a small emerald house symbol and subtle blue-gray horizontal lines, and a circular emerald green badge with a white check mark in front of the invoice. Ground is a simple small curved green garden platform. Match a refined mint-green, ivory and emerald mobile rental payment dashboard.
Composition: all meaningful objects grouped at x=77%, y=57%, with safe margins so the grouping survives a wide 400x155 mobile hero crop aligned center-right. LEFT 52 percent is very light ivory-mint empty negative space for title and subtitle added in code. Upper area has subtle large translucent pale mint curved waves. Lower background transitions to clean pale mint-white. Wide composition, 1672x941 or similar. Image should be crisp and richly modeled, softly rounded forms, gentle shadows, soft natural daylight.
Constraints: no words, no letters, no numbers, no typography, no watermark, no people, no app chrome, no QR code. Invoice has only the small generic house symbol and horizontal lines.
