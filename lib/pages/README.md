# Cấu trúc màn hình

Thư mục được chia theo vai trò và feature. Các thư mục feature dùng snake_case; tạo widget màn hình trong feature tương ứng khi bắt đầu triển khai. Auth, hồ sơ, thông báo và trợ giúp dùng chung được đặt dưới shared.

```text
pages/
  shared/          auth, profile, notifications, support
  tenant/          tenant_page_router.dart, tenant_ui.dart
    conversations/ tenant_conversation_page.dart
      components/   message bubble
      models/       conversation message
    discovery/      tenant_discovery_page.dart, tenant_favorites_page.dart,
                    tenant_favorites_store.dart
      components/   room card/artwork/details, filter sheet
      models/       room listing and preview data
    invoices/       tenant_invoices_page.dart, tenant_invoice_detail_page.dart
      components/   invoice card, charge rows, payment instructions
    incidents/      tenant_incidents_page.dart
    leases/         tenant_home_page.dart
      components/   lease metric, overview card, member row
  landlord/      landlord_page_router.dart, landlord_ui.dart
    dashboard/      landlord_dashboard_page.dart
    services/       landlord_services_page.dart (+ models/)
    meter_readings/ landlord_meter_readings_page.dart (+ models/)
    members/        landlord_members_page.dart
    conversations/  landlord_conversations_page.dart, landlord_chat_page.dart (+ models/)
    incidents/      landlord_incidents_page.dart (+ models/)
    (chưa làm)      properties, rooms, room_types, viewings, leases, billing,
                    payments, announcements, payment_accounts, reports, staff
  admin/         dashboard, users, property_verification, moderation,
                 support, audit_logs, settings
```

Các màn hình người thuê đang được triển khai trong `tenant/`; tiện ích giao diện dùng chung của nhóm màn hình nằm trong `tenant_ui.dart`.

Phạm vi từng màn hình và luồng nghiệp vụ được mô tả trong `docs/THIET_KE_NGHIEP_VU.md`.

Vai trò chủ trọ hiện dùng dữ liệu mẫu của một nhà trọ Mây House trong `landlord/landlord_demo_store.dart`:

- `landlord/properties/`: thông tin nhà trọ và form chỉnh sửa, chọn ảnh từ thiết bị bằng `image_picker`, xem trước trước khi lưu.
- `landlord/room_types/`: danh sách loại phòng, giá thuê theo tháng và thêm/sửa/xóa.

Thông tin, ảnh và giá đã chỉnh sửa được giữ khi chuyển trang trong phiên chạy hiện tại. Dữ liệu chưa lưu vào cơ sở dữ liệu và sẽ trở về mẫu khi khởi động lại ứng dụng.
