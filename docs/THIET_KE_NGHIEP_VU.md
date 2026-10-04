# Đặc tả nghiệp vụ và thiết kế tổng thể ứng dụng quản lý trọ

> Trạng thái: thiết kế mục tiêu đề xuất, không phải mô tả chức năng đã được cài đặt.
> Cập nhật: 2026-10-03

## 1. Mục tiêu và hiện trạng

Ứng dụng phục vụ người thuê tìm và quản lý chỗ ở; chủ trọ quản lý nhà, phòng, hợp đồng, hóa đơn và trao đổi với người thuê; quản trị viên hỗ trợ và kiểm soát nền tảng.

Repo hiện là Flutter starter project. lib/main.dart còn màn hình đếm mẫu; lib/layouts/ có ba layout khởi đầu tenant, landlord, admin; chưa thấy model nghiệp vụ, backend, database hoặc service. Tài liệu này mô tả đích cần xây, độc lập với nhà cung cấp backend. Trước khi vận hành thật cần chọn backend, auth, lưu tệp và dịch vụ push notification.

## 2. Thuật ngữ và mô hình miền

- **Nhà trọ (property):** địa điểm do một hoặc nhiều chủ/quản lý vận hành.
- **Phòng (room):** đơn vị cho thuê thực tế; có thể gắn loại phòng nhưng vẫn có giá/đặc điểm riêng.
- **Loại phòng (room type):** mẫu mô tả diện tích, tiện nghi hoặc cấu hình cơ bản.
- **Hợp đồng (lease):** thỏa thuận thuê phòng theo thời hạn; có người thuê đại diện và thành viên.
- **Người thuê đại diện (trưởng phòng):** đầu mối chính của hợp đồng; không gọi là “chủ phòng”.
- **Dịch vụ:** điện, nước, internet, xe, vệ sinh hoặc phí khác, mỗi dịch vụ có đơn vị và cách tính.
- **Kỳ hóa đơn:** khoảng thời gian cần thanh toán; mặc định theo tháng.

Nguyên tắc:

1. Một tài khoản có thể vừa thuê ở nơi này, vừa quản lý nhà trọ khác. Phân quyền theo nhà/hợp đồng/tài nguyên, không chỉ một role toàn cục.
2. Trạng thái thuê của phòng được suy ra từ hợp đồng có hiệu lực. Tình trạng bảo trì là trạng thái riêng.
3. Hợp đồng, đơn giá và hóa đơn đã phát hành phải giữ lịch sử; thay đổi sau này không được âm thầm sửa kỳ cũ.
4. Chủ trọ chỉ đọc dữ liệu nhà mình; người thuê chỉ đọc hợp đồng/phòng họ là thành viên; admin chỉ truy cập theo nhiệm vụ và có audit.
5. Ảnh và giấy tờ lưu ở file/object storage. Database chỉ lưu metadata và khóa file có kiểm soát truy cập.

## 3. Vai trò và quyền

| Vai trò | Quyền chính | Giới hạn |
|---|---|---|
| Khách | Tìm nhà/phòng đang công khai, xem thông tin, yêu cầu đăng nhập để liên hệ | Không xem thông tin người thuê hiện tại, hợp đồng hay hóa đơn |
| Người thuê | Xem hợp đồng, thành viên được phép, hóa đơn và thông báo; gửi minh chứng thanh toán; tạo sự cố; chat | Không sửa giá, hợp đồng hoặc chỉ số đã chốt |
| Người thuê đại diện | Quyền người thuê; gửi lời mời thành viên, làm đầu mối | Không tự duyệt lời mời hoặc thay quyền chủ trọ |
| Chủ trọ/chủ sở hữu | Quản lý nhà, phòng, giá, hợp đồng, hóa đơn, thông báo và sự cố thuộc nhà | Không truy cập nhà khác nếu chưa được cấp quyền |
| Nhân viên quản lý | Quyền theo phân công như nhập chỉ số, xử lý sự cố | Không tự cấp quyền chủ sở hữu |
| Admin | Xử lý tài khoản, báo cáo, xác minh và ticket | Thao tác nhạy cảm phải có lý do/audit; không tùy ý sửa giao dịch |

**Giả định MVP:** một hợp đồng có một người thuê đại diện. Người đại diện gửi yêu cầu thêm người; chủ trọ duyệt. Người được mời phải xác nhận và được duyệt mới trở thành thành viên. Lời mời chờ duyệt còn hạn giữ chỗ trong giới hạn max_occupants.

## 4. Quy trình end-to-end

### 4.1 Tài khoản và phân quyền

