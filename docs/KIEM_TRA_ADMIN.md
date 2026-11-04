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
2. **Khóa tài khoản Firebase:** `firestore.rules` hiện cấm client ghi `users`; cần luồng backend có kiểm tra quyền admin. Bản cập nhật không thay rule, không cấp quyền và không thao tác dữ liệu máy chủ.
3. **Xác minh pháp lý:** mô hình nhà trọ chưa có giấy tờ sở hữu/ủy quyền. Duyệt hiện tại chỉ xác minh thông tin cơ bản; không được gọi là đã kiểm tra pháp lý.
4. **Gửi yêu cầu bổ sung qua Firebase:** cần projection/kênh nhận riêng cho đúng chủ nhà trọ. Không mở quyền đọc toàn bộ cấu hình quản trị cho chủ trọ.

## Kiểm tra

Các bài kiểm tra mới dùng đối tượng trong bộ nhớ và JSON, không mở SQLite/Firebase, không sửa dữ liệu thật. Kiểm tra giao diện tại 320, 390, 768 và 1440 px; kiểm tra điều hướng, tìm kiếm, khóa/mở local, xác minh thiếu hồ sơ, thay đổi sau xác minh, tính tiền, duyệt thu muộn, chốt trùng, thu vượt và khôi phục trạng thái.

Vòng giao diện trước có 23 bài kiểm tra đạt. Vòng dữ liệu mẫu bổ sung kiểm tra lưu/khôi phục, lỗi ghi local, phân trang, sửa thông tin người đại diện và đổi tháng khi tải bộ mẫu khác. Đã xem ảnh Flutter widget của tổng quan, hồ sơ nhanh, tài khoản, xác minh, hoa hồng và hoạt động. Bài kiểm tra xác nhận lệnh âm chạm/rung được gửi qua platform channel, chữ lớn 1,3 lần và giảm chuyển động không gây tràn giao diện. Chưa kiểm tra âm/rung hoặc hiệu năng trên thiết bị Android thật.

```powershell
flutter analyze --no-pub
flutter test --no-pub test/admin_demo_test.dart test/admin_workflow_test.dart test/admin_ui_test.dart test/role_drawer_test.dart test/portfolio_ui_test.dart --dart-define=ADMIN_PREVIEW=true
```

Tạo ảnh kiểm tra từ widget, không chạy `main()` hay kết nối database:

```powershell
flutter test --no-pub test/admin_ui_test.dart --dart-define=ADMIN_PREVIEW=true
```

Ảnh tổng quan nằm trong `build/admin_preview/admin_390.png`; các trạng thái trong `.impeccable/review/phone-widget*.png`. Việc kiểm tra widget không chứng minh kết nối Firebase, SQLite, ngân hàng hay chạy trực tiếp trên điện thoại thật.

Phản hồi trong admin dùng ripple Material, âm chạm hệ thống, rung nhẹ khi chọn/xác nhận, chuyển mục 180 ms và bottom sheet 260/180 ms. Không có âm phát tự động, không thêm thư viện âm thanh; âm chạm còn phụ thuộc cài đặt âm lượng/âm hệ thống của Android.

## Dữ liệu mẫu có thể chỉnh và lưu Firebase

- Chọn **Dùng demo** trong admin. Bộ mẫu có 10 nhà trọ, hồ sơ thuê, 24 tài khoản mô phỏng và ba kỳ hoa hồng tính tương đối theo thời điểm tạo mẫu. Có đủ trạng thái chưa đặt tỷ lệ, chưa chốt, chờ thu, thu một phần và thu đủ. Tài khoản mẫu không phải tài khoản đăng nhập; số 17 phiên là minh họa và được ghi rõ trên UI.
- **Người dùng → Người thuê → chạm hồ sơ → Sửa hồ sơ mẫu** để đổi tên/điện thoại. Người đại diện lưu vào hợp đồng gốc của bộ mẫu; thành viên lưu vào hồ sơ. Khóa/mở tài khoản mẫu và thay đổi hoa hồng tự lưu local, tách khỏi dữ liệu nghiệp vụ đang dùng.
- **Hoa hồng → chạm nhà trọ → Đặt tỷ lệ → Chốt kỳ → Ghi nhận tiền** để thử quy trình. Có tìm kiếm, lọc trạng thái, thẻ thu gọn kèm ảnh; hướng dẫn nằm trong “Cơ sở tính”. Hồ sơ thuê chia trang 12 người.
- Chạm **biểu tượng đám mây** trên thanh demo: **Lưu Firebase** gửi bản chụp bộ mẫu; **Tải Firebase** xác nhận trước khi thay bộ mẫu trên máy. App chỉ báo đã lưu khi có kết quả thành công; lỗi mạng/quyền hoặc lỗi lưu local có thông báo. Tải bộ mẫu khác tháng sẽ chọn đúng tháng của bộ vừa tải.
- Luồng legacy dùng `app_documents/admin_demo` và `app_documents/admin_demo:<propertyId>`, theo envelope JSON `payload` hiện có. Khi chạy chế độ Firebase Auth, dùng `management/admin_demo_<uid>` và các document nhà trọ tương ứng. Một batch gồm manifest và từng nhà trọ; kiểm tra generation tránh ghép lẫn hai bản tải. Giới hạn 800.000 byte JSON mỗi phần để chừa chỗ dưới giới hạn document Firestore; không thay `admin`, `auth`, `portfolio` hoặc xuất tin demo vào `public_rooms`.
- Không đổi hoặc deploy Rules. Quyền thực tế do máy chủ quyết định; `firestore.rules` trong repo hiện cấm `app_documents`, còn `management` cần Firebase admin. Ảnh Console có document `admin` không chứng minh client được quyền ghi. Chưa xác nhận ghi/tải Firebase thật trong vòng này vì không có thiết bị Android hay kết nối điều khiển Console.

Tài liệu chính thức: [Firestore batch nguyên tử](https://firebase.google.com/docs/firestore/manage-data/transactions), [giới hạn Firestore](https://firebase.google.com/docs/firestore/quotas). APK debug nằm tại `build/app/outputs/flutter-apk/app-debug.apk`. Các bài test không ghi database thật.
