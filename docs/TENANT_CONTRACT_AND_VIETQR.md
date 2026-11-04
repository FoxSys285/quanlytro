# Hợp đồng thuê và mã thanh toán

Trang hợp đồng gồm ảnh đầu trang, thời hạn còn lại tính từ ngày hiện tại, phòng và ảnh lấy từ loại phòng thực tế, các bên tham gia, tiến độ theo ngày thuê; tiếp đó là thông tin hợp đồng, bên cho thuê, bên thuê, đơn giá dịch vụ và phương thức thanh toán. Không có nút tải hợp đồng hoặc xem chi tiết.

## VietQR

- `lib/pages/shared/payments/vietqr_service.dart` tra `GET https://api.vietqr.io/v2/banks`, đối chiếu chính xác tên thường gọi, tên pháp lý, mã viết tắt hoặc BIN; bỏ dấu, khoảng trắng và không phân biệt hoa thường. Không đoán gần đúng ngân hàng. Danh sách được lưu trong bộ nhớ tối đa một ngày, gộp các yêu cầu đồng thời.
- Mã thanh toán lấy từ `https://img.vietqr.io/image/<BIN>-<ACCOUNT>-qr_only.svg`, thêm `addInfo` đã chuẩn hóa. Dùng SVG theo hướng dẫn hiện tại của VietQR, không phụ thuộc API `/v2/generate` dự kiến ngừng hỗ trợ từ 01/01/2027.
- `TenantBankQr` tự tải lại khi ngân hàng, số tài khoản, nội dung hoặc số tiền thay đổi. QR cũ được ẩn trong lúc tải QR cho tài khoản mới. Có thông báo lỗi, nút thử lại và sao chép STK/nội dung; thời gian chờ mỗi yêu cầu tối đa 12 giây.
- Tài khoản nhận tiền là `defaultPaymentAccount` hiện tại của chủ trọ, cùng nguồn với thanh toán hóa đơn. Nếu khác thông tin lúc ký, trang vẫn hiển thị riêng tài khoản ghi trong hợp đồng. Khi chưa có tài khoản nhận tiền hiện tại, không tạo QR từ thông tin cũ.
- Trên trang hợp đồng, QR không chứa số tiền cố định. Người thuê nhập số tiền theo hóa đơn. Thành phần hỗ trợ `amount` khi dùng trong một luồng có số tiền xác định.
- Tên chủ tài khoản hiển thị do chủ trọ cung cấp, không phải kết quả xác minh người thụ hưởng. Không gọi API tra tên chủ tài khoản, không tự đánh dấu hóa đơn đã thanh toán và không cần lưu API key trong ứng dụng. Ngân hàng xác nhận người thụ hưởng trong ứng dụng của người trả.
- Ngân hàng/BIN, số tài khoản và nội dung chuyển khoản được gửi đến dịch vụ tạo ảnh VietQR khi tải QR. Không gửi CCCD hoặc địa chỉ của hai bên.

Nguồn chính thức: [API ngân hàng](https://www.vietqr.io/api-bank), [Quick Link](https://www.vietqr.io/qr-dong), [thông báo thay đổi 14/10/2026](https://www.vietqr.io/thong-bao-cap-nhat).

## Ảnh đầu trang

Tệp `assets/images/tenant_contract_hero.png`, tạo bằng công cụ `image_gen` tích hợp (built-in), nền không trong suốt; đã khai báo trong `pubspec.yaml`.

Prompt:

Use case: stylized-concept
Asset type: wide 16:9 header background for a Vietnamese rental contract mobile app screen.
Primary request: polished soft 3D illustration, on the RIGHT HALF a large upright ivory rental agreement sheet with subtle gray horizontal lines and a small abstract signature, a miniature white cozy house with warm gray pitched roof and green window trim, a glossy emerald green shield with a white check mark in the foreground, two small leafy plants on a simple pale mint rounded pedestal. Calm trustworthy housing-contract theme inspired by refined friendly mobile banking illustrations.
Composition: wide landscape 1672x941 or similar, all meaningful objects centered around x=75%, y=55%, grouped tightly enough to survive a right-aligned crop of a wide 400x220 mobile header. LEFT 55% empty pale ivory-to-mint gradient for app title rendered in Flutter, upper 15% airy. Main objects fully within the frame, comfortable margins.
Lighting and palette: soft diffused daylight, ivory paper, emerald green shield, mint background, gentle ambient shadows, subtle depth, tasteful smooth ceramic-like surfaces, clean premium rendering.
Constraints: no words, no letters, no numbers, no typography, no logos, no watermark, no people, no app chrome. Gray lines and abstract signature on paper only.