1. Người dùng đăng ký email/số điện thoại, xác minh và đăng nhập.
2. Có thể bật vai trò chủ trọ trên cùng tài khoản, tạo nhà trọ hoặc nhận lời mời quản lý.
3. Chủ nhà mời/thu hồi nhân viên và chọn quyền theo nhà.
4. Backend kiểm tra quyền với từng tài nguyên. Ẩn nút ở UI không thay thế phân quyền server.
5. Có khôi phục tài khoản, cập nhật hồ sơ, đăng xuất thiết bị và yêu cầu xóa/ẩn danh tài khoản.

### 4.2 Khám phá và xem phòng

1. Chủ trọ đăng tin nhà/phòng, ảnh, vị trí, tiện ích, nội quy, giá tham khảo.
2. Người thuê lọc theo khu vực, giá, tiện nghi, tình trạng rồi xem chi tiết.
3. Thẻ phòng hiển thị trạng thái bằng chữ và màu: còn trống, đang giữ chỗ, đang thuê, sửa chữa, ngừng cho thuê.
4. Người thuê đăng nhập để gửi yêu cầu xem và chọn lịch; tin nhắn gắn với nhà/phòng/yêu cầu.
5. Chủ trọ chấp nhận, đề xuất thời gian khác hoặc từ chối; hai bên có thể hủy.
6. Yêu cầu xem không tự giữ phòng. Nếu giữ phòng, tạo hold có hạn, điều kiện và tiền cọc; hết hạn tự giải phóng.

### 4.3 Hợp đồng

1. Sau khi hai bên thống nhất trực tiếp, chủ trọ tạo hợp đồng đúng phòng.
2. Nhập người thuê đại diện, thời hạn, tiền thuê/cọc, kỳ và ngày đến hạn, giới hạn người, điều khoản.
3. Tải bản hợp đồng ký trực tiếp hoặc ghi nhận xác nhận. Không mặc định thao tác trong app là chữ ký điện tử có giá trị pháp lý.
4. Khi hợp đồng có hiệu lực, phòng chuyển sang đang thuê theo dữ liệu hợp đồng.
5. Gia hạn, đổi giá/phòng, thêm/bớt người tạo phụ lục hoặc bản ghi thay đổi có ngày hiệu lực, người xác nhận.
6. Khi trả phòng: ghi ngày kết thúc, chỉ số cuối, công nợ, hoàn/khấu trừ cọc, lý do. Hợp đồng cũ vẫn xem được.

### 4.4 Thêm thành viên

1. Người thuê đại diện mời bằng email/số điện thoại, ghi tên và ngày bắt đầu dự kiến.
2. Backend kiểm tra hợp đồng hiệu lực, quyền mời và số người tối đa; tính thành viên active cộng lời mời còn hạn.
3. Người được mời đăng nhập/tạo tài khoản, xem thông tin và xác nhận.
4. Chủ trọ duyệt/từ chối; từ chối có lý do. Hủy/từ chối/hết hạn thì giải phóng chỗ.
5. Sau khi duyệt, tạo thành viên hợp đồng; nếu cần phụ lục, lưu file và xác nhận riêng.
6. Thành viên rời đi/bị xóa phải có ngày kết thúc và audit; không xóa lịch sử hóa đơn/giao dịch.

### 4.5 Bảng giá, chỉ số và hóa đơn

1. Chủ trọ tạo danh mục điện/nước/dịch vụ, cách tính, đơn giá có hiệu lực từ ngày; có thể ghi đè giá theo phòng.
2. Gắn đồng hồ vào phòng nếu đo riêng. Đến kỳ, nhập chỉ số đầu/cuối, ngày ghi và ảnh đồng hồ.
3. Kiểm tra chỉ số cuối không nhỏ hơn đầu (trừ trường hợp thay đồng hồ có giải trình); tính lượng dùng và tạo hóa đơn nháp.
4. Chủ trọ rà soát và phát hành; snapshot đơn giá/cách tính vào từng dòng hóa đơn.
5. Người thuê nhận thông báo, xem các dòng tính, hạn đóng và hướng dẫn QR/chuyển khoản.
6. Hóa đơn nháp sửa được. Hóa đơn đã phát hành cần hủy/điều chỉnh có lý do, giữ bản cũ và tạo bản thay thế.

**Công thức tổng quát đề xuất:**

Tổng = tiền thuê theo ngày thực tế + điện + nước + dịch vụ + điều chỉnh - giảm trừ + nợ kỳ trước (nếu bật).

