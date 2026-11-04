# Chuông thông báo và trang Trợ giúp người thuê

## Appbar

`TenantNotificationButton` hiển thị nút chuông nền trắng và chấm đỏ khi tài khoản hiện tại còn thông báo nhà trọ chưa đọc. Nút theo dõi `AnnouncementStore` để cập nhật sau khi người dùng đọc thông báo; tùy chọn thông báo ứng dụng không xóa trạng thái thông báo nhà trọ.

`TenantNavigationBar` dùng nút chuông cho Yêu thích, Cài đặt, Hồ sơ cá nhân, Đổi mật khẩu, Thông báo ứng dụng, Báo cáo sự cố, Lịch xem phòng, Thành viên phòng và Trợ giúp. Các trang con mở qua `TenantSubpageScaffold` cũng được đồng bộ. Ở khung điều hướng chính, nút chọn mục Thông báo trong khung hiện tại; ở trang mở riêng, nút đẩy trang Thông báo lên và cho phép quay lại. Trang Thông báo được mở riêng không hiển thị thêm nút chuông để tránh mở nhiều bản sao.

## Trợ giúp

Trang người thuê dùng ảnh đầu trang riêng, tìm kiếm có dấu/không dấu, hướng dẫn nhanh, bộ lọc chủ đề, câu hỏi thường gặp có thể mở rộng, sao chép mẫu mô tả và lối vào yêu cầu hỗ trợ. Danh sách yêu cầu và form gửi yêu cầu dùng cùng thẻ, màu, ô nhập và nút với các trang người thuê khác. Luồng gửi yêu cầu và phản hồi dùng `AdminStore` hiện có.

Các ảnh xem trước được lưu ở `.dart_tool/previews/tenant_help.png`, `tenant_support_tickets.png` và `tenant_support_form.png`.

## Ảnh đầu trang

Tệp `assets/images/tenant_help_hero.png` được tạo bằng công cụ `image_gen` tích hợp (built-in), nền không trong suốt, đã lưu trong workspace và khai báo trong `pubspec.yaml`.

Prompt:

Use case: stylized-concept. Asset type: wide 16:9 hero background for Help and Support pages in a Vietnamese rental housing mobile app. A refined soft photorealistic 3D still life grouped in the RIGHT 40%: a miniature ivory house with sage roof, an emerald-green support headset surrounding an ivory speech bubble with a simple raised green question-mark symbol, a small ivory guidebook with emerald binding and a small leafy plant on a pale mint rounded pedestal. Calm friendly practical help theme. Subjects centered x=78%, y=53%, kept inside middle vertical 60% so the artwork survives a right-aligned 400x180 mobile header crop. LEFT 58% and upper 15% clean pale ivory-mint empty negative space for title and subtitle drawn separately in Flutter. Soft daylight, gentle shadows, tactile ceramic-like surfaces, ivory, sage and emerald palette matching polished rental finance app artwork. No words, letters, numbers, logos, watermark, actual people, or UI chrome. The single question-mark symbol is allowed. Landscape 1672x941 or similar.
