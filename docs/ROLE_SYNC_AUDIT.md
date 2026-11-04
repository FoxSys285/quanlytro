# Kiểm tra đồng bộ ba vai trò — 04/11/2026

## Nguồn dữ liệu và định danh

Mặc định ứng dụng đăng nhập Firebase Authentication rồi lấy vai trò tại `users/{uid}`. Chủ trọ quản lý nhà có `ownerUid` của mình; người thuê truy vấn `tenantIds` chứa `users/{uid}.tenantId`; admin đọc toàn bộ để quản trị. Một số điện thoại, tên hoặc mã phòng không được dùng thay khóa người thuê. Hợp đồng mới có trường mã người thuê để nối đúng tài khoản; người ở ghép được tìm qua thành viên đã duyệt.

Firestore là nguồn chung. Android/desktop giữ SQLite riêng theo UID; web đọc Firestore trực tiếp. Không lấy cache tài khoản khác, không đăng nhập bằng mật khẩu demo khi Firebase từ chối. `USE_FIREBASE_AUTH=false` chỉ dành bản legacy đối chiếu, sẽ không đồng bộ được sau khi Rules khóa `app_documents`.

## Lỗi đã sửa

| Luồng | Lỗi trước đây | Cách xử lý |
|---|---|---|
| Tenant ở trang con | Constructor mặc định dùng `tenant-demo` | Lấy `currentTenantId` tại runtime, vẫn cho test truyền ID rõ ràng |
| Hồ sơ tenant | Sửa hồ sơ cá nhân đồng thời sửa hợp đồng và bị Rules từ chối | Hồ sơ cá nhân lưu `user_state`; giấy tờ hợp đồng do chủ trọ/admin quản lý |
| Thanh toán, sự cố, lịch xem, thành viên | Bộ đếm cục bộ có thể trùng giữa hai thiết bị | ID ngẫu nhiên 128-bit cho yêu cầu mới |
| Duyệt thanh toán | Chia transaction có thể lưu thanh toán mà chưa cập nhật hóa đơn; hai lần duyệt có thể mất lần cộng tiền | Một transaction cho cả lần lưu; hợp đồng/hóa đơn/thanh toán kiểm tra phiên bản nghiêm ngặt |
| Đồng thời sửa dữ liệu | Lưu cả snapshot dễ đụng các trường không đổi | Chỉ xuất thay đổi so với bản client đã chuẩn hóa; hợp nhất trường độc lập, báo xung đột cùng trường |
| Nhận dữ liệu thiết bị khác | Chỉ tải lúc đăng nhập | Listener theo quyền, debounce, hàng đợi đọc/ghi; giữ store và nhà đang mở; không thay chỉnh sửa chưa lưu |
| Chat đang mở / gửi cùng lúc | Snapshot thay object khiến trang chat giữ bản cũ; hai thiết bị có thể cùng lấy index làm ID | Giữ object hội thoại tại chỗ; mỗi tin mới có ID riêng, timestamp và thứ tự gốc; không sửa document tin cũ |
| Xung đột | Phải đóng app để lấy lại bản server | Banner có thử lưu và tải bản mới; tải bỏ chỉnh sửa cần người dùng xác nhận |
| Thông báo | Codec hiểu sai khóa trạng thái đọc, chủ trọ có thể ghi mất lượt đọc tenant | Dùng map theo tenantId; hợp nhất lượt đọc từ projection riêng |
| Admin ẩn tin | Chủ trọ lưu lại có thể bật tin hoặc tạo phòng né nhà bị ẩn | Giữ cờ công bố ở nhà và phòng; Rules kiểm tra quyền moderation |
| Xóa dữ liệu | Record đã bỏ khỏi snapshot vẫn tồn tại hoạt động | Archive record; phòng bị gỡ chuyển không công bố/không khả dụng; không xóa lịch sử tin nhắn |
| Khóa tài khoản | Admin chỉ xem tài khoản cloud | Admin sửa riêng `disabled` của tài khoản khác; không tự khóa hoặc sửa role/tenantId; permission-denied kết thúc phiên |

Mỗi lần lưu ứng dụng giới hạn 400 document để tránh chia nhỏ một nghiệp vụ. Bộ import danh mục giới hạn 450 document/đợt nguyên tử và chỉ tạo nhà mới. Khi vượt giới hạn, công cụ dừng trước khi ghi; chia đợt nhập theo nhà.

## Dữ liệu Firebase đã chuyển

Đã sao lưu dữ liệu legacy hiện tại vào `.dart_tool/demo_data/`, không bổ sung dữ liệu mẫu. Đã xuất bằng codec ứng dụng, ghi có điều kiện phiên bản và đọc lại kiểm tra **2.071 document**:

| Collection | Số document |
|---|---:|
| `rental_properties` | 10 |
| `public_rooms` | 454 |
| `rental_records` | 1.599 |
| `users` | 3 |
| `management` | 2 |
| `support_tickets` | 2 |
| `public_settings` | 1 |

Ba UID do người dùng cung cấp đã được gán admin/tenant/landlord theo ảnh Firebase Authentication; tenant nối với `tenant-demo` hiện có. Không thay mật khẩu, không đưa UID cấu hình hoặc bản sao lưu nghiệp vụ lên Git. Collection legacy được giữ để đối chiếu.