- Điện/nước = (chỉ số cuối - chỉ số đầu) × đơn giá snapshot.
- Dịch vụ khai báo cơ sở tính: theo phòng, đầu người, tiêu thụ, cố định hoặc thủ công.
- Thuê giữa tháng: mặc định đề xuất tính theo ngày thuê thực tế / số ngày tháng; hiển thị phép tính.
- Không cộng nợ cũ nếu chính sách chưa bật và người thuê không thấy dòng nợ.
- Đồng hồ chung phải khai báo cách phân bổ (đầu người/diện tích/tỷ lệ/thủ công); không giả định số đo riêng.

### 4.6 Thanh toán

1. QR/chuyển khoản là hướng dẫn, không tự khẳng định đã nhận tiền nếu chưa tích hợp đối soát.
2. Người thuê gửi số tiền, thời điểm, mã giao dịch và ảnh minh chứng; trạng thái ban đầu là đang kiểm tra.
3. Chủ trọ có quyền tài chính xác nhận hoặc từ chối kèm lý do. Chỉ khoản xác nhận mới cập nhật hóa đơn đã trả.
4. Lưu người duyệt, thời gian, lý do và lịch sử trạng thái. Có thể hỗ trợ nhiều lần thanh toán nhưng MVP đề xuất chỉ thanh toán đủ một lần; thanh toán một phần/hoàn tiền để giai đoạn sau.
5. Không tin số tiền/trạng thái do app client gửi; server tính và kiểm tra.

### 4.7 Chat, thông báo và sự cố

- Hội thoại gắn với yêu cầu thuê, nhà/phòng hoặc hợp đồng. Chỉ thành viên hội thoại được đọc; lưu người gửi, thời gian, đọc/chưa đọc, tệp.
- Thông báo gửi phạm vi nhà, phòng hoặc cá nhân. Chủ trọ xem trước người nhận; người thuê có inbox và trạng thái đã đọc.
- Tự thông báo khi có hóa đơn, lời mời, lịch hẹn đổi, thanh toán được duyệt/từ chối, hợp đồng sắp hết hạn hoặc sự cố cập nhật.
- Sự cố gồm phòng, loại, mô tả, ưu tiên, ảnh/video, thời gian có thể vào phòng; chủ trọ tiếp nhận, phân công, trao đổi, hoàn thành. Người thuê xác nhận hoặc mở lại.

### 4.8 Admin và hỗ trợ

1. Người dùng gửi ticket có chủ đề, nội dung, tệp và mã ticket.
2. Admin gán người xử lý, phản hồi, ghi chú nội bộ, đóng/mở lại.
3. Admin xử lý vi phạm/xác minh theo chính sách; khóa/mở phải có lý do và thời hạn.
4. Admin không sửa hợp đồng/giao dịch thay các bên. Truy cập dữ liệu nhạy cảm cần phân quyền, lý do và audit.

## 5. Trạng thái chuẩn

| Đối tượng | Trạng thái đề xuất |
|---|---|
| Tài khoản | active, suspended, pending_deletion, deleted/anonymized |
| Tin đăng | draft, published, paused, rejected, archived |
| Phòng - bảo trì | operational, maintenance, inactive |
| Phòng - thuê | Suy ra available, held, occupied; có thể unavailable |
| Yêu cầu xem | pending, accepted, reschedule_proposed, rejected, cancelled, completed, no_show |
| Giữ chỗ | active, converted_to_lease, expired, cancelled |
| Hợp đồng | draft, pending_acceptance, active, expiring, ended, terminated, void |
| Thành viên | invited, pending_landlord_approval, active, rejected, left, removed, expired |
| Hóa đơn | draft, issued, partially_paid, paid, overdue, void, replaced |
| Yêu cầu thanh toán | submitted, under_review, confirmed, rejected, cancelled, refunded |
| Sự cố | new, acknowledged, in_progress, waiting_for_tenant, resolved, closed, reopened, cancelled |
| Ticket | open, assigned, waiting_user, resolved, closed |

overdue, expiring, available có thể tính từ ngày/hợp đồng/hold. Nếu cache trạng thái, cần job đồng bộ và quy tắc nhất quán.

## 6. Mô hình dữ liệu/bảng đề xuất

### Quy ước

- Tên bảng snake_case; UUID làm khóa chính. Bảng nghiệp vụ thường có created_at, updated_at, created_by, và khi cần deleted_at.
- Tiền là số nguyên VND hoặc decimal chuẩn, không dùng float. Hóa đơn giữ đơn giá snapshot.
- Thời gian lưu UTC; ngày/hạn dùng timezone của nhà trọ (mặc định Asia/Ho_Chi_Minh).
- Không tự lưu mật khẩu nếu backend auth provider quản lý. File không lưu blob trực tiếp trong DB.

### Tài khoản và quyền

