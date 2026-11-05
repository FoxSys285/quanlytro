# Danh sách nhà trọ đã xác minh

Đã bổ sung **400 nhà trọ xác minh mẫu**, phân bố ở 34 tỉnh/thành (mỗi nơi 11–12 nhà), trong bộ danh mục 680 nhà trọ. 280 nhà còn lại giữ nguyên trạng thái chưa xác minh.

Các thuộc tính trong `rental_properties/{id}`:

| Thuộc tính | Ý nghĩa |
| --- | --- |
| `verified` | Trạng thái được duyệt để hiển thị trong bộ lọc |
| `verificationProof` | SHA-256 tính bằng đúng thuật toán của app trên hồ sơ, phòng và loại phòng hiện tại |
| `verification.status` | `verified` |
| `verification.scope` | `demo`: xác minh mô phỏng cho dữ liệu mẫu |
| `verification.schemaVersion` | Phiên bản metadata, hiện là `1` |
| `verification.reviewedAt` | Thời điểm cập nhật, định dạng ISO 8601 UTC |
| `verification.reviewedBy` | `demo-catalogue-seed`, không giả danh người kiểm duyệt thật |
| `verification.note` | Ghi rõ dữ liệu mẫu chưa được kiểm chứng ngoài thực tế |

Giữ nguyên `isDemo`, nguồn dữ liệu, số điện thoại mẫu, ảnh, giá thuê và dữ liệu nghiệp vụ. Trạng thái trong `management/system.admin.verified` và `verificationProofs` được đồng bộ để màn quản trị không ghi đè lại các phê duyệt này từ dữ liệu cũ.

App hiển thị **Đã xác minh · mẫu** cho các hồ sơ mẫu, kèm mô tả trên thẻ. Bộ lọc vẫn yêu cầu `verified == true` và dấu kiểm tra khớp hồ sơ hiện tại. Metadata không thể thay thế dấu kiểm tra. Khi dữ liệu hồ sơ/phòng thay đổi, app cần xác minh lại. Khi đọc Firebase, trạng thái tại từng nhà trọ được khôi phục cho các vai trò, thay cho việc chỉ phụ thuộc bộ nhớ quản trị.

## Sao lưu và kiểm tra

- Bản sao lưu và kế hoạch bất biến: `.local-backups/verified-properties-400/` (Git bỏ qua).
- Báo cáo không chứa thông tin đăng nhập: `artifacts/BAO_CAO_400_NHA_TRO_XAC_MINH.json`.
- Cập nhật 400 hồ sơ cùng bản trạng thái quản trị trong một lần ghi nguyên tử, có điều kiện phiên bản để không ghi đè chỉnh sửa đồng thời.
- Đã đọc lại toàn bộ hồ sơ, đối chiếu các trường không liên quan, kiểm tra đọc công khai và xác nhận 400 hồ sơ bằng model người thuê và quản trị của ứng dụng.
- Tác vụ này không triển khai Firestore Rules và không thay đổi Firebase Authentication.

```powershell
python -m unittest discover -s test -p test_verified_property_seed.py
flutter test test/tenant_properties_test.dart test/cloud_catalog_codec_test.dart test/admin_workflow_test.dart tool/verify_seeded_properties_test.dart
```

`tool/verify_seeded_properties_test.dart` kiểm tra dữ liệu trong bản sao lưu/đọc lại tại máy này. Khi tiếp tục tác vụ đã có kế hoạch, dùng `apply` hoặc `verify`, không ghi đè bản sao lưu:

```powershell
node tool/with_firebase_cli.cjs tool/seed_verified_properties.py verify
```
