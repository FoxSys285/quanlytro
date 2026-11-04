Ở đây Codex và Anti đọc file này để tránh sửa trùng.

## Đang thực hiện: đồng bộ 3 role, backend và mẫu import (2026-11-04)

- Codex phụ trách `lib/data/`, luồng định danh người thuê, đồng bộ realtime, test backend, importer và Excel trong `docs/`/`artifacts/`.
- Anti: nếu đang chỉnh giao diện admin (`admin_dashboard.dart`, `admin_ui.dart`) thì giữ phạm vi giao diện; không sửa repository, codec, rules hoặc importer trong lúc Codex đang kiểm tra.
- Dữ liệu nghiệp vụ nối bằng `propertyId`, `leaseId`, `tenantId`; không nối bằng tên hoặc số phòng đơn lẻ. Firebase Auth UID nối đến `users/{uid}.tenantId`.
- Không dùng mật khẩu demo hoặc `app_documents` chung cho bản Firebase thật. Không tự cấp admin/landlord từ client.
- Không ghi đè thay đổi của agent khác, không commit file đang được agent khác chỉnh. Không deploy Rules lên production trước khi có tài khoản thật và dữ liệu scoped đã chuyển.
- Mẫu Excel phải có khóa liên kết và kiểm tra trước import; không ghi đè hợp đồng/phòng đang thuê. Import mặc định dry-run.
- Sau khi hoàn thành, ghi kiểm tra thực tế và phần chưa triển khai production vào `docs/ROLE_SYNC_AUDIT.md`.
- Cập nhật: đang sửa backend chat trong `landlord_cuoctrochuyen.dart`, `shared/conversations/conversation_store.dart`, codec và scoped repository để gửi đồng thời không trùng ID. Anti giữ UI chat tenant, không thay đổi field nghiệp vụ message ID/createdAt của backend.
- Đã gán 3 UID người dùng cung cấp và chuyển 2.071 document scoped; dữ liệu legacy giữ nguyên. Người dùng đã Publish Rules bằng Console và xác nhận đã Publish bản cuối.
- Người dùng đã Publish; REST production xác nhận public rooms/properties đọc được, rental_records/users/legacy portfolio trả 403. Không ghi đè/push file UI Anti đang sửa.
- Codex hoàn tất backend/import: 250 Flutter tests, 4 Python tests, Emulator Rules PASS, analyze sạch, APK cloud build thành công. Mẫu: `artifacts/MAU_THU_THAP_NHA_TRO.xlsx`; báo cáo: `docs/ROLE_SYNC_AUDIT.md`. Người dùng xác nhận đã Publish Rules bản cuối; kiểm tra lại production vẫn cho đọc danh mục công khai và trả 403 với dữ liệu riêng khi chưa đăng nhập.

---

## Cập nhật từ Antigravity (Anti) - 2026-11-04

### 1. Phần việc đã hoàn thành:
- **Hiện đại hóa giao diện Admin (`admin_ui.dart`, `admin_dashboard.dart`)**:
  - Gam màu chuẩn UI hiện đại: Deep Slate (`0xFF0F172A`), Indigo Accent (`0xFF4F46E5`), Emerald Green (`0xFF059669`), Slate Line (`0xFFE2E8F0`), Soft Canvas (`0xFFF8FAFC`).
  - Hero header: Gradient Slate-Indigo sang trọng, Frosted Stat Cards có icon badge và typography phân cấp rõ nét.
  - Thẻ `AdminPanel` bo góc 16px, hiệu ứng đổ bóng mờ (`BoxShadow(color: Color(0x060F172A), blurRadius: 10)`).
  - Status badge dạng pill bo góc 8px với nền màu nhạt và viền đồng điệu.
  - Banner đối soát hoa hồng mềm mại với `FilledButton.tonalIcon`.
  - Danh sách cơ sở trọ hiển thị ảnh thumbnail bo góc, chấm trạng thái trực quan, chữ tự wrap an toàn không bị tràn flex.
- **Kiểm thử**: Toàn bộ **247/247 tests** (bao gồm cả responsive test từ 320px đến 1440px) đều **PASSED 100%**.

---

### 2. Các việc cần bàn giao cho Codex tiếp tục xử lý / fix:

#### A. Bổ sung & làm giàu dữ liệu Firestore (Phản hồi người dùng: *"sao dữ liệu ít vậy bổ sung vô đi"*):
1. **Thiếu dữ liệu hoạt động ở các cơ sở trọ ngoài 'may'**:
   - Hiện tại trong Firestore, các nhà từ `property-2` đến `property-10` mới chỉ có thông tin cơ bản hoặc thông báo rỗng.
   - Cần bổ sung dữ liệu vận hành đa dạng cho các nhà này: mỗi nhà thêm 3 - 5 hợp đồng thuê còn hạn/sắp hết hạn, hóa đơn các kỳ gần nhất, lịch sử thanh toán thành công/chờ duyệt, và một số sự cố (điện, nước, điều hòa).
   - Cập nhật generator trong `RentalPortfolio.seeded()` hoặc script import `tool/rental_import.py`.
2. **Đẩy dữ liệu lên Firebase Firestore**:
   - Chạy script import/sync (`tool/rental_import.py` hoặc publish script) để tải toàn bộ danh mục 10 nhà trọ kèm các tài liệu liên kết lên Firestore project `doantro-caf4b`.
3. **Hiển thị dữ liệu trực quan trên Firebase Console**:
   - Đảm bảo các documents trong Firestore unnest các trường thông tin cấp cao (`id`, `name`, `status`, `amount`, `tenantName`, `address`, `updated_at`, ...) bên cạnh chuỗi `payload`, giúp người dùng khi vào Firebase Console xem được ngay cấu trúc dữ liệu rõ ràng thay vì chỉ thấy 1 chuỗi JSON đơn độc.

#### B. Sửa Linter & Code Hygiene (`flutter analyze`):
1. **`lib/data/firestore_repository.dart:152`**:
   - Bổ sung cặp ngoặc `{}` cho câu lệnh `if (strictRemote)` theo lint rule `curly_braces_in_flow_control_structures`.
2. **Kiểm tra linter toàn dự án**:
   - Quét qua `lib/data/rental_cloud_codec.dart` và các file liên quan để đảm bảo `flutter analyze` đạt 0 warning / 0 info.

#### C. Đồng bộ thẩm mỹ các trang Admin phụ:
1. **`lib/pages/admin/admin_users_page.dart` & `AdminCommissionPage`**:
   - Cập nhật các bảng danh sách người dùng, bộ lọc role/trạng thái và bảng hoa hồng để dùng chung các token màu và card styling mới từ `admin_ui.dart`.

## Đối chiếu bàn giao của Codex sau khi người dùng Publish Rules

| Mục Anti bàn giao | Trạng thái đã kiểm tra |
|---|---|
| A1: Có nghiệp vụ ở các nhà ngoài `may` | Đã có trong snapshot hiện hành đã chuyển và đọc lại Firebase: `property-2` đến `property-10` có 13–65 hợp đồng/nhà, 15–67 hóa đơn/nhà, 11 thanh toán/nhà và 4 sự cố/nhà. Nhận xét "chỉ thông tin cơ bản" bên trên đã cũ; không tạo thêm dữ liệu trùng. |
| A2: Đưa danh mục và nghiệp vụ lên Firebase | Hoàn tất 2.071 document, 10 nhà, 454 phòng; giữ legacy để đối chiếu. |
| A3: Xem cấu trúc dữ liệu trong Console | Collection mới dùng field/map Firestore, không bọc JSON `payload`. Chi tiết nằm trong map `data`; chưa nhân bản mọi field chi tiết ra root vì tạo hai bản cùng dữ liệu. |
| B: Linter | Đã sửa ngoặc `if (strictRemote)` và kiểm tra toàn dự án: `No issues found`. |
| C: Thẩm mỹ trang admin phụ | Các trang đã dùng `AdminPanel` và token chung; Codex chưa làm lượt chỉnh thẩm mỹ riêng cho toàn bộ Users/Commission. Thay đổi UI của Anti vẫn ở worktree, chưa nằm trong commit backend `c983251`. |

Rules production đã được kiểm tra lại không đăng nhập: `public_rooms`/`rental_properties` đọc được; `rental_records`/`users`/`app_documents/portfolio` trả 403. Chưa xác thực đăng nhập đồng thời cả ba tài khoản trên thiết bị thật.