| Bảng | Cột chính | Ràng buộc/ý nghĩa |
|---|---|---|
| users | id, auth_subject, email, phone, full_name, avatar_media_id, status, last_login_at | auth_subject duy nhất; chuẩn hóa email/phone |
| user_preferences | user_id, locale, timezone, push_enabled, email_enabled | Một dòng mỗi user |
| property_staff | id, property_id, user_id, role, status, invited_by, joined_at | Role: owner/manager/billing/maintenance; unique nhà-user còn hiệu lực |
| platform_admins | user_id, admin_role, status, granted_by | Vai trò nền tảng tách với chủ trọ |

### Nhà, phòng và giá

| Bảng | Cột chính | Ràng buộc/ý nghĩa |
|---|---|---|
| properties | id, name, description, address, ward, district, province, latitude, longitude, timezone, listing_status, verification_status | Chủ/quản lý được xác định qua property_staff; địa chỉ chính xác có thể chỉ hiện sau khi duyệt lịch |
| property_media | id, property_id, media_id, sort_order, caption | Ảnh nhà/tiện ích |
| room_types | id, property_id, name, description, default_area_m2, default_amenities_json | Unique property_id + name |
| rooms | id, property_id, room_type_id, code, floor, area_m2, base_rent, max_occupants, maintenance_status, is_listed, features_json | Unique property_id + code; giá phòng ưu tiên giá mẫu |
| room_media | id, room_id, media_id, sort_order, caption | Ảnh phòng |
| service_catalog | id, property_id, name, service_type, unit_label, billing_basis, active | Basis: metered/per_room/per_person/fixed/manual |
| service_rates | id, service_id, room_id nullable, unit_price, effective_from, effective_to, created_by | Room null là giá mặc định; cấm khoảng giá trùng phạm vi |
| meters | id, property_id, room_id, service_id, meter_code, installed_at, removed_at, status | MVP đồng hồ riêng phòng; đồng hồ chung cần phân bổ rõ |

### Tìm phòng, lịch xem và chat

| Bảng | Cột chính | Ràng buộc/ý nghĩa |
|---|---|---|
| viewing_requests | id, room_id, applicant_user_id, requested_start_at, requested_end_at, status, landlord_note, tenant_note | Không tự giữ phòng |
| room_holds | id, room_id, applicant_user_id, expires_at, deposit_amount, terms, status, created_by | Một phòng tối đa một hold active |
| conversations | id, property_id, room_id, viewing_request_id, lease_id, type, created_at | Hội thoại gắn ngữ cảnh |
| conversation_members | conversation_id, user_id, joined_at, left_at, last_read_at, muted | Unique conversation-user |
| messages | id, conversation_id, sender_user_id, body, message_type, sent_at, edited_at, deleted_at | Soft delete nếu cần kiểm toán |
| message_media | message_id, media_id | Tệp đính kèm |

### Hợp đồng và cư dân

| Bảng | Cột chính | Ràng buộc/ý nghĩa |
|---|---|---|
| leases | id, property_id, room_id, lease_code, status, start_date, end_date, rent_amount, deposit_amount, billing_day, due_day, max_occupants, terms_json, created_by | Không cho hai lease active trùng thời gian cùng phòng nếu không hỗ trợ thuê theo giường |
| lease_members | id, lease_id, user_id, display_name_snapshot, contact_snapshot, role, status, move_in_date, move_out_date, approved_by, approved_at | role xác định representative/member; chỉ một representative active mỗi lease |
| member_invitations | id, lease_id, inviter_user_id, invitee_user_id nullable, invitee_email, invitee_phone, token_hash, status, expires_at, decision_by, decision_at | Không lưu token rõ; pending còn hạn giữ slot |
| lease_documents | id, lease_id, media_id, document_type, version, effective_at, uploaded_by, accepted_by_json | Hợp đồng/phụ lục và xác nhận |
| lease_changes | id, lease_id, change_type, old_values_json, new_values_json, effective_at, reason, created_by, approved_by | Lịch sử đổi giá/thời hạn/phòng/thành viên |

### Chỉ số, hóa đơn và thanh toán

| Bảng | Cột chính | Ràng buộc/ý nghĩa |
|---|---|---|
| meter_readings | id, meter_id, room_id, period_start, period_end, previous_value, current_value, unit_price_snapshot, usage_amount, photo_media_id, recorded_at, recorded_by, status | Unique meter/kỳ; điều chỉnh cần lý do |
| invoices | id, invoice_code, lease_id, room_id, period_start, period_end, issued_at, due_at, status, subtotal, adjustment_total, total, amount_paid, currency, revision, replaces_invoice_id, created_by, issued_by | Một kỳ mỗi lease/revision; snapshot |
| invoice_lines | id, invoice_id, service_id nullable, description, quantity, unit_label, unit_price, amount, calculation_json, source_reading_id nullable | Dòng thuê, điện/nước, dịch vụ, điều chỉnh |
| payment_submissions | id, invoice_id, payer_user_id, amount, method, transfer_reference, paid_at_claimed, status, proof_media_id, reviewed_by, reviewed_at, rejection_reason | Bằng chứng chưa phải xác nhận đã nhận |
| payment_events | id, payment_submission_id, from_status, to_status, actor_user_id, reason, created_at | Nhật ký bất biến |
| payment_accounts | id, property_id, bank_name, account_name, account_number_protected, qr_media_id, transfer_note_template, active | Giới hạn người được xem |

