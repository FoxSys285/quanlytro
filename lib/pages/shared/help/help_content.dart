import '../../../layouts/role_layout.dart';

class HelpArticle {
  const HelpArticle(this.category, this.question, this.answer);

  final String category;
  final String question;
  final String answer;
}

List<HelpArticle> helpArticlesFor(AppRole role) => [
  if (role == AppRole.tenant) ...const [
    HelpArticle(
      'Tìm phòng',
      'Làm thế nào để tìm phòng và đặt lịch xem?',
      '1. Vào Khám phá, tìm và lọc phòng theo nhu cầu.\n'
          '2. Chọn một phòng để xem giá thuê, diện tích và dịch vụ.\n'
          '3. Chọn đặt lịch xem, điền thông tin và gửi yêu cầu.\n'
          '4. Vào Lịch xem phòng để theo dõi phản hồi của chủ trọ.',
    ),
    HelpArticle(
      'Chỗ ở',
      'Xem thông tin chỗ ở và thành viên phòng ở đâu?',
      'Vào Chỗ ở để xem hợp đồng và thông tin phòng đang thuê. '
          'Mở Thành viên phòng trong menu để xem danh sách người ở cùng. '
          'Nếu thông tin chưa đúng hoặc chưa có phòng thuê, hãy trao đổi với chủ trọ để kiểm tra hợp đồng.',
    ),
    HelpArticle(
      'Thanh toán',
      'Tôi cần làm gì để thanh toán hóa đơn?',
      '1. Vào Hóa đơn và chọn hóa đơn cần thanh toán.\n'
          '2. Kiểm tra các khoản thu, tổng tiền và hạn thanh toán.\n'
          '3. Mở hướng dẫn thanh toán, chuyển khoản theo thông tin được cung cấp.\n'
          '4. Gửi thông tin hoặc minh chứng thanh toán theo hướng dẫn trên màn hình.\n'
          '5. Theo dõi trạng thái sau khi chủ trọ đối soát.',
    ),
    HelpArticle(
      'Thanh toán',
      'Đã chuyển tiền nhưng hóa đơn chưa được xác nhận?',
      'Kiểm tra trạng thái hóa đơn và thông tin thanh toán đã gửi. '
          'Chủ trọ cần đối soát trước khi xác nhận. Nếu cần kiểm tra thêm, '
          'nhắn cho chủ trọ mã hóa đơn, số tiền và thời điểm chuyển khoản. '
          'Nếu thanh toán bị từ chối, xem lý do và kiểm tra lại minh chứng.',
    ),
    HelpArticle(
      'Trao đổi',
      'Báo sự cố trong phòng như thế nào?',
      '1. Mở menu và chọn Báo sự cố.\n'
          '2. Tạo yêu cầu, chọn loại sự cố và nhập tiêu đề, mô tả cụ thể.\n'
          '3. Chọn Gửi yêu cầu.\n'
          '4. Theo dõi trạng thái xử lý trong danh sách sự cố. '
          'Bạn cũng có thể trao đổi thêm với chủ trọ qua Tin nhắn.',
    ),
  ] else ...const [
    HelpArticle(
      'Quản lý nhà',
      'Bắt đầu thiết lập nhà trọ như thế nào?',
      '1. Vào Nhà trọ để kiểm tra thông tin nhà đang quản lý.\n'
          '2. Thiết lập Loại phòng và thêm Phòng trọ.\n'
          '3. Kiểm tra Dịch vụ và bảng giá.\n'
          '4. Thêm thông tin thuê trong Hợp đồng và kiểm tra Người thuê.\n'
          '5. Kiểm tra Tài khoản nhận tiền trước khi thu tiền phòng.',
    ),
    HelpArticle(
      'Cho thuê',
      'Theo dõi yêu cầu xem phòng ở đâu?',
      'Mở Lịch xem phòng để xem các yêu cầu của người tìm thuê. '
          'Kiểm tra phòng, thời gian hẹn và thông tin liên hệ trước khi phản hồi. '
          'Bạn có thể trao đổi thêm với người hẹn xem qua Tin nhắn.',
    ),
    HelpArticle(
      'Thu chi',
      'Lập hóa đơn tiền phòng như thế nào?',
      '1. Kiểm tra Chỉ số điện nước của kỳ cần thu.\n'
          '2. Vào Lập hóa đơn và chọn hợp đồng, kỳ thu.\n'
          '3. Kiểm tra tiền phòng, dịch vụ, các khoản bổ sung và hạn thanh toán.\n'
          '4. Kiểm tra tổng tiền trước khi lưu hóa đơn.',
    ),
    HelpArticle(
      'Thu chi',
      'Xác nhận hoặc từ chối thanh toán ở đâu?',
      'Vào Duyệt thanh toán, chọn khoản chờ đối soát và nhấn Kiểm tra và xử lý. '
          'Đối chiếu số tiền, thông tin chuyển khoản và minh chứng với giao dịch thực tế. '
          'Chọn Xác nhận khi thông tin khớp; nếu Từ chối, nhập lý do để người thuê kiểm tra lại.',
    ),
    HelpArticle(
      'Vận hành',
      'Làm thế nào để gửi thông báo cho người thuê?',
      '1. Mở Gửi thông báo từ menu hoặc nhấn chuông trên thanh trên cùng.\n'
          '2. Chọn tạo thông báo.\n'
          '3. Chọn đối tượng nhận: cả nhà, theo tầng hoặc các phòng cụ thể.\n'
          '4. Điền tiêu đề, nội dung và kiểm tra thông tin trước khi Gửi thông báo.',
    ),
    HelpArticle(
      'Vận hành',
      'Quản lý yêu cầu sửa chữa như thế nào?',
      'Vào Yêu cầu sửa chữa để xem sự cố do người thuê gửi. '
          'Kiểm tra phòng, nội dung sự cố và cập nhật trạng thái theo tiến độ xử lý. '
          'Dùng Tin nhắn khi cần làm rõ tình trạng hoặc thống nhất thời gian sửa chữa.',
    ),
  ],
  const HelpArticle(
    'Tài khoản',
    'Chỉnh sửa hồ sơ cá nhân ở đâu?',
    'Mở Tài khoản → Cài đặt → Hồ sơ cá nhân. Chọn Chỉnh sửa hồ sơ, '
        'cập nhật thông tin và nhấn Lưu thay đổi. Chọn Hủy nếu không muốn lưu.',
  ),
  const HelpArticle(
    'Tài khoản',
    'Chuông thông báo và thông báo ứng dụng khác nhau thế nào?',
    'Chuông trên thanh trên cùng mở thông báo nhà trọ. '
        'Tùy chọn nhận thông báo ứng dụng nằm trong Cài đặt → Thông báo ứng dụng. '
        'Tắt tùy chọn này không xóa các thông báo nhà trọ đã nhận.',
  ),
];

/// Allow Vietnamese queries with or without diacritics.
String normalizeHelpQuery(String value) {
  var result = value.toLowerCase().trim();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    for (final rune in entry.value.runes) {
      result = result.replaceAll(String.fromCharCode(rune), entry.key);
    }
  }
  return result.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
}
