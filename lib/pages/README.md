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
    (chưa làm)      reports, staff
  admin/         dashboard, users, property_verification, moderation,
                 support, audit_logs, settings
```

Các màn hình người thuê đang được triển khai trong `tenant/`; tiện ích giao diện dùng chung của nhóm màn hình nằm trong `tenant_ui.dart`.

Thông báo, thành viên, hợp đồng, hóa đơn, thanh toán, sự cố và hội thoại dùng dữ liệu chung giữa Chủ trọ và Người thuê. `LandlordDemoStore` là nguồn dữ liệu nghiệp vụ hiện có; `shared/announcements/` lưu thông báo/người nhận/trạng thái đọc, `shared/conversations/` lưu hội thoại chung. Mẫu Người thuê hiện tại là Minh Anh (`tenant-demo`), liên kết với hợp đồng HD-2026-0302 qua ID, không lọc cố định theo tên hay phòng.

Phạm vi từng màn hình và luồng nghiệp vụ được mô tả trong `docs/THIET_KE_NGHIEP_VU.md`.

Vai trò chủ trọ hiện dùng dữ liệu mẫu của một nhà trọ Mây House trong `landlord/landlord_demo_store.dart`:

- `landlord/properties/`: thông tin nhà trọ và form chỉnh sửa, chọn ảnh từ thiết bị bằng `image_picker`, xem trước trước khi lưu.
- `landlord/room_types/`: danh sách loại phòng, giá thuê theo tháng và thêm/sửa/xóa.
- `landlord/rooms/`: danh sách phòng của nhà trọ hiện tại, lọc tầng/trạng thái và tìm mã phòng, loại phòng, người thuê. Giá phòng có hợp đồng lấy từ hợp đồng; phòng trống lấy giá của loại phòng.
- `landlord/announcements/`: gửi đến tất cả phòng, một tầng hoặc nhiều phòng được chọn trong phiên; Người thuê đúng phạm vi nhận cùng thông báo. Hộp nhận được lấy từ dữ liệu nghiệp vụ hiện tại.
- `landlord/viewings/`: người đặt lịch, ngày giờ, nút xác nhận/hủy và mở cuộc trò chuyện.
- `tenant/viewings/`: các phòng người thuê đã đặt lịch với trạng thái đang chờ xác nhận, đã xác nhận, đã hủy.

Hai trang lịch dùng chung `shared/viewings/viewing_store.dart`. Chủ trọ chỉ thấy lịch của Mây House (`may`); Người thuê chỉ thấy lịch của ID phiên mình. Trạng thái đổi bên Chủ trọ hiển thị bên Người thuê. Hội thoại từ lịch xem dùng cùng danh sách tin ở hai vai trò. Thay ID phiên và các store bằng phiên đăng nhập/repository khi có backend.

Thông tin, ảnh và giá đã chỉnh sửa được giữ khi chuyển trang trong phiên chạy hiện tại. Dữ liệu chưa lưu vào cơ sở dữ liệu và sẽ trở về mẫu khi khởi động lại ứng dụng.

Danh mục phòng mẫu dùng chung giữa danh sách phòng và bộ chọn người nhận tại `LandlordDemoStore.roomCatalog`. Phòng 101 liên kết với mã A.101 của hợp đồng mẫu; A.302 và B.105 giữ mã như các hợp đồng hiện có. Giá và trạng thái trên danh sách phòng cập nhật theo loại phòng/hợp đồng trong phiên chạy.

Chi tiết đối chiếu trường, quy tắc giữ lịch sử và các bước kiểm tra nằm tại `docs/DONG_BO_CHU_TRO_NGUOI_THUE.md`.
