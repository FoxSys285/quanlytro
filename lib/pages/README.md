# Cấu trúc màn hình

Thư mục được chia theo vai trò và feature. Các thư mục feature dùng snake_case; tạo widget màn hình trong feature tương ứng khi bắt đầu triển khai. Auth, hồ sơ, thông báo và trợ giúp dùng chung được đặt dưới shared.

```text
pages/
  shared/        auth, profile, notifications, support
  tenant/        discovery, viewings, conversations, leases, members,
                 invoices, payments, announcements, incidents
  landlord/      dashboard, properties, rooms, room_types, services,
                 meter_readings, viewings, conversations, leases, members,
                 billing, payments, announcements, incidents,
                 payment_accounts, reports, staff
  admin/         dashboard, users, property_verification, moderation,
                 support, audit_logs, settings
```

Phạm vi từng màn hình và luồng nghiệp vụ được mô tả trong `docs/THIET_KE_NGHIEP_VU.md`.
