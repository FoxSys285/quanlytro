import 'package:flutter/material.dart';

import 'legal_document_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) => const LegalDocumentPage(
    title: 'Chính sách bảo mật',
    subtitle: 'Giải thích dữ liệu TroPremium xử lý, mục đích sử dụng, bên nhận dữ liệu và các quyền của bạn.',
    icon: Icons.shield_outlined,
    notice: 'Chúng tôi chỉ yêu cầu quyền vị trí khi bạn dùng tính năng cần vị trí. Bạn có thể từ chối quyền này; một số tính năng bản đồ hoặc tìm kiếm gần bạn khi đó có thể không hoạt động đầy đủ.',
    sections: [
      LegalDocumentSection(
        title: 'Dữ liệu có thể được xử lý',
        body: 'Loại dữ liệu phụ thuộc vào tính năng bạn sử dụng và thông tin bạn hoặc người cùng giao dịch cung cấp. Có thể bao gồm:',
        points: [
          'Hồ sơ tài khoản: tên hiển thị, email, số điện thoại, vai trò và mã định danh tài khoản Firebase; Google hoặc Firebase xử lý thông tin cần thiết để đăng nhập và xác minh OTP.',
          'Dữ liệu quản lý thuê: thông tin nhà và phòng, địa chỉ/tọa độ, hồ sơ chủ trọ và người thuê, thành viên hợp đồng, yêu cầu xem phòng, nội dung trao đổi, hóa đơn, khoản tiền và trạng thái thanh toán được ghi nhận.',
          'Tệp bạn tải lên: ảnh, video, tài liệu và giấy tờ xác minh nếu bạn chủ động gửi qua tính năng tương ứng.',
          'Gói dịch vụ: lựa chọn gói, đơn đăng ký, mã giao dịch giả lập và trạng thái kích hoạt. Phiên bản đồ án không thu tiền hoặc gửi dữ liệu thanh toán đến ngân hàng/SePay.',
          'Vị trí thiết bị: chỉ khi bạn cấp quyền và sử dụng tính năng định vị hoặc chọn khu vực trên bản đồ. Tọa độ nhà trọ do người dùng chọn hoặc nhập được lưu cùng tin nhà trọ.',
        ],
      ),
      LegalDocumentSection(
        title: 'Mục đích sử dụng',
        body: 'Dữ liệu được dùng để tạo và bảo vệ tài khoản; kết nối đúng vai trò; vận hành tin nhà trọ, hồ sơ thuê, trao đổi, hóa đơn và hỗ trợ; ghi nhận đơn gói giả lập; xử lý yêu cầu của bạn; bảo vệ hệ thống và thực hiện nghĩa vụ theo pháp luật. TroPremium không dùng dữ liệu cho mục đích khác ngoài phạm vi được thông báo hoặc được pháp luật cho phép.',
      ),
      LegalDocumentSection(
        title: 'Nơi lưu trữ và nhà cung cấp xử lý',
        body: 'TroPremium sử dụng các nhà cung cấp để vận hành tính năng. Hồ sơ, tin nhà trọ, phòng, hợp đồng, hóa đơn và trao đổi được lưu trong Cloud Firestore. Firebase Authentication hỗ trợ đăng nhập. Supabase lưu đơn đăng ký gói và trạng thái thanh toán giả lập. Phiên bản đồ án không kết nối SePay hoặc ngân hàng để thu và đối soát thanh toán gói. Cloudinary lưu ảnh, video và tệp tải lên. Google Maps hỗ trợ bản đồ.',
        points: [
          'Nhân sự quản trị được phân quyền có thể truy cập thông tin cần thiết để hỗ trợ, kiểm duyệt hoặc xử lý sự cố.',
          'Chủ trọ và người thuê chỉ nhìn thấy dữ liệu cần thiết cho tính năng và quan hệ thuê của họ theo quyền truy cập của tài khoản.',
          'Nhà cung cấp xử lý dữ liệu theo chức năng hạ tầng của họ. Vị trí lưu trữ có thể ở Việt Nam hoặc quốc gia khác tùy cấu hình vùng của từng dịch vụ.',
        ],
      ),
      LegalDocumentSection(
        title: 'Chia sẻ dữ liệu',
        body: 'Dữ liệu chỉ được cung cấp cho người dùng liên quan, nhân sự được phân quyền hoặc nhà cung cấp nêu trên trong phạm vi cần thiết để thực hiện tính năng. TroPremium có thể cung cấp dữ liệu cho cơ quan có thẩm quyền khi có yêu cầu hợp lệ hoặc để bảo vệ quyền và an toàn của người dùng theo quy định pháp luật. Người đăng tin tự chịu trách nhiệm khi chia sẻ nội dung công khai trong tin nhà trọ.',
      ),
      LegalDocumentSection(
        title: 'Thời gian lưu giữ',
        body: 'Dữ liệu được lưu trong thời gian cần để cung cấp dịch vụ, duy trì hồ sơ giao dịch, xử lý hỗ trợ, bảo vệ quyền lợi hợp pháp và đáp ứng nghĩa vụ lưu trữ theo pháp luật. Khi không còn mục đích xử lý, dữ liệu sẽ được xóa, hủy hoặc khử nhận dạng theo quy trình và khả năng kỹ thuật của hệ thống, trừ phần cần tiếp tục lưu theo quy định hoặc để giải quyết tranh chấp.',
      ),
      LegalDocumentSection(
        title: 'Bảo vệ dữ liệu',
        body: 'Ứng dụng áp dụng xác thực tài khoản, phân quyền truy cập theo vai trò và các biện pháp kỹ thuật phù hợp tại các dịch vụ lưu trữ. Một số tài liệu riêng tư được cấp liên kết tải có thời hạn sau khi kiểm tra quyền. Bạn cũng cần giữ kín mật khẩu, OTP và đăng xuất khỏi thiết bị dùng chung. Không có biện pháp truyền hoặc lưu trữ nào bảo đảm an toàn tuyệt đối.',
      ),
      LegalDocumentSection(
        title: 'Quyền và lựa chọn của bạn',
        body: 'Bạn có thể yêu cầu biết, xem, cập nhật hoặc sửa dữ liệu của mình; yêu cầu rút lại sự đồng ý, hạn chế hoặc phản đối việc xử lý, xóa dữ liệu hay thực hiện quyền khác theo pháp luật hiện hành. Một số yêu cầu có thể ảnh hưởng đến khả năng đăng nhập, xác minh, lưu hồ sơ thuê hoặc dùng tính năng liên quan. Một số dữ liệu vẫn có thể cần được lưu theo nghĩa vụ pháp luật hoặc để giải quyết giao dịch, tranh chấp.',
        points: [
          'Gửi yêu cầu qua mục Trợ giúp trong ứng dụng và nêu rõ tài khoản, dữ liệu hoặc quyền bạn muốn thực hiện.',
          'Chỉ gửi giấy tờ xác minh danh tính khi cần thiết để bảo vệ tài khoản và xử lý yêu cầu; không gửi mật khẩu hoặc mã OTP.',
        ],
      ),
      LegalDocumentSection(
        title: 'Cập nhật chính sách',
        body: 'Chính sách này có thể thay đổi khi tính năng, nhà cung cấp hoặc quy định pháp luật thay đổi. Phiên bản mới và ngày cập nhật sẽ được hiển thị tại trang này. Nếu thay đổi làm ảnh hưởng đáng kể đến cách xử lý dữ liệu, TroPremium sẽ thông báo trong ứng dụng khi phù hợp.',
      ),
    ],
  );
}
