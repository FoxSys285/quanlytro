# Rà soát và cập nhật admin — 04/11/2026

Đối chiếu `HeThongQuanLyKhachThueTro.docx`, mã nguồn hiện tại và yêu cầu bổ sung trong cuộc trao đổi. Word mô tả quản trị tài khoản, giám sát và báo cáo tổng hợp; chưa mô tả hoa hồng hoặc số người đang mở ứng dụng. Bản Word không bị sửa.

| Yêu cầu | Kết quả và phạm vi |
| --- | --- |
| Giao diện Modern Premium | Admin Android: header navy có ảnh, nền sáng, nút periwinkle, ảnh nhà trọ vuốt ngang và hồ sơ nhanh dạng bottom sheet. Không làm giao diện web. Không dùng số tăng trưởng hoặc biểu đồ giả. |
| Số lượng người dùng | Thống kê tài khoản riêng với hồ sơ người thuê. Local lấy tài khoản thực sự đã khởi tạo; Firebase đọc collection `users` bằng quyền admin. |
| Quản lý tài khoản | Tìm tên/email/mã, lọc vai trò và trạng thái, phân trang. Khóa/mở local có xác nhận, kiểm tra quyền và nhật ký. Không cho khóa admin hiện tại. Firebase chỉ đọc, không tự thay đổi quyền. |
| Xác minh nhà trọ | Kiểm tra tên, địa chỉ, chủ trọ, điện thoại, mô tả, ảnh, danh sách phòng, diện tích/sức chứa/giá. Thiếu dữ liệu thì không thể xác minh. Có yêu cầu bổ sung và thu hồi xác minh. Thông tin thay đổi thì trạng thái cũ không còn hợp lệ. |
| Yêu cầu bổ sung | Lưu lý do trong trạng thái admin; chủ trọ xem được trên màn thông tin/danh sách nhà trọ trong luồng local. Chưa có kênh gửi yêu cầu này xuyên tài khoản Firebase. |
| Hoa hồng hàng tháng | Đặt tỷ lệ riêng từng nhà trọ, xem dự kiến, chốt kỳ đã kết thúc, ghi nhận thu từng phần hoặc toàn bộ bằng chứng từ, xem đã nhận/còn phải thu và lịch sử. Dữ liệu dùng chung cơ chế lưu trạng thái admin hiện có. |
| Người đang mở app | Có theo dõi foreground/background và phiên đăng nhập **trên thiết bị hiện tại**. Chưa có thống kê người online toàn hệ thống. UI ghi rõ phạm vi, không suy diễn online từ số tài khoản. |
| Chức năng đang có | Giữ hỗ trợ, ẩn/hiện tin Khám phá, nhật ký, cài đặt, hồ sơ và thông báo tài khoản. Đổi tên “Kiểm duyệt và báo cáo” thành “Kiểm duyệt tin đăng” đúng chức năng thực tế. |

## Quy ước hoa hồng đang áp dụng

- Không tự gán tỷ lệ mặc định. Admin nhập tỷ lệ 0–100%, lưu đến hai chữ số thập phân.
- Chỉ tính khoản thanh toán `approved`, loại hóa đơn hủy và chứng từ không còn hóa đơn.
- Cơ sở tính là phần **tiền thuê phòng** của khoản đã duyệt; phân bổ khoản trả từng phần theo tỷ lệ tiền phòng / tổng hóa đơn. Loại điện, nước, dịch vụ.
- Xếp tháng theo ngày duyệt thu `reviewedAt`; dữ liệu cũ thiếu ngày duyệt dùng `paidAt`. Khoản báo trả cuối tháng nhưng duyệt đầu tháng sau thuộc tháng sau, tránh bỏ sót trong kỳ đã chốt.
- Số tiền VND và phần trăm tính bằng số nguyên, làm tròn đến đồng. Chốt từng nhà trọ/tháng một lần; giữ nguyên cơ sở, tỷ lệ và số phải thu của kỳ đó.
- Nhận tiền yêu cầu số tiền dương, không vượt số còn phải thu, có mã chứng từ và không trùng mã trong cùng kỳ. Đây là sổ ghi nhận sau đối chiếu thực tế, không phải thanh toán ngân hàng tự động.
- Chưa có nghiệp vụ hoàn tiền/điều chỉnh kỳ đã chốt. Nhóm cần thống nhất cơ sở thu hoa hồng này trước khi dùng với tiền thật.

