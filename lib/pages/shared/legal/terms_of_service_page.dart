import 'package:flutter/material.dart';

import 'legal_document_page.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) => const LegalDocumentPage(
    title: 'Điều khoản sử dụng',
    subtitle: 'Quy định khi tạo tài khoản và sử dụng các công cụ quản lý, tìm kiếm nhà trọ của TroPremium.',
    icon: Icons.description_outlined,
    notice: 'Vui lòng đọc kỹ trước khi tạo tài khoản. Khi đánh dấu đồng ý và đăng ký, bạn xác nhận đã đọc và chấp thuận các điều khoản dưới đây.',
    sections: [
      LegalDocumentSection(
        title: 'Phạm vi dịch vụ',
        body: 'TroPremium cung cấp ứng dụng hỗ trợ chủ trọ quản lý nhà, phòng và hồ sơ thuê; hỗ trợ người thuê tìm kiếm thông tin, trao đổi, theo dõi hóa đơn và các thông tin liên quan đến việc thuê. Một số tính năng chỉ khả dụng khi tài khoản được xác thực hoặc được cấp đúng vai trò.',
      ),
      LegalDocumentSection(
        title: 'Tài khoản và thông tin đăng ký',
        body: 'Bạn cần cung cấp thông tin chính xác, cập nhật và chỉ dùng email hoặc số điện thoại mà bạn có quyền sử dụng. Bạn chịu trách nhiệm giữ bí mật thông tin đăng nhập và các hoạt động thực hiện từ tài khoản của mình.',
        points: [
          'Không chia sẻ mã OTP, mật khẩu hoặc quyền truy cập tài khoản cho người khác.',
          'Thông báo qua mục Trợ giúp nếu nghi ngờ tài khoản bị truy cập trái phép hoặc thông tin hồ sơ bị dùng sai.',
          'Chọn đúng vai trò chủ trọ hoặc người thuê và chỉ truy cập hồ sơ, tài liệu mà bạn có quyền xem.',
        ],
      ),
      LegalDocumentSection(
        title: 'Nội dung và thông tin nhà trọ',
        body: 'Người đăng nội dung chịu trách nhiệm về tính chính xác, quyền sử dụng và căn cứ đăng tải thông tin, hình ảnh, video, giấy tờ hoặc dữ liệu của người khác. Không đăng nội dung giả mạo, xâm phạm quyền riêng tư, quyền sở hữu trí tuệ hoặc trái pháp luật.',
        points: [
          'Chủ trọ cần có quyền quản lý hoặc được ủy quyền đăng tin về nhà, phòng và thông tin liên hệ.',
          'Chỉ cung cấp thông tin cá nhân của người thuê hoặc thành viên khác khi có căn cứ phù hợp và đã thông báo cho họ.',
          'Người thuê nên tự kiểm tra nhà, phòng, chủ thể giao dịch và các điều kiện thuê trước khi giao tiền hoặc ký kết.',
        ],
      ),
      LegalDocumentSection(
        title: 'Thỏa thuận thuê và giao dịch giữa người dùng',
        body: 'Thông tin tin đăng, hồ sơ thuê, hợp đồng và hóa đơn trong ứng dụng là công cụ hỗ trợ người dùng quản lý và trao đổi. Các bên tự xác nhận nội dung thỏa thuận, điều kiện thuê, tiền cọc, tiền thuê và việc bàn giao. TroPremium không thay thế hợp đồng giữa chủ trọ và người thuê, không bảo đảm mọi tin đăng hoặc hành vi của người dùng.',
      ),
      LegalDocumentSection(
        title: 'Gói dịch vụ và thanh toán',
        body: 'Phiên bản đồ án hiện tại dùng thanh toán giả lập để trình bày luồng đăng ký gói. Khi xác nhận, hệ thống ghi nhận đơn và kích hoạt gói trong 30 ngày; không có chuyển khoản, thu tiền thật hoặc đối soát ngân hàng. Giá và quyền lợi được hiển thị trước khi xác nhận. Hóa đơn thuê giữa người dùng tuân theo thỏa thuận riêng của các bên.',
      ),
      LegalDocumentSection(
        title: 'Hành vi không được phép',
        body: 'Bạn không được sử dụng ứng dụng để lừa đảo, quấy rối, phát tán mã độc, xâm nhập trái phép, thu thập dữ liệu ngoài quyền được cấp, làm gián đoạn dịch vụ hoặc đăng tải nội dung bị cấm. Không dùng ứng dụng để giả danh người khác hoặc né tránh các biện pháp bảo vệ tài khoản.',
      ),
      LegalDocumentSection(
        title: 'Dịch vụ bên thứ ba và khả năng hoạt động',
        body: 'Một số tính năng dựa vào Firebase/Google, Google Maps, Supabase và Cloudinary. Tính năng có thể bị ảnh hưởng khi dịch vụ bên thứ ba bảo trì, gián đoạn hoặc thay đổi điều kiện cung cấp. TroPremium sẽ xử lý sự cố trong phạm vi mình kiểm soát và cập nhật hướng dẫn khi cần.',
      ),
      LegalDocumentSection(
        title: 'Tạm ngưng, chấm dứt và thay đổi điều khoản',
        body: 'TroPremium có thể giới hạn tính năng hoặc tạm ngưng quyền truy cập khi cần bảo vệ tài khoản, dữ liệu, người dùng hoặc để xử lý hành vi vi phạm điều khoản hay pháp luật. Việc xử lý dữ liệu khi tài khoản ngừng hoạt động được thực hiện theo Chính sách bảo mật và quy định áp dụng. Điều khoản có thể được cập nhật; phiên bản và ngày cập nhật sẽ được công bố trong ứng dụng.',
      ),
      LegalDocumentSection(
        title: 'Hỗ trợ và giải quyết yêu cầu',
        body: 'Nếu có câu hỏi, khiếu nại về tài khoản, gói dịch vụ hoặc nội dung trong ứng dụng, hãy gửi yêu cầu qua mục Trợ giúp. Các giao dịch thuê nhà và tranh chấp phát sinh giữa chủ trọ với người thuê cần được các bên trao đổi, đối chiếu hồ sơ và giải quyết theo thỏa thuận cùng quy định pháp luật.',
      ),
    ],
  );
}
