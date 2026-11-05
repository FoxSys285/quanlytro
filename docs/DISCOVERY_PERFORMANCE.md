# Tối ưu trang Khám phá

## Điều hướng và làm mới

- Tab Khám phá được giữ trong `RoleLayoutShell` bằng `IndexedStack`, khởi tạo khi mở lần đầu. Khi chuyển sang tab khác rồi quay lại, dữ liệu, bản đồ và vị trí cuộn được giữ trong phiên hiện tại.
- Kéo xuống đầu trang để làm mới bằng `RefreshIndicator`. Yêu cầu đồng thời được gộp, không gửi nhiều lần vì kéo liên tiếp.
- Khi làm mới, danh sách cũ tiếp tục hiển thị. Nếu mạng lỗi, app giữ danh sách và thông báo có thể thử lại.

## Giới hạn truy vấn

- Mỗi mục xem trước tối đa **10 phòng**. Nổi bật và giá tốt dùng truy vấn riêng; mục đáng tin cậy lấy tối đa 10 hồ sơ đã xác minh rồi tối đa 10 phòng thuộc các nhà đó. Mục gần bạn dùng lại tập xem trước; thao tác chọn vị trí mở danh sách khu vực riêng.
- Trang danh sách phòng giữ phân trang **8 phòng/trang**, dùng con trỏ Firestore. Trang trước dùng dữ liệu đã nạp trong màn hình, không truy vấn lại.
- Truy vấn thường đọc thêm 1 bản ghi để biết có trang tiếp theo. Không suy ra rằng cả trang Khám phá chỉ đọc tổng cộng 10 tài liệu: mỗi mục có truy vấn riêng và mục xác minh cần đọc hồ sơ để kiểm tra dấu xác minh.
- `published`, `available`, nhà trọ được chọn, khu vực và thứ tự giá/diện tích được áp dụng trong truy vấn Firebase trước khi phân trang. Các tên khu vực phổ biến từ GPS được quy về các cách viết tương ứng đang lưu.
- Firestore không hỗ trợ tìm chuỗi con trực tiếp. Từ khóa và các điều kiện còn lại được lọc trong các lô nhỏ, tối đa **64 tài liệu phòng** hoặc **48 tài liệu nhà trọ** cho một lần yêu cầu. Khi còn dữ liệu, app trả con trỏ để tiếp tục; không quét hết kho dữ liệu trong một lần tải. Trang lọc ít kết quả có thể chưa đủ số phòng và vẫn có trang sau.
- Truy vấn dùng `Source.server` để kéo làm mới thật sự lấy dữ liệu mới. Bộ nhớ của màn hình đảm nhiệm việc hiển thị tức thì khi quay lại tab.

## Đồng bộ dữ liệu người thuê

- Bỏ truy vấn và lắng nghe toàn bộ `rental_properties` cho người thuê. Chỉ tải các nhà được tham chiếu trong dữ liệu nghiệp vụ của chính tài khoản, theo nhóm mã tài liệu.
- Khi mở chi tiết phòng khác, chỉ tải hồ sơ nhà đó để hiển thị chủ nhà và liên hệ. Không thêm toàn bộ danh mục công khai vào hồ sơ đang thuê.
- Khi tạo chat hoặc lịch xem tại nhà mới, repository tải đúng nhà đích lúc lưu để giữ liên kết chủ sở hữu và tin nhắn. Người thuê không xuất bản lại thông tin nhà trọ/phòng.

## Chỉ mục và kiểm tra

Chỉ mục được lưu ở `firestore.indexes.json`, liên kết trong `firebase.json`. Công cụ `tool/ensure_discovery_indexes.py` chỉ tạo chỉ mục thiếu; không xóa chỉ mục và không triển khai Firestore Rules.

Đã kiểm tra truy vấn thật trên `tropremium-d14ac`, gồm giá, diện tích, nhà trọ được chọn, xác minh và tỉnh/phường. Kiểm thử đo giới hạn đọc, không trùng phòng khi chuyển trang, giữ trạng thái tab, cử chỉ làm mới, lỗi mạng và lưu chat/lịch xem mới.

```powershell
flutter test test/discovery_refresh_test.dart test/discovery_read_budget_test.dart test/remote_discovery_test.dart test/tenant_properties_test.dart test/catalog_pagination_test.dart test/tenant_room_details_test.dart test/tenant_gps_search_test.dart test/room_conversation_test.dart test/viewing_workflow_test.dart test/cloud_catalog_codec_test.dart test/role_drawer_test.dart
node tool/with_firebase_cli.cjs tool/check_discovery_queries.py
```

Bộ kiểm thử trên đạt 70 test. Phân tích tĩnh các file liên quan không có lỗi; APK debug build thành công tại `build/app/outputs/flutter-apk/app-debug.apk`.