### Thông báo, sự cố, tệp và hỗ trợ

| Bảng | Cột chính | Ràng buộc/ý nghĩa |
|---|---|---|
| announcements | id, property_id, author_user_id, title, body, target_type, target_id, published_at, expires_at, status | Target: property/room/lease/member |
| announcement_recipients | announcement_id, user_id, delivered_at, read_at | Snapshot người nhận lúc gửi |
| notifications | id, user_id, type, title, body, deep_link, entity_type, entity_id, created_at, read_at, delivery_status | Inbox là nguồn sự thật; push là kênh phụ |
| incidents | id, property_id, room_id, lease_id, reported_by, category, title, description, priority, status, preferred_visit_at, assigned_to, resolved_at, closed_at | Người thuê chỉ báo sự cố phòng mình |
| incident_updates | id, incident_id, author_user_id, body, status_after, created_at | Lịch sử |
| incident_media | incident_id, media_id | Ảnh/video sự cố |
| media_assets | id, storage_key, mime_type, size_bytes, checksum, uploaded_by, visibility, created_at, deleted_at | URL có hạn, validate loại/dung lượng |
| support_tickets | id, ticket_code, created_by, category, subject, status, priority, assigned_admin_id, related_entity_type, related_entity_id, closed_at | Khác sự cố bảo trì |
| support_messages | id, ticket_id, sender_user_id, body, is_internal_note, created_at | Ghi chú nội bộ chỉ admin |
| audit_logs | id, actor_user_id, action, entity_type, entity_id, before_json, after_json, reason, created_at | Append-only; hạn chế PII |
| reports | id, reporter_user_id, target_type, target_id, reason, details, status, handled_by, handled_at | Báo cáo tin đăng/tài khoản/nội dung |

### Chỉ mục và ràng buộc

- Index theo property, room, lease, user, status, thời gian; hóa đơn theo lease/kỳ/status.
- Tìm tin theo trạng thái, tỉnh/quận, giá; dùng spatial index nếu hỗ trợ.
- Dùng transaction/lock khi cấp phòng, duyệt thành viên, phát hành hóa đơn và xác nhận thanh toán.
- Ràng buộc một representative active trên mỗi lease bằng unique constraint phù hợp (partial unique index nếu dùng SQL).
- Một kỳ hóa đơn một lease (trừ revision thay thế); mỗi đổi trạng thái tiền phải có event.
- Kiểm tra quyền server-side cho media, invoice, message và document; UUID khó đoán không thay authorization.

## 7. Các trang/màn hình

Mọi trang cần trạng thái loading, empty, error, retry, mất mạng và không đủ quyền.

### Chung và auth

| Trang | Chức năng |
|---|---|
| Splash/khởi tạo | Khôi phục phiên, tải cấu hình và điều hướng |
| Đăng nhập | Email/điện thoại, mật khẩu/OTP, quên mật khẩu |
| Đăng ký | Tạo tài khoản, xác minh liên hệ, điều khoản |
| Chọn vai trò/nhà | Chuyển ngữ cảnh nếu user vừa tenant vừa landlord |
| Hồ sơ | Liên hệ, đổi mật khẩu, tùy chọn, đăng xuất thiết bị, yêu cầu xóa |
| Trung tâm thông báo | Inbox, lọc, đánh dấu đọc, mở trang đích |
| Trợ giúp | FAQ, gửi ticket, xem lịch sử phản hồi |

### Khách/người thuê