## Các phần backend còn thiếu

1. **Online toàn hệ thống:** cần dịch vụ presence theo tài khoản/phiên, xử lý mất mạng và hết hạn phiên. Hướng chính thức của Firebase dùng Realtime Database và Cloud Functions để phản chiếu trạng thái sang Firestore: [Firebase presence](https://firebase.google.com/docs/firestore/solutions/presence). Không thể coi “đăng nhập gần nhất” là đang mở app.
2. **Khóa tài khoản Firebase:** `firestore.rules` hiện cấm client ghi `users`; cần luồng backend có kiểm tra quyền admin. Chưa triển khai backend khóa tài khoản; không đổi Rules hoặc quyền.
3. **Xác minh pháp lý:** mô hình nhà trọ chưa có giấy tờ sở hữu/ủy quyền. Duyệt hiện tại chỉ xác minh thông tin cơ bản; không được gọi là đã kiểm tra pháp lý.
4. **Gửi yêu cầu bổ sung qua Firebase:** cần projection/kênh nhận riêng cho đúng chủ nhà trọ. Không mở quyền đọc toàn bộ cấu hình quản trị cho chủ trọ.

## Kiểm tra

Các bài kiểm tra mới dùng đối tượng trong bộ nhớ và JSON, không mở SQLite/Firebase, không sửa dữ liệu thật. Kiểm tra giao diện tại 320, 390, 768 và 1440 px; kiểm tra điều hướng, tìm kiếm, khóa/mở local, xác minh thiếu hồ sơ, thay đổi sau xác minh, tính tiền, duyệt thu muộn, chốt trùng, thu vượt và khôi phục trạng thái.

Vòng dữ liệu hiện tại kiểm tra sửa trực tiếp hồ sơ đại diện/thành viên, cùng một snapshot được lưu local và gửi lên remote, lỗi Firebase phải hiện rõ, thử lại thành công và không tạo dữ liệu giả khi thiếu bản lưu. Kiểm tra SQLite dùng thư mục tạm trong workspace. Bài kiểm tra giao diện xác nhận phân trang, sửa hồ sơ, điều hướng, phản hồi platform channel, chữ lớn và giảm chuyển động. Chưa kiểm tra âm/rung hoặc hiệu năng trên thiết bị Android thật.

```powershell
flutter analyze --no-pub
flutter test --no-pub test/admin_live_data_test.dart test/admin_workflow_test.dart test/admin_ui_test.dart test/role_drawer_test.dart test/portfolio_ui_test.dart --dart-define=ADMIN_PREVIEW=true
```

Tạo ảnh kiểm tra từ widget, không chạy `main()` hay kết nối database:

```powershell
flutter test --no-pub test/admin_ui_test.dart --dart-define=ADMIN_PREVIEW=true
```

Ảnh tổng quan nằm trong `build/admin_preview/admin_390.png`; các trạng thái trong `.impeccable/review/phone-widget*.png`. Việc kiểm tra widget không chứng minh kết nối Firebase, SQLite, ngân hàng hay chạy trực tiếp trên điện thoại thật.

Phản hồi trong admin dùng ripple Material, âm chạm hệ thống, rung nhẹ khi chọn/xác nhận, chuyển mục 180 ms và bottom sheet 260/180 ms. Không có âm phát tự động, không thêm thư viện âm thanh; âm chạm còn phụ thuộc cài đặt âm lượng/âm hệ thống của Android.

## Dữ liệu đang dùng — không có chế độ demo

- Đã bỏ `AdminDemoData`, nút “Dùng demo”, 24 tài khoản mô phỏng và chỉ số 17 phiên giả. Các trang admin dùng chung `RentalPortfolio.instance` và `AdminStore.instance` với ứng dụng.
- **Người dùng → Người thuê → chạm hồ sơ → Sửa hồ sơ** sửa trực tiếp dữ liệu liên hệ hiện tại. Người đại diện cập nhật nguồn hợp đồng; thành viên cập nhật hồ sơ. Có kiểm tra quyền admin và tên/số điện thoại hợp lệ.
- Tự lưu qua repository hiện có: legacy ghi `app_documents/portfolio` và `app_documents/admin`; chế độ Firebase Auth dùng các collection nghiệp vụ và `management/system`. Không ghi vào namespace `admin_demo` nữa. Dữ liệu cũ trong namespace đó không được chọn làm nguồn ứng dụng.
- Thanh trạng thái chỉ báo **Đã lưu dữ liệu lên Firebase** khi remote xác nhận. Lỗi mạng/quyền hiện rõ, giữ thay đổi trên máy và có nút thử lại. Không báo thành công Firebase chỉ vì SQLite ghi được. Nếu chưa có dữ liệu đã lưu thì báo lỗi, không tự sinh bộ nhà trọ/tài khoản/tin nhắn/lịch xem phòng giả.
- Hoa hồng mở tháng hiện tại và tính dự kiến từ tiền phòng trong các khoản thu đã duyệt. Chốt kỳ chỉ khi tháng kết thúc; ghi nhận tiền hoa hồng phải có số thực nhận và chứng từ, không tự giả định đã nhận.

### Dữ liệu Firebase đã cập nhật trực tiếp ngày 04/11/2026

Theo yêu cầu mỗi trọ một tỷ lệ: `may` 3%, `property-2` 3,5%, rồi tăng 0,5 điểm phần trăm mỗi nhà đến `property-10` 7,5%. Đã đọc lại document sau commit để xác nhận. Không thay hồ sơ, hóa đơn, khoản thu hay chứng từ hiện có.

Khoản thu đã duyệt hiện đều nằm trong tháng 11/2026. Tổng phần tiền phòng được tính hoa hồng là 138.075.000 đ; dự kiến hoa hồng 7.305.375 đ. Tháng 11 chưa kết thúc nên chưa tạo kỳ đã chốt; không thêm chứng từ đã nhận tiền.

`tool/initialize_admin_commissions.py` mặc định chỉ đọc/lập kế hoạch. `--apply` mới ghi; sao lưu vào `.local-backups/firestore/` (bị Git bỏ qua), bảo toàn giá trị đã có, không nhân đôi kỳ và không tạo khoản nhận tiền. Commit kiểm tra update-time của cả portfolio và admin để tránh ghi đè bản vừa thay đổi. Không sửa Rules.

Phạm vi xác minh là dữ liệu đã ghi/đọc lại, không phải bảo mật production: endpoint legacy hiện chấp nhận thao tác REST không kèm Firebase Auth. Quyền truy cập đang triển khai không được thay đổi trong tác vụ này.

```powershell
python -m unittest discover -s test -p test_admin_commission_import.py
python tool/initialize_admin_commissions.py --project doantro-caf4b
```

Ảnh kiểm tra có thể dùng snapshot đã đọc từ Firebase bằng `--dart-define=ADMIN_LIVE_SNAPSHOT=build/admin-live-backup/<thu-muc>` kèm `ADMIN_PREVIEW=true`. Snapshot/backup không đưa lên Git. Các bài test không tự ghi database thật; thao tác ghi thật đã thực hiện riêng qua script có `--apply` và được kiểm tra bằng đọc lại.
