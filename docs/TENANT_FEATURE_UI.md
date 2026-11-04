# Đồng bộ giao diện tiện ích người thuê

Các trang Yêu thích, Cài đặt, Hồ sơ cá nhân, Đổi mật khẩu, Thông báo ứng dụng, Báo cáo sự cố, Lịch xem phòng và Thành viên phòng dùng cùng phong cách nền mint, ảnh đầu trang 3D, chữ xanh đậm, nội dung trắng bo góc và form có điểm nhấn xanh.

- `TenantFeatureFrame` dùng bố cục co giãn theo chiều rộng và cỡ chữ. Mỗi nhóm có ảnh riêng, các trang con Cài đặt dùng ảnh tài khoản chung.
- `TenantNavigationBar` đồng bộ nút quay lại và tiêu đề cho trang con, cả khi truy cập từ menu và khi mở bằng điều hướng.
- Các form chỉnh hồ sơ, tạo sự cố, đặt lịch và thêm thành viên có tiêu đề minh họa bằng icon, ô nhập bo góc, điều hướng bàn phím, lỗi xác thực và vùng nội dung cuộn được. Quy tắc lưu dữ liệu và chờ chủ trọ duyệt được giữ nguyên.
- Form đặt lịch đổi cặp ngày/giờ thành hai hàng trên màn hình nhỏ và giữ hàng ngang khi đủ rộng.
- Yêu thích đăng ký theo dõi `TenantFavoritesStore.changes`; thao tác xóa tất cả phát thông báo thay đổi để đồng bộ số lượng và lưu trạng thái.
- Các thay đổi ở màn hình tài khoản dùng nhánh người thuê. Các form hồ sơ của vai trò khác giữ cách hiển thị hiện có.

## Ảnh xem trước

Được tạo bằng kiểm thử widget ở `.dart_tool/previews/`:

- `tenant_favorites.png`
- `tenant_settings.png`
- `tenant_profile.png`
- `tenant_password.png`
- `tenant_notification_settings.png`
- `tenant_incidents.png`
- `tenant_viewings.png`
- `tenant_members.png`
- `tenant_profile_form.png`
- `tenant_incident_form.png`
- `tenant_viewing_form.png`
- `tenant_member_form.png`

## Ảnh đầu trang và prompt

Tạo bằng công cụ `image_gen` tích hợp (built-in), nền không trong suốt. Các ảnh đã được lưu trong workspace và khai báo trong `pubspec.yaml`.

### assets/images/tenant_favorites_hero.png

Use case: stylized-concept. Asset type: wide 16:9 hero background for saved favorite rental homes in a Vietnamese mobile app. Soft premium photorealistic 3D illustration: a miniature ivory house with muted sage roof, a large sculptural emerald-green heart, and two slightly offset ivory property cards bearing tiny generic green house silhouettes and gray lines, a small plant on a pale mint rounded pedestal. All objects grouped tightly in the RIGHT 40%, centered x=78%, y=53%, contained within the middle 60% of height so the art survives a right-aligned 400x160 banner crop. LEFT 58% and upper 15% uncluttered pale ivory-mint gradient space for title and subtitle drawn separately. Soft daylight, friendly gentle shadows, tactile ceramic surfaces, natural green plant, emerald and ivory harmonious with rental finance illustrations. No words, letters, numbers, logos, watermark, people, or UI. Landscape 1672x941 or similar.

### assets/images/tenant_settings_hero.png

Use case: stylized-concept. Asset type: wide 16:9 hero background for Settings and personal account pages in a Vietnamese rental mobile app. A refined soft photorealistic 3D still life grouped in the RIGHT 40%: an ivory rounded settings gear with emerald center, a small ivory profile card with a green generic person silhouette, an emerald shield bearing a white check, and a small leafy plant on a pale mint pedestal. Quiet pale ivory-mint background with very subtle curved light shapes. LEFT 58% and top 15% clean empty negative space for text drawn separately by Flutter. All objects concentrated at x=78%, y=53%, within the middle vertical 60%, so they remain visible in a 400x160 mobile banner cropped center-right. Soft daylight, natural gentle shadows, mint, ivory, emerald palette matching contemporary rental finance illustrations. Polished friendly trustworthy visual. No letters, text, words, numbers, logos, watermark, UI chrome, or people. 1672x941 landscape or similar.

### assets/images/tenant_incidents_hero.png

Use case: stylized-concept. Asset type: wide 16:9 hero background for reporting maintenance incidents in a Vietnamese rental housing mobile app. Refined soft photorealistic 3D still life grouped in the RIGHT 40%: a compact ivory rental house with sage roof, an emerald green tool case with a white wrench symbol, an ivory clipboard with subtle gray lines and a small green check, and a leafy plant on a pale mint pedestal. Convey practical home maintenance and helpful support, calm and friendly. All subjects centered x=78%, y=52%, inside middle 60% height so they survive a right-aligned 400x160 mobile banner crop. LEFT 58% and top 15% clean pale ivory-mint empty negative space for separately-rendered app copy. Soft daylight, gentle shadows, ivory, sage and emerald palette, tactile ceramic-like surfaces, polished 3D rendering matching rental payment app artwork. No letters, words, text, numbers, logo, watermark, UI chrome, or people. 1672x941 landscape or similar.

### assets/images/tenant_viewings_hero.png

Use case: stylized-concept. Asset type: wide 16:9 header background for rental room viewing appointments in a Vietnamese housing mobile app. Premium soft realistic 3D still life on the RIGHT 40%: a chunky ivory desk calendar with simple blank grid squares and emerald binding rings, a small emerald location pin beside a miniature ivory house with a sage roof, and a small round ivory clock with simple green hands on a pale mint pedestal. Small leafy plant. No digits on clock or calendar. All objects grouped centered x=78%, y=53%, within middle vertical 60% to survive a right-aligned 400x160 banner crop. LEFT 58% and top 15% empty ivory-mint negative space for title and subtitle drawn in code. Natural soft daylight, mint, sage, ivory and emerald green, ceramic-like surfaces, gentle shadows, polished inviting home-rental app illustration. No words, text, letters, numbers, watermark, logos, people, or UI. 1672x941 landscape or similar.

### assets/images/tenant_members_hero.png

Use case: stylized-concept. Asset type: wide 16:9 hero background for room members and housemates in a Vietnamese rental mobile app. Premium friendly soft photorealistic 3D still life on RIGHT 40%: three abstract rounded green-and-ivory person bust icons, no realistic faces or clothing, grouped beside a miniature ivory house with a sage roof and a small profile card with a green person symbol, a little leafy plant on a pale mint pedestal. Convey shared living, community and managing room members. Subjects centered x=78%, y=53%, contained within middle 60% height so they survive a right-aligned 400x160 mobile header crop. LEFT 58% and upper 15% clean pale ivory-mint empty negative space for title and subtitle drawn separately by the app. Soft daylight and shadows, ivory, sage and emerald palette, tactile ceramic surfaces matching refined housing finance app artwork. No text, letters, numbers, watermark, logos, actual people, or app chrome. Landscape 1672x941 or similar.
