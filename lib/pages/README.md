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
    leases/         tenant_home_page.dart
      components/   lease metric, overview card, member row
  landlord/      dashboard, properties, rooms, room_types, services,
                 meter_readings, viewings, conversations, leases, members,
                 billing, payments, announcements, incidents,
                 payment_accounts, reports, staff
  admin/         dashboard, users, property_verification, moderation,
                 support, audit_logs, settings
```

Các màn hình người thuê đang được triển khai trong `tenant/`; tiện ích giao diện dùng chung của nhóm màn hình nằm trong `tenant_ui.dart`.

Phạm vi từng màn hình và luồng nghiệp vụ được mô tả trong `docs/THIET_KE_NGHIEP_VU.md`.
