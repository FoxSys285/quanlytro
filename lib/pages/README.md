# Cấu trúc màn hình

Thư mục được chia theo vai trò và feature. Các thư mục feature dùng snake_case; tạo widget màn hình trong feature tương ứng khi bắt đầu triển khai. Auth, hồ sơ, thông báo và trợ giúp dùng chung được đặt dưới shared.

```text
pages/
  shared/          rental (định danh/thành viên), viewings, conversations, announcements
  tenant/          tenant_page_router.dart, tenant_ui.dart
    announcements/  tenant_announcements_page.dart (+ components/, models/)
    members/        tenant_members_page.dart (+ components/, models/)
    conversations/ tenant_danhsachtinnhan_page.dart, tenant_tinnhan_page.dart
      components/   message bubble
      models/       conversation message
    discovery/      tenant_discovery_page.dart, tenant_favorites_page.dart,
                    tenant_favorites_store.dart
      components/   room card/artwork/details, filter sheet
      models/       room listing and preview data
    invoices/       tenant_invoices_page.dart, tenant_invoice_detail_page.dart
      components/   invoice card, charge rows, payment instructions
    incidents/      tenant_baosuco_page.dart
    leases/         tenant_home_page.dart
      components/   lease metric, overview card, member row
    viewings/       tenant_viewings_page.dart (+ components/)
  landlord/      landlord_page_router.dart, landlord_ui.dart
    dashboard/      landlord_tongquan_page.dart
    services/       landlord_dichvubanggia_page.dart (+ models/)
    meter_readings/ landlord_chisodiennuoc_page.dart (+ models/)
    members/        landlord_nguoithue_page.dart
    conversations/  landlord_danhsachtinnhan_page.dart, landlord_tinnhan_page.dart (+ models/)
    incidents/      landlord_yeucausuachua_page.dart (+ models/)
    properties/     landlord_properties_page.dart (+ components/, models/, services/)
    room_types/     landlord_room_types_page.dart (+ models/)
    rooms/          landlord_rooms_page.dart (+ components/, models/)
    viewings/       landlord_viewings_page.dart (+ components/, data/, models/)
    announcements/  landlord_announcements_page.dart
    leases/         landlord_leases_page.dart
    billing/        landlord_billing_page.dart
    payments/       landlord_payments_page.dart
    payment_accounts/ landlord_payment_accounts_page.dart
    staff/          landlord_staff_page.dart, landlord_staff_store.dart
  admin/         dashboard, users, property_verification, moderation,
                 support, audit_logs, settings
```

Các màn hình người thuê đang được triển khai trong `tenant/`; tiện ích giao diện dùng chung của nhóm màn hình nằm trong `tenant_ui.dart`.

Thông báo, thành viên, hợp đồng, hóa đơn, thanh toán, sự cố và hội thoại dùng dữ liệu chung giữa Chủ trọ và Người thuê. `LandlordDemoStore` giữ model nghiệp vụ cho giao diện; `AppPersistence` và `ScopedFirestoreRentalRepository` mã hóa/lưu Firestore, còn Rules giới hạn theo UID chủ trọ hoặc `tenantId`. `shared/announcements/` lưu thông báo/người nhận/trạng thái đọc, `shared/conversations/` lưu hội thoại chung. `tenant-demo` là ID dữ liệu chuyển mẫu; tài khoản thật lấy `tenantId` từ hồ sơ Firebase.

Phạm vi từng màn hình và luồng nghiệp vụ được mô tả trong `docs/THIET_KE_NGHIEP_VU.md`.

Vai trò chủ trọ hiện dùng dữ liệu mẫu của một nhà trọ Mây House trong `landlord/landlord_demo_store.dart`:

- `landlord/properties/`: thông tin nhà trọ và form chỉnh sửa, chọn ảnh từ thiết bị bằng `image_picker`, xem trước trước khi lưu.
- `landlord/room_types/`: danh sách loại phòng, giá thuê theo tháng và thêm/sửa/xóa.
- `landlord/rooms/`: danh sách phòng của nhà trọ hiện tại, lọc tầng/trạng thái và tìm mã phòng, loại phòng, người thuê. Giá phòng có hợp đồng lấy từ hợp đồng; phòng trống lấy giá của loại phòng.
- `landlord/announcements/`: gửi đến tất cả phòng, một tầng hoặc nhiều phòng được chọn trong phiên; Người thuê đúng phạm vi nhận cùng thông báo. Hộp nhận được lấy từ dữ liệu nghiệp vụ hiện tại.
- `landlord/viewings/`: người đặt lịch, ngày giờ, nút xác nhận/hủy và mở cuộc trò chuyện.
- `tenant/viewings/`: các phòng người thuê đã đặt lịch với trạng thái đang chờ xác nhận, đã xác nhận, đã hủy.

Hai trang lịch dùng chung `shared/viewings/viewing_store.dart`. Chủ trọ chỉ thấy lịch của Mây House (`may`); Người thuê chỉ thấy lịch của ID phiên mình. Trạng thái đổi bên Chủ trọ hiển thị bên Người thuê. Hội thoại từ lịch xem dùng cùng danh sách tin ở hai vai trò. Thay ID phiên và các store bằng phiên đăng nhập/repository khi có backend.

Khi Firebase Auth bật, thay đổi được lưu vào Firestore qua `AppPersistence`; snapshot listener tải thay đổi từ thiết bị khác. SQLite/cache chỉ dùng theo UID ở nền tảng native. Dữ liệu đăng nhập thật không được thay bằng dữ liệu mẫu khi tải cloud lỗi.

Hồ sơ và tùy chọn thông báo dùng chung các trang trong `shared/profile/` và `shared/notifications/`, với dữ liệu riêng cho từng role ở `AccountStore`. Tắt thông báo thay đổi tùy chọn và biểu tượng chuông; lịch sử thông báo vẫn được giữ. Push notification và quyền thông báo hệ điều hành chưa được kết nối. Hồ sơ liên hệ đồng bộ vào dữ liệu nhà trọ/người thuê đang được cấp quyền. `landlord/staff/` lưu danh sách liên hệ nhân viên trong dữ liệu quản lý của chủ trọ.

Danh mục mẫu chỉ dùng trong chế độ demo/migration. Phòng thật và tin khám phá lấy từ document nhà/phòng; tenant yêu thích và lịch xem nối bằng ID phòng ổn định.

Chi tiết đối chiếu trường, quy tắc giữ lịch sử và các bước kiểm tra nằm tại `docs/DONG_BO_CHU_TRO_NGUOI_THUE.md`.