| Trang | Chức năng |
|---|---|
| Khám phá | Tìm kiếm, bộ lọc, danh sách/map nếu có |
| Chi tiết nhà | Ảnh, địa chỉ hiển thị phù hợp, nội quy, dịch vụ, danh sách phòng |
| Chi tiết phòng | Giá/diện tích/tiện nghi/ảnh/trạng thái chữ và màu |
| Yêu cầu xem | Chọn giờ, ghi chú, gửi/hủy |
| Hộp thư/chi tiết hội thoại | Danh sách chat, gửi tin/tệp, lịch xem liên quan |
| Trang thuê của tôi | Hợp đồng và phòng hiện tại |
| Chi tiết hợp đồng | Điều khoản, thời hạn, giá, thành viên, tệp/phụ lục |
| Thành viên phòng | Thành viên được phép, mời nếu là đại diện, theo dõi duyệt |
| Danh sách hóa đơn | Kỳ, trạng thái, hạn, số tiền |
| Chi tiết hóa đơn | Các dòng tính, chỉ số, QR/chuyển khoản, gửi minh chứng |
| Gửi minh chứng | Ảnh, số tiền, mã giao dịch, kết quả duyệt |
| Lịch sử thanh toán | Trạng thái, quyết định, lý do từ chối |
| Thông báo nhà | Thông báo người dùng được nhận |
| Sự cố | Tạo, ảnh, tiến độ, trao đổi, xác nhận/mở lại |

### Chủ trọ/quản lý

| Trang | Chức năng |
|---|---|
| Dashboard | Phòng trống/đang thuê, hóa đơn đến hạn, thanh toán chờ, sự cố mới |
| Danh sách nhà | Tạo/chọn nhà, mời nhân viên, trạng thái xác minh/tin |
| Tạo/sửa nhà | Vị trí, mô tả, tiện ích, ảnh, nội quy, bật/tắt tin |
| Sơ đồ/danh sách phòng | Lọc tầng/loại/trạng thái; thẻ có chữ trạng thái |
| Tạo/sửa phòng và loại | Mã, diện tích, giá, sức chứa, tiện nghi, ảnh |
| Dịch vụ/bảng giá | Dịch vụ, cách tính, giá hiệu lực, ghi đè theo phòng |
| Đồng hồ/chỉ số | Gắn đồng hồ, nhập chỉ số/ảnh, xem lịch sử |
| Hộp thư | Chat theo tin/phòng/hợp đồng, lịch xem |
| Yêu cầu xem | Duyệt/đổi/hủy lịch; tùy chọn giữ phòng |
| Danh sách/tạo hợp đồng | Thời hạn, giá/cọc, người đại diện, sức chứa, tài liệu |
| Chi tiết hợp đồng | Thành viên, phụ lục, lịch sử, gia hạn/kết thúc |
| Duyệt thành viên | Kiểm tra sức chứa, duyệt/từ chối có lý do |
| Tạo kỳ hóa đơn | Chọn kỳ/phòng, nhập số liệu hàng loạt |
| Rà soát/phát hành | Kiểm tra công thức, phát hành và gửi thông báo |
| Quản lý hóa đơn | Lọc chưa trả/quá hạn/đã trả, điều chỉnh có audit |
| Duyệt thanh toán | Xem minh chứng, xác nhận/từ chối kèm lý do |
| Tạo thông báo | Chọn nhà/phòng/người nhận, xem trước, gửi |
| Quản lý sự cố | Tiếp nhận, phân công, tiến độ, trao đổi, đóng |
| Tài khoản nhận tiền | Ngân hàng/QR/mẫu nội dung chuyển khoản |
| Báo cáo | Công suất, công nợ, thu theo kỳ |
| Nhân viên | Mời, đổi quyền, thu hồi quyền |

### Admin

| Trang | Chức năng |
|---|---|
| Dashboard | Ticket, báo cáo, xác minh chờ |
| Quản lý người dùng | Tìm, xem dữ liệu cần thiết, khóa/mở có lý do |
| Xác minh nhà | Tài liệu, quyết định, lý do, lịch sử |
| Kiểm duyệt/báo cáo | Xem nội dung, quyết định và phản hồi |
| Ticket hỗ trợ | Gán, trả lời, ghi chú nội bộ, đóng/mở lại |
| Audit log | Tra cứu thao tác nhạy cảm |
| Cấu hình nền tảng | Danh mục và chính sách chung |

## 8. Service và kiến trúc

### Phía Flutter

Tách UI khỏi nghiệp vụ theo feature với presentation, application, domain, data:

- **Page/Widget:** hiển thị và nhận thao tác, không tự tính tổng tiền hay quyền.
- **Controller/ViewModel/Notifier:** gọi use case, quản lý loading/success/error.
- **Use case/Application service:** một hành động như phát hành hóa đơn hoặc duyệt lời mời.
- **Repository interface:** hợp đồng đọc/ghi độc lập backend.
- **Repository implementation/API client:** gọi backend, parse DTO, phân trang.
- **Router/Guard:** điều hướng theo phiên/role để UX; backend vẫn enforce quyền.

Chọn thống nhất state management và dependency injection trước khi mở rộng; đặc tả không khóa package cụ thể.

### Service nghiệp vụ/API

