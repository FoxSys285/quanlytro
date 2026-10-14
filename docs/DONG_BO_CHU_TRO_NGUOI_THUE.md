# Đồng bộ Chủ trọ và Người thuê

Ngày rà soát: 14/10/2026.

## Kết quả trước khi sửa

Các phần đã làm chưa đồng bộ đầy đủ. Lịch xem đã dùng `ViewingStore` chung, nhưng phần lớn các màn hình khác giữ dữ liệu riêng hoặc tạo lại dữ liệu khi mở trang.

| Nhóm | Chênh lệch phát hiện |
|---|---|
| Hợp đồng A.302 | Người thuê hiển thị HD-2026-0148, giá 3.800.000 đ, cọc 7.600.000 đ, từ 01/06/2026 đến 31/05/2027. Chủ trọ quản lý HD-2026-0302, giá/cọc 3.500.000 đ, từ 01/03/2026 đến 28/02/2027. |
| Điện, nước và dịch vụ | Người thuê dùng đơn giá viết sẵn khác với hợp đồng. Hợp đồng mẫu A.302 ghi nước theo tháng trong khi hóa đơn tính theo m³. Trang bảng giá và chỉ số giữ dữ liệu riêng, không đưa chỉ số đã lưu vào trình lập hóa đơn. |
| Thành viên | Người thuê thấy Nguyễn Minh Anh/Trần Thảo Linh và số điện thoại khác. Chủ trọ quản lý Minh Anh/Trần Thu Hà. Duyệt thành viên không cập nhật số người trong hợp đồng. |
| Hóa đơn | Hai vai trò dùng mã hóa đơn khác nhau. Chi tiết phía người thuê tự suy ra tiền thuê bằng tổng tiền trừ một khoản cố định, rồi gắn cùng một bộ điện/nước/dịch vụ cho mọi kỳ. |
| Thanh toán | Người thuê chỉ xem hướng dẫn và nút gửi minh chứng chưa có nghiệp vụ. Số tiền/mã hóa đơn trong hướng dẫn cố định; người thuê không thấy kết quả duyệt/từ chối của chủ trọ. |
| Thông báo | Chủ trọ lưu thông báo gửi thử trong trạng thái của trang. Người thuê dùng danh sách riêng, không nhận được thông báo đã gửi. |
| Sự cố | Hai vai trò giữ hai danh sách và hai cách đặt trạng thái. Gửi/xử lý/xác nhận sự cố không truyền sang bên còn lại. |
| Tin nhắn | Hai bên dùng hai danh sách tin riêng. Hội thoại mở từ lịch xem chỉ xuất hiện ở bên Chủ trọ. |
| Tin phòng | Giá, địa chỉ, ảnh và tên tin của nhà đang quản lý chưa lấy từ dữ liệu Chủ trọ. Yêu thích và đặt lịch dựa vào tên hiển thị nên dễ mất liên kết khi đổi tên. |
| Tổng quan | Số phòng, hóa đơn, doanh thu, thanh toán chờ và sự cố được viết sẵn, không phản ánh thao tác trên các trang nghiệp vụ. |

## Nguồn dữ liệu sau khi sửa

Giữ tên `LandlordDemoStore` để tương thích với các màn hình đã có; store này hiện là nguồn dữ liệu nhà/phòng, hợp đồng, thành viên, hóa đơn, thanh toán, dịch vụ, chỉ số và sự cố cho cả hai vai trò. Hội thoại và thông báo có store chung trong `lib/pages/shared/`.