## Kiểm tra

- Bộ Flutter toàn dự án ở lượt cuối: **250 test PASS**; `flutter analyze --no-pub`: **No issues found**.
- Kiểm tra bổ sung sau khi bật cloud mặc định: runtime refresh, auth boundary, widget và cloud admin guards PASS.
- Firestore Emulator (`demo-quanlytro`, không phải production): kiểm quyền công khai/riêng, truy vấn theo tenant/owner, chống nâng role, khóa tài khoản, duyệt tiền, tin nhắn bất biến, nhà bị ẩn và tạo nhà/phòng cùng transaction PASS.
- Import Excel: **4 Python test PASS**, gồm validation, workbook → codec Firestore, SQLite add-only/backup/giữ dữ liệu cũ và đăng nhập admin nhập mật khẩu ẩn, từ chối tài khoản sai quyền.
- Workbook có bốn sheet nhập trống và hai sheet hướng dẫn/ví dụ; đã xem preview cả sáu sheet. Chưa kiểm trên Excel desktop.
- APK cloud debug mới nhất sau khi hoàn thiện giao diện: `build/app/outputs/flutter-apk/app-cloud-debug.apk`. SHA256: `f53a279356b1c6ae9f76cbc40b8635e2f6f5d6087f76ca143036c93835bd782d`.

Lệnh chạy lại:

```powershell
flutter analyze --no-pub
flutter test --no-pub
python -m unittest discover -s test -p test_rental_import.py
node tool/firestore_rules_test.cjs
flutter build apk --debug --no-pub --dart-define=USE_FIREBASE_AUTH=true
```

Lệnh Node cần Firestore Emulator đang chạy cổng 8080 và dependencies trong `.dart_tool/firebase_tools/`. Không chạy kiểm quyền trên dữ liệu production.

## Bước triển khai và giới hạn thực tế

Firebase CLI chưa có credentials quản trị; lần deploy CLI bị từ chối xác thực. Người dùng đã Publish Rules bằng Console. Kiểm tra REST production không đăng nhập xác nhận `public_rooms` và `rental_properties` đọc được; `rental_records`, `users`, `app_documents/portfolio` đều trả **403**. Đây là kiểm tra ranh giới công khai/riêng; không thay thế thử đăng nhập với từng role. Nếu `firestore.rules` được chỉnh tiếp sau thời điểm Publish, cần Publish lại bản cuối.

Chưa đăng nhập ba tài khoản trên thiết bị thật vì mật khẩu do người dùng giữ. Widget/test và Emulator không chứng minh độ mượt theo FPS hoặc trạng thái server production. Sau khi Publish Rules, cần chạy APK mới trên hai thiết bị: tenant gửi lịch xem/thanh toán/sự cố/tin nhắn, chủ trọ xử lý, tenant thấy kết quả; admin ẩn nhà và khóa tài khoản để kiểm tra phản ánh ở hai role còn lại.

Khóa bằng `users.disabled` chặn quyền dữ liệu ứng dụng, không xóa tài khoản Firebase Auth hoặc thu hồi refresh token qua Admin SDK. Tài khoản chưa được cấp vai trò vẫn không vào dữ liệu riêng. Chủ trọ/admin hoàn toàn chưa có nhà chưa có màn onboarding rỗng; đợt chuyển hiện tại đã cấp 10 nhà cho chủ trọ được chỉ định.

Giao diện admin chung/dashboard của Anti được review và tích hợp cùng lượt hoàn thiện Users/Commission tiếp theo. Các thay đổi chat tenant/yêu thích và generated Windows được giữ riêng, không đưa vào commit giao diện admin.

## Hoàn thiện giao diện Users/Commission

Đã gom nhóm bộ lọc tài khoản, thống nhất theme và màu trạng thái, hiển thị trạng thái đang khóa/mở, làm rõ bảng tiền đối soát và kết quả tìm kiếm rỗng. Các phép tính hoa hồng và hành động nghiệp vụ được giữ nguyên. Tương phản chữ badge với nền được kiểm tra cho bảng màu hiện tại (tối thiểu 4,85:1).

Kiểm tra widget bao phủ 320/390/768/1440px; 320px có chữ 130%. Đã sửa ảnh thẻ dashboard co lại theo chỗ còn trống để không đẩy chữ tràn khỏi thẻ. Ảnh review được render từ widget Flutter ở 390px và 1440px trong `.impeccable/review/`; đây không phải ảnh chụp từ Android emulator. Hiện không có thiết bị nào trong `adb devices`.

Lượt cuối của phần giao diện: **18 test admin PASS**, gồm tìm kiếm/lọc, trạng thái rỗng, chỉnh hồ sơ, khóa/mở tài khoản, kiểm tra đối soát và render preview. Analyze toàn dự án sạch; APK cloud debug build thành công. Không chạy lại ghi dữ liệu production trong lượt giao diện này.

Mẫu nhập và cách dùng: [DATA_IMPORT.md](DATA_IMPORT.md). Đối chiếu kỹ thuật: [Firestore listeners](https://firebase.google.com/docs/firestore/query-data/listen), [transactions](https://firebase.google.com/docs/firestore/manage-data/transactions), [Firebase Auth](https://firebase.google.com/docs/auth/flutter/password-auth).