| Service | Trách nhiệm |
|---|---|
| AuthService | Đăng ký/đăng nhập/đăng xuất, khôi phục và xác minh |
| ProfileService | Hồ sơ, tùy chọn, yêu cầu xóa/ẩn danh |
| AuthorizationService | Quyền theo user/property/lease/resource ở server |
| PropertyService | Nhà, nhân sự, quyền, xác minh |
| RoomService | Loại/phòng, ảnh, tiện nghi, sức chứa |
| ListingService | Đăng/tạm dừng/tìm kiếm/kiểm duyệt |
| ViewingService | Yêu cầu xem, đổi lịch, hủy, giữ chỗ hết hạn |
| MessagingService | Hội thoại, tin, đọc, tệp, báo cáo |
| LeaseService | Tạo/kích hoạt/gia hạn/kết thúc, tài liệu/phụ lục |
| LeaseMemberService | Mời, xác nhận, duyệt, kiểm tra sức chứa, rời phòng |
| PricingService | Dịch vụ và giá hiệu lực/ghi đè phòng |
| MeterReadingService | Nhập/điều chỉnh chỉ số, ảnh, cảnh báo bất thường |
| BillingService | Preview, tính dòng, phát hành, quá hạn, điều chỉnh/thay thế |
| PaymentService | Nhận bằng chứng, duyệt/từ chối, đối soát, idempotency |
| AnnouncementService | Gửi theo phạm vi và snapshot người nhận |
| NotificationService | Inbox, push/email/SMS, retry và chống gửi trùng |
| IncidentService | Tạo, phân công, cập nhật, trao đổi, đóng/mở lại |
| SupportService | Ticket, gán admin, phản hồi |
| AdminService | Xác minh, kiểm duyệt, khóa tài khoản và audit |
| MediaService | Upload URL có hạn, validate MIME/dung lượng và quyền xem |
| AuditService | Ghi sự kiện append-only |
| ReportService | Báo cáo/export có phân quyền |

Repository phía app tương ứng: AuthRepository, PropertyRepository, RoomRepository, ListingRepository, ViewingRepository, ConversationRepository, LeaseRepository, InvoiceRepository, PaymentRepository, AnnouncementRepository, IncidentRepository, SupportRepository, MediaRepository, NotificationRepository.

Lỗi API cần phân loại thống nhất: unauthorized, forbidden, not found, validation, conflict, network, server. Danh sách lớn dùng pagination/filter phía server.

### API contract gợi ý nếu dùng REST

~~~text
POST /auth/register                         POST /auth/login
GET  /me                                    PATCH /me
GET  /properties                            POST /properties
GET  /properties/{id}                       PATCH /properties/{id}
GET  /properties/{id}/rooms                 POST /properties/{id}/rooms
POST /rooms/{id}/viewing-requests           PATCH /viewing-requests/{id}
GET  /conversations                         POST /conversations/{id}/messages
POST /leases                                GET /leases/{id}
POST /leases/{id}/member-invitations        POST /member-invitations/{id}/decision
POST /leases/{id}/readings                  POST /leases/{id}/invoices/preview
POST /invoices/{id}/issue                   GET  /invoices/{id}
POST /invoices/{id}/payment-submissions     POST /payments/{id}/decision
POST /properties/{id}/announcements         GET  /notifications
POST /incidents                             PATCH /incidents/{id}
POST /support-tickets                       POST /media/upload-url
~~~

Phát hành hợp đồng/hóa đơn, duyệt thành viên và thanh toán phải validate quyền và transaction tại server. Dùng idempotency key cho lệnh có thể bị gửi lại do mạng.

## 9. Tác vụ nền và sự kiện

| Sự kiện | Hành động |
|---|---|
| Hợp đồng sắp hết hạn | Nhắc chủ trọ/người thuê theo mốc cấu hình |
| Đến ngày chốt kỳ | Tạo danh sách phòng cần nhập chỉ số; không phát hành thiếu số liệu |
| Hóa đơn phát hành | Tạo notification cho thành viên hợp đồng |
| Hóa đơn quá hạn | Nhắc theo chính sách, chống gửi lặp |
| Lời mời hết hạn | Đánh dấu expired, giải phóng slot |
| Room hold hết hạn | Giải phóng phòng, thông báo liên quan |
| Sự cố đổi trạng thái | Báo người gửi và quản lý được giao |
| Admin xử lý tài khoản/tin | Audit và gửi thông báo phù hợp |

Job cần retry an toàn, khóa chống trùng, timezone rõ, log lỗi và theo dõi.

## 10. Bảo mật và phi chức năng