| Nhóm | Trường và liên kết chung | Hành vi đã đồng bộ |
|---|---|---|
| Nhà/phòng và tin đăng | `property.id`, tên, địa chỉ, tỉnh/thành phố, phường/xã, ảnh, mô tả; mã phòng, tầng, loại, diện tích, sức chứa, giá loại phòng | Tin của nhà đang quản lý lấy trực tiếp từ dữ liệu Chủ trọ; chỉ hiển thị phòng trống có loại phòng. Thay đổi loại/giá/ảnh/khu vực cập nhật ở Khám phá và Yêu thích. |
| Định danh người thuê | `TenantSession.tenantId`, `lease.tenantId`, `lease.propertyId`, `lease.id` | Phiên xem trước dùng Minh Anh (`tenant-demo`). Đổi tên hoặc số điện thoại không làm mất liên kết với hợp đồng/hóa đơn. Hợp đồng mới cho hồ sơ đã biết giữ mã người thuê; dữ liệu không được lọc bằng tên người hoặc số phòng cố định. |
| Hợp đồng | Hai bên: tên, liên hệ, CCCD, địa chỉ; bên thuê: năm sinh, ngày cấp CCCD; phòng, thời hạn, tháng thuê, giá/cọc, ngày đóng, điện/nước, cách tính nước, tiền xe/dịch vụ, phương thức nhận tiền, ghi chú | Trang Chỗ ở và chi tiết hợp đồng lấy cùng đối tượng hợp đồng. Kết thúc hợp đồng làm mất trạng thái chỗ ở hiện tại và cập nhật phòng trống; lịch sử hóa đơn vẫn được giữ. |
| Thành viên | `member.id`, `leaseId`, `tenantId`, tên, điện thoại, ngày vào/dự kiến, vai trò, trạng thái, lý do từ chối | Người đại diện lấy từ hợp đồng, người ở cùng lấy từ danh sách thành viên. Duyệt cập nhật danh sách và số người; kiểm tra sức chứa, chặn duyệt lại. Từ chối giữ bản ghi/lý do, hiển thị cho phòng liên quan ở phía Người thuê. Số người trong form hợp đồng lấy từ thành viên đã duyệt. |
| Chỉ số và bảng giá | Định danh dịch vụ, tên, đơn vị, cách tính, giá, trạng thái; mã phòng, kỳ, chỉ số cũ/mới | Thay bảng giá áp dụng cho tin và giá mặc định của hợp đồng mới. Chỉ số lưu theo phòng/kỳ, không dùng lại số tháng 10 khi chọn tháng 9. Trình lập hóa đơn điền sẵn lượng tiêu thụ đúng phòng/kỳ nếu đã có. |
| Hóa đơn | `id`, `leaseId`, phòng/người đại diện tại lúc lập, kỳ, hạn, danh sách khoản thu, tổng, đã xác nhận, còn lại, trạng thái | Người thuê thấy đúng hóa đơn của hợp đồng mình, cùng các dòng thu và trạng thái chưa trả/một phần/đã trả/quá hạn/đã hủy. Chặn hóa đơn trùng kỳ còn hiệu lực và kỳ ngoài thời hạn thuê; mã mới không trùng lịch sử. |
| Thanh toán | `id`, `invoiceId`, số báo trả, ngày báo, phương thức, tham chiếu, ảnh/tên minh chứng, tài khoản nhận, số xác nhận, trạng thái, ngày duyệt, lý do từ chối | Người thuê gửi khoản trả và ảnh tùy chọn; Chủ trọ xem cùng khoản/ảnh và duyệt hoặc từ chối. Gửi chưa làm giảm nợ. Duyệt giảm đúng số tiền xác nhận; hỗ trợ trả một phần. Từ chối cho phép gửi lại. Chặn gửi trùng khi còn chờ, vượt dư nợ và duyệt hai lần. |
| Tài khoản nhận tiền | Tài khoản đang hoạt động được chọn mặc định, ngân hàng, tên/số tài khoản | Hướng dẫn hiện tại đọc cùng tài khoản mặc định của Chủ trọ và đúng mã/số tiền còn lại của hóa đơn. Phương thức bị tắt trong hợp đồng không được dùng. Không hiển thị mã QR minh họa như QR thanh toán thật. |
| Thông báo | `id`, `propertyId`, tiêu đề, nội dung, phân loại, ưu tiên, thời gian, danh sách phòng và danh sách người nhận lúc gửi | Gửi toàn nhà/tầng/phòng đưa cùng thông báo đến Người thuê đúng phạm vi. Chuẩn hóa phòng 101 ↔ A.101. Người nhận được chụp tại lúc gửi; người mới vào phòng không tự nhận lịch sử trước đó. Trạng thái đọc lưu riêng từng người và giữ qua chuyển trang/vai trò. Hộp thông báo Chủ trọ lấy từ thanh toán, sự cố, lịch xem và công nợ thực trong phiên. |
| Sự cố | `id`, `leaseId`, người báo/mã người báo, phòng, tiêu đề, loại, nội dung, ngày, ưu tiên, trạng thái chung | Gửi từ Người thuê xuất hiện ở Chủ trọ. Chủ trọ cập nhật xử lý, Người thuê thấy ngay và có thể mở lại hoặc xác nhận khi đã xử lý. Xác nhận chuyển thành Đã đóng ở cả hai bên. |
| Hội thoại | `id`, `propertyId`, `tenantId`, hợp đồng nếu có, cùng danh sách tin và hướng người gửi | Tin gửi ở một vai trò xuất hiện ở vai trò kia; bộ đếm chưa đọc độc lập cho mỗi bên. Hội thoại từ lịch xem dùng chung store và giữ qua điều hướng. Tên Chủ trọ/người đại diện trong hội thoại thuê cập nhật theo dữ liệu nhà/hợp đồng. |
| Lịch xem/Yêu thích | `roomId` ổn định, `propertyId`, `tenantId`, thông tin lịch, thời gian gửi, trạng thái; ID tin thay cho tên yêu thích | Đổi tên không làm mất yêu thích hay cho đặt trùng cùng phòng/giờ. Kiểm tra lại phòng còn trống khi gửi lịch, kể cả form đã mở trước khi Chủ trọ cho thuê phòng. |
| Tổng quan | Phòng theo trạng thái, hóa đơn cần thu, thanh toán chờ, sự cố mới, chỉ số chưa ghi, thành viên chờ, số thu theo kỳ | Các số liệu lấy từ cùng dữ liệu nghiệp vụ, tự cập nhật sau thao tác. Nhãn số thu theo hóa đơn tháng được dùng để không nhầm với báo cáo dòng tiền theo ngày giao dịch. |

