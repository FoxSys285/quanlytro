# Trợ lý AI cho đồ án và nhà trọ

## Chạy trên máy phát triển

Yêu cầu Node.js 22 trở lên và Flutter đã cài các dependency (`flutter pub get`). Proxy chỉ dùng thư viện chuẩn Node.js, không cần `npm install`.

1. Giữ cấu hình riêng tại `lib/ai.env`, theo mẫu `server/ai.env.example`:

   ```dotenv
   claude_key=YOUR_API_KEY
   base=https://YOUR_PROVIDER/v1
   AI_MODEL=claude-haiku-4-5-20251001
   ```

   Hai tên `claude_key` và `base` tương thích với file hiện có. `AI_MODEL` là tùy chọn. Proxy cũng nhận biến môi trường `ANTHROPIC_API_KEY`, `AI_BASE_URL`, `AI_MODEL`, `AI_PORT`, `AI_HOST`, `AI_ENV_FILE`. Biến môi trường ưu tiên hơn file. Đường dẫn mặc định không phụ thuộc thư mục đang chạy lệnh.

2. Từ thư mục dự án, mở terminal chạy:

   ```powershell
   node server/ai-server.mjs
   ```

   Proxy mặc định ở `http://127.0.0.1:8765`; `GET /health` kiểm tra dịch vụ đang chạy, không kiểm tra khóa với nhà cung cấp.

3. Chạy Android emulator:

   ```powershell
   flutter run
   ```

   Android mặc định gọi `http://10.0.2.2:8765`, địa chỉ máy phát triển nhìn từ Android emulator chuẩn. Windows và Flutter web mặc định gọi `http://127.0.0.1:8765`.

4. Nếu dùng điện thoại Android cắm USB:

   ```powershell
   adb reverse tcp:8765 tcp:8765
   flutter run --dart-define=AI_PROXY_URL=http://127.0.0.1:8765
   ```

   Nếu `adb` chưa có trong PATH, dùng `platform-tools/adb` trong Android SDK. `AI_PROXY_URL` là URL gốc, không thêm `/api/chat`. Thay URL bằng endpoint HTTPS của proxy khi triển khai.

5. Mở biểu tượng ✨ trên thanh công cụ hoặc menu → **Trợ lý AI**. Nhập câu hỏi hoặc chọn gợi ý. Nút **Cuộc trò chuyện mới** xóa lịch sử của vai trò hiện tại. Lịch sử từng vai trò giữ trong phiên chạy, mất khi đóng ứng dụng; không trộn với tin nhắn chủ trọ/người thuê.

## Phạm vi

- Hỏi cách sử dụng màn hình, nghiệp vụ quản lý trọ, kiến trúc và cách trình bày đồ án, tính tiền điện nước và kinh nghiệm thuê phòng.
- Kiến thức dự án nằm tại `server/knowledge.md`; cập nhật file này khi thay đổi nghiệp vụ.
- App gửi bối cảnh tối thiểu theo vai trò: phòng trống và giá, số lượng; người thuê có thêm thông tin tiền thuê/phí và số dư hóa đơn của chính phiên người thuê. Không tự gửi CCCD, số điện thoại, tài khoản ngân hàng, hình ảnh hoặc hợp đồng của người thuê khác. Nội dung người dùng tự gõ sẽ được chuyển đến nhà cung cấp AI trong `base`.
- AI chỉ trả lời và hướng dẫn. Không có công cụ sửa dữ liệu, duyệt thanh toán/thành viên hoặc gửi tin nhắn.
- Khi lỗi mạng, hết hạn mức hoặc khóa không hợp lệ, giao diện có thông báo và nút thử lại, giữ lại câu hỏi.

## Cấu hình và triển khai

`lib/ai.env` được `.gitignore` bỏ qua và **không** khai báo trong Flutter assets. Chỉ proxy đọc khóa. Không đặt khóa vào `--dart-define`, mã Dart hoặc Git. Debug Android cho phép HTTP để kết nối proxy cục bộ; bản release dùng proxy HTTPS.

Proxy này phục vụ bản demo trên máy cá nhân, mặc định chỉ lắng nghe loopback; app hiện chưa có đăng nhập. Trước khi mở ra Internet, cần bổ sung xác thực phiên/người dùng, giới hạn lượt gọi theo tài khoản, HTTPS và danh sách origin cho domain web triển khai. Vai trò từ client hiện chỉ chọn bối cảnh hướng dẫn, không phải cơ chế phân quyền backend.

Proxy gọi [Claude Messages API](https://platform.claude.com/docs/en/api/messages/create) qua địa chỉ `base`, giữ tối đa 19 lượt tin nhắn gần nhất trong mỗi request, giới hạn thời gian và độ dài để tránh gửi lịch sử không giới hạn. Model mặc định có thể đổi bằng `AI_MODEL` để phù hợp tài khoản nhà cung cấp.

## Kiểm thử

```powershell
node --test server/ai-server.test.mjs
flutter analyze
flutter test
```

Kiểm thử tự động dùng HTTP giả lập, không tiêu tốn lượt gọi AI thật. Kiểm tra kết nối thật cần chạy proxy và gửi câu hỏi từ ứng dụng.