- Enforce quyền server-side; kiểm tra tenant khác, landlord khác và admin trong test phân quyền.
- File giấy tờ/hóa đơn dùng signed URL ngắn hạn; giới hạn MIME/dung lượng, quét file nếu có.
- Hạn chế truy cập số điện thoại, địa chỉ chính xác, tài khoản ngân hàng, giấy tờ.
- Audit mọi đổi quyền, hợp đồng, giá, chỉ số, hóa đơn, thanh toán và khóa tài khoản.
- Transaction cho cấp phòng, slot thành viên, lập hóa đơn và xác nhận thanh toán.
- Loading/empty/error/retry, hỗ trợ mạng yếu; retry không tạo bản ghi trùng.
- Tiếng Việt, tiền VND, timezone nhà trọ; màu trạng thái có tương phản và luôn kèm chữ.
- Có backup, retention, khôi phục và quy trình xử lý sự cố trước vận hành thật.

## 11. Lộ trình đề xuất

1. **Lõi quản lý:** auth/phân quyền, nhà/phòng/loại, nhân viên, hợp đồng/thành viên, giá/dịch vụ, chỉ số, hóa đơn, inbox.
2. **Tìm phòng và tương tác:** tin đăng/tìm kiếm, chat, lịch xem/giữ phòng, mời thành viên, minh chứng/duyệt thanh toán, sự cố.
3. **Vận hành:** admin/ticket/kiểm duyệt, báo cáo, push/email, export, đồng hồ chung, thanh toán một phần/hoàn tiền, tích hợp đối soát nếu chọn.

Không đưa dữ liệu thật lên app trước khi có server authorization, lưu tệp an toàn và transaction; mock data chỉ dành cho prototype.

## 12. Quyết định cần chốt

1. Backend/auth/database/file storage và môi trường dev/staging/prod.
2. Một hợp đồng thuê nguyên phòng hay nhiều hợp đồng/giường trong một phòng.
3. Ai mời/duyệt thành viên, lời mời giữ chỗ bao lâu, có phụ lục không.
4. Ngày chốt kỳ, cách tính giữa tháng, phí theo đầu người, đồng hồ chung.
5. Thanh toán một phần hay đủ một lần; xác nhận thủ công hay tích hợp ngân hàng.
6. Quy trình xác minh nhà/tin và chính sách kiểm duyệt.
7. Kênh thông báo và thời hạn lưu hội thoại/chứng từ.
8. Ai được xem địa chỉ/số điện thoại/thông tin thành viên.

## 13. Tiêu chí hoàn thành nghiệp vụ

- Một tài khoản có nhiều vai trò nhưng chỉ một hồ sơ; không đọc/sửa ngoài phạm vi.
- Không tạo hợp đồng trùng phòng hoặc vượt sức chứa khi có hai thao tác đồng thời.
- Đổi giá không sửa hóa đơn cũ; hóa đơn giải thích được từ snapshot/dòng tính.
- Ảnh chuyển khoản không tự xác nhận đã nhận tiền; quyết định có người, thời gian, lý do.
- Mời/duyệt/từ chối/hết hạn/rời phòng cập nhật đúng số người và còn lịch sử.
- Tin đăng, lịch xem, chat, thông báo, sự cố có quyền truy cập đúng.
- Retry không tạo hợp đồng/hóa đơn/thanh toán trùng.
- Admin xử lý hỗ trợ/vi phạm có audit, không tùy ý sửa giao dịch.

## 14. Sơ đồ quan hệ khái quát

~~~mermaid
erDiagram
  USERS ||--o{ PROPERTY_STAFF : manages
  PROPERTIES ||--o{ PROPERTY_STAFF : has
  PROPERTIES ||--o{ ROOMS : contains
  ROOM_TYPES ||--o{ ROOMS : classifies
  PROPERTIES ||--o{ SERVICE_CATALOG : defines
  SERVICE_CATALOG ||--o{ SERVICE_RATES : priced_by
  ROOMS ||--o{ LEASES : leased_under
  LEASES ||--o{ LEASE_MEMBERS : includes
  USERS ||--o{ LEASE_MEMBERS : joins
  LEASES ||--o{ MEMBER_INVITATIONS : invites
  LEASES ||--o{ INVOICES : billed_by
  INVOICES ||--o{ INVOICE_LINES : contains
  INVOICES ||--o{ PAYMENT_SUBMISSIONS : paid_with
  METERS ||--o{ METER_READINGS : records
  CONVERSATIONS ||--o{ MESSAGES : contains
  USERS ||--o{ CONVERSATION_MEMBERS : participates
  PROPERTIES ||--o{ ANNOUNCEMENTS : publishes
  USERS ||--o{ NOTIFICATIONS : receives
  ROOMS ||--o{ INCIDENTS : has
  INCIDENTS ||--o{ INCIDENT_UPDATES : tracks
~~~