## Dữ liệu hiện tại và dữ liệu lịch sử

Thông tin nhà và bảng giá tin đăng được cập nhật trực tiếp. Các điều khoản hợp đồng và dòng hóa đơn đã phát hành là dữ liệu đã thỏa thuận/đã ghi nhận: đổi bảng giá không sửa đơn giá của hợp đồng cũ; sửa giá hợp đồng hoặc chỉ số không sửa hóa đơn đã lập. Thông tin ngân hàng trong bản hợp đồng được giữ, còn hướng dẫn trả hóa đơn lấy tài khoản nhận tiền hiện tại. Thông tin lịch xem là bản ghi tại thời điểm yêu cầu, được hiển thị thống nhất ở hai vai trò.

## Phạm vi hiện tại

Đây là đồng bộ trong cùng phiên chạy ứng dụng, qua dữ liệu chung và `ChangeNotifier`. Chuyển trang hoặc chuyển vai trò giữ các thay đổi. Khởi động lại ứng dụng sẽ khôi phục dữ liệu mẫu. Chưa có đăng nhập, database, API, tải minh chứng lên server hoặc đồng bộ giữa nhiều thiết bị. Các kiểm tra phạm vi trong store chỉ phục vụ bản xem trước; backend tương lai phải kiểm tra quyền và giao dịch tại server.

Các tin nhà khác trong Khám phá vẫn là mẫu độc lập và không nằm trong nhà Mây House mà Chủ trọ đang quản lý. Khoảng cách/vị trí tìm gần vẫn là mô phỏng. Kho chỉ số hiện có dữ liệu mẫu tháng 10/2026; kỳ chưa có dữ liệu hiển thị trống, khi lập hóa đơn có thể nhập lượng tiêu thụ thủ công. Các mục hồ sơ, cài đặt, hỗ trợ và thông báo ứng dụng chưa triển khai nghiệp vụ vẫn là màn hình chờ.

## Kiểm chứng

Đã chạy `flutter analyze` và toàn bộ `flutter test`: không có lỗi/cảnh báo phân tích, 58 kiểm thử đạt. Bộ `test/rental_synchronization_test.dart` bổ sung kiểm tra dữ liệu giữa hai vai trò, giới hạn người thuê, thanh toán một phần/từ chối/gửi lại, hóa đơn lịch sử, thời hạn/trùng phòng, thành viên, sự cố, thông báo, tài khoản nhận và ID tin/lịch xem. Các luồng giao diện hợp đồng, hóa đơn, sự cố và thông báo được kiểm tra tại chiều rộng 390 và 1280.

`flutter build apk --debug` cũng đã thành công. Bản APK kiểm tra nằm tại `build/app/outputs/flutter-apk/app-debug.apk`.

Có thể kiểm tra thủ công bằng menu chuyển vai trò:

1. Chủ trọ sửa hợp đồng Minh Anh/A.302: giá thuê, tiền cọc, đơn giá, thời hạn. Chuyển sang Người thuê → Chỗ ở → Mở hợp đồng: thông tin phải giống bên Chủ trọ. Hóa đơn cũ giữ nguyên các dòng đã lập.
2. Chủ trọ sửa tên/ảnh nhà, giá loại phòng và khu vực. Chuyển sang Người thuê → Khám phá: tin phòng trống của Mây House cập nhật theo dữ liệu vừa lưu; tin yêu thích giữ theo mã phòng.
3. Chủ trọ → Gửi thông báo → chọn A.302 → nhập và gửi. Chuyển sang Người thuê → Thông báo nhà trọ: thấy cùng nội dung; mở để đánh dấu đã đọc rồi rời/quay lại trang vẫn giữ trạng thái đọc. Thông báo riêng phòng khác không xuất hiện cho Minh Anh.
4. Người thuê → Báo sự cố → tạo yêu cầu. Chủ trọ → Yêu cầu sửa chữa → mở yêu cầu → chọn Đã xử lý. Người thuê thấy trạng thái mới; chọn Xác nhận thì cả hai bên thấy Đã đóng.
5. Hóa đơn mẫu A.302 đã có một khoản chờ duyệt. Chủ trọ → Duyệt thanh toán → từ chối khoản đó với lý do, hoặc tạo hóa đơn kỳ khác cho hợp đồng. Người thuê → chi tiết hóa đơn → Thanh toán → nhập tham chiếu và chọn ảnh nếu có → gửi. Chủ trọ thấy cùng khoản, duyệt một phần/đủ tiền; Người thuê thấy số đã xác nhận, số còn lại và lịch sử quyết định.
6. Người thuê → Tin nhắn → Nguyễn Văn An → gửi tin. Chủ trọ → Tin nhắn → Minh Anh/A.302 nhận và trả lời. Chuyển lại Người thuê để xem câu trả lời.
