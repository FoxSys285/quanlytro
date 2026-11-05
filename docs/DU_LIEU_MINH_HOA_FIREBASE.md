# Bổ sung dữ liệu minh họa vào Firebase

Theo yêu cầu ngày 05/11/2026, bổ sung mẫu cho các trạng thái nghiệp vụ bằng
`tool/supplement_firebase_samples.py`. Công cụ dùng dữ liệu Firebase đang đọc
được sau đăng nhập; không lấy SQLite, snapshot cũ hay dữ liệu khởi tạo của app.

## Nội dung

Mỗi nhà có hợp đồng đang hiệu lực được bổ sung:

- Hợp đồng nháp và đã kết thúc, thông tin cá nhân mẫu tách riêng; không đổi phòng
  đang thuê hoặc tạo tài khoản đăng nhập.
- Hóa đơn đã trả, trả một phần, quá hạn, chờ duyệt và báo trả bị từ chối; có khoản
  thu tương ứng. Số đã trả khớp khoản được duyệt; khoản chờ/bị từ chối không tính
  vào tiền đã nhận. Các hóa đơn tình huống cùng kỳ cố ý tách riêng để xem trạng thái.
- Thành viên đang chờ, được duyệt, bị từ chối; sự cố mới, đang xử lý, đã xử lý, đã đóng.
- Chỉ số điện nước kỳ trước nếu chưa có chỉ số phòng/kỳ đó.
- Lịch xem chờ, xác nhận, hủy; hội thoại và tin nhắn nằm ở document riêng.
- Thông báo chủ trọ/người thuê nếu kênh tương ứng chưa có dữ liệu. Giữ trạng thái
  đã đọc hiện có, không ghi đè thông báo trước đó.

Thêm một yêu cầu hỗ trợ mở do chính admin đăng nhập tạo. Không giả danh yêu cầu
của tài khoản khác. Mã cố định `sample-v1-*`, nội dung mẫu có `[MẪU]`; các khoản
thu này là **minh họa**, không phải xác nhận đã giao nhận tiền thật. Chúng tham
gia thống kê và tính dự kiến hoa hồng giống dữ liệu nghiệp vụ khác.

Nhà chưa có hợp đồng hiệu lực được bỏ qua, không tự gán người thuê hoặc chủ sở hữu.
Ưu tiên liên kết hồ sơ người thuê có tài khoản Firebase hiện có để kiểm tra màn
người thuê. Thành viên/hợp đồng mẫu mới không được cấp tài khoản hoặc quyền.

Hoa hồng và xác minh ở `management/system` do Anti phụ trách theo `.ai/agents.md`;
công cụ này không sửa các trường đó. Không ghi `app_documents`, `users`, Rules,
ảnh, giá phòng, tài khoản ngân hàng hoặc dữ liệu đang có.

## Chạy

Mở terminal tại thư mục dự án. Lệnh đầu xem trước; lệnh sau mới ghi:

```powershell
python tool/supplement_firebase_samples.py
python tool/supplement_firebase_samples.py --apply
```

Nhập email admin rồi mật khẩu tại lời nhắc ẩn. Không gửi mật khẩu vào chat, tham
số hoặc file. Dùng xác thực và kiểm tra vai trò admin của publisher hiện có;
không lưu token/mật khẩu. Không cần chỉnh Rules.

Đọc dữ liệu Firebase đang có rồi ghi một batch nguyên tử. Chỉ tạo document mới bằng
`exists: false`, không ghi đè bản vừa được tạo ở thiết bị khác. Mỗi đợt tối đa
450 document; vượt mức thì dừng, chưa ghi gì. Nếu thiếu quyền hoặc có xung đột,
dừng và chạy lại sau khi xử lý nguyên nhân. Không chia nhỏ rồi ghi một phần.

Lưu `before.json`, `planned.json`, `after.json` trong thư mục con
`.local-backups/firestore/samples-*` đã được Git bỏ qua. Chỉ thông báo
`PUBLISHED_AND_VERIFIED` sau khi đọc lại và đối chiếu toàn bộ document vừa ghi.
Nếu bước đọc lại lỗi sau commit, kiểm tra bản sao trước khi chạy lại; ID cố định
ngăn tạo trùng nhưng không có nghĩa lần ghi trước chưa xảy ra.

## Kiểm tra và giới hạn xác minh

```powershell
python -m unittest discover -s test -p test_firebase_samples.py
python -m unittest discover -s test -p test_rental_import.py
flutter test --no-pub tool/check_firebase_samples_test.dart
flutter analyze --no-pub tool/check_firebase_samples_test.dart
```

Các kiểm tra xác nhận quan hệ mã, quyền đọc theo tenant, không thay bản gốc,
không nhân đôi khi chạy lại, preview không commit, có backup/đọc lại sau commit,
và model thật của app nạp được dữ liệu. Test không ghi Firebase thật.

## Đã nhập và đối chiếu Firebase thật — 05/11/2026

Anti đã thực hiện commit và đọc lại 250 document. Sau đó Codex đăng nhập admin,
đọc lại Firebase độc lập và so sánh với `planned.json`: **250/250 khớp**, không
thay đổi document cũ. Chạy lại công cụ cho kết quả `newDocuments: 0`.

| Loại | Số bản ghi mới |
| --- | ---: |
| Hợp đồng | 20 |
| Hóa đơn | 50 |
| Thanh toán | 40 |
| Thành viên | 30 |
| Sự cố | 40 |
| Lịch xem | 30 |
| Hội thoại | 10 |
| Tin nhắn | 20 |
| Chỉ số điện nước | 9 |
| Hỗ trợ | 1 |

Thông báo đã có trên Firebase nên được giữ nguyên. Nhà Mây đã có chỉ số cùng
phòng/kỳ nên không tạo thêm. Các khoản thu mới là minh họa và tham gia thống kê.

Đã đọc trực tiếp `management/system`: 10 tỷ lệ hoa hồng, 16 kỳ đối soát và 6 nhà
đánh dấu xác minh. Đây là dữ liệu phục vụ đồ án, không xác nhận giao nhận tiền
thật hay xác minh pháp lý.

Bản sao nhập nằm tại `.local-backups/firestore/samples-20261105T144844161058/`.
Bản đọc độc lập và kết quả đối chiếu nằm tại
`.local-backups/firestore/samples-20261105T144944308701/verification.json`.
Không lưu mật khẩu/token vào các file này.

Trong môi trường này, `beginTransaction` trả 403 dù đăng nhập admin và đọc
nghiệp vụ thành công. Công cụ đã chuyển sang batch commit `exists: false`;
không sửa Rules hoặc tăng quyền. Các kiểm tra đã cập nhật để chặn gọi lại API
transaction không hoạt động ở môi trường này.
