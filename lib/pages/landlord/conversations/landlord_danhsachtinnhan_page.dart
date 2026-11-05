import 'package:flutter/material.dart';

import '../../../layouts/landlord_navigation.dart';
import '../landlord_theme.dart';

import '../landlord_ui.dart';
import '../../shared/conversations/conversation_store.dart';
import '../landlord_demo_store.dart';
import 'landlord_tinnhan_page.dart';
import 'models/landlord_cuoctrochuyen.dart';

// Tên Class chính bằng tiếng Việt
class LandlordDanhSachTinNhanPage extends StatefulWidget {
  const LandlordDanhSachTinNhanPage({super.key});

  @override
  State<LandlordDanhSachTinNhanPage> createState() =>
      _LandlordDanhSachTinNhanPageState();
}

class _LandlordDanhSachTinNhanPageState
    extends State<LandlordDanhSachTinNhanPage> {
  // 1. DỮ KIỆN (Kho lưu trữ đưa lên đầu)
  final _store = ConversationStore.instance;

  // 2. VÒNG ĐỜI VÀ LẮNG NGHE
  @override
  void initState() {
    super.initState();
    _store.addListener(_capNhat);
  }

  void _capNhat() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store.removeListener(_capNhat);
    super.dispose();
  }

  // 3. CÁC HÀM XỬ LÝ (Viết trước hàm build)
  // Hàm mở màn hình chat chi tiết với người thuê
  Future<void> _moKhungChat(LandlordConversation hoiThoai) async {
    _store.markRead(hoiThoai, landlord: true);
    await LandlordNavigation.push<void>(
      context,
      page: LandlordTinNhanPage(conversation: hoiThoai),
      destinationId: 'conversations',
    );
    // Cập nhật lại danh sách sau khi quay về từ khung chat
    if (mounted) {
      setState(() {});
    }
  }

  // 4. HÀM BUILD ĐẶT Ở DƯỚI CÙNG
  @override
  Widget build(BuildContext context) {
    // Lấy danh sách các cuộc trò chuyện của khu trọ hiện tại từ kho
    final danhSachHoiThoai = _store.forProperty(
      LandlordDemoStore.activeInstance.property.id,
    );

    // Danh sách widget hiển thị trên toàn màn hình
    final List<Widget> danhSachWidget = [
      const LandlordPageTitle(
        title: 'Tin nhắn',
        subtitle: 'Trao đổi với người thuê theo từng phòng.',
      ),
    ];

    // Kiểm tra nếu chưa có cuộc trò chuyện nào thì hiển thị trạng thái trống
    if (danhSachHoiThoai.isEmpty) {
      danhSachWidget.add(
        const LandlordEmptyState(message: 'Chưa có cuộc trò chuyện nào.'),
      );
    } else {
      // Duyệt qua từng cuộc trò chuyện bằng vòng lặp for cơ bản
      for (int i = 0; i < danhSachHoiThoai.length; i++) {
        final hoiThoai = danhSachHoiThoai[i];
        final lastMessage = hoiThoai.messages.lastOrNull;

        // Nếu có tin nhắn chưa đọc thì in đậm tiêu đề
        FontWeight doDamTieuDe;
        if (hoiThoai.unread > 0) {
          doDamTieuDe = FontWeight.w800;
        } else {
          doDamTieuDe = FontWeight.w600;
        }

        // Tạo cột hiển thị thời gian và chấm đỏ số tin chưa đọc ở bên phải
        final List<Widget> cotBenPhai = [
          Text(
            lastMessage?.time ?? '',
            style: TextStyle(
              color: LandlordPalette.of(context).muted,
              fontSize: 11,
            ),
          ),
        ];

        if (hoiThoai.unread > 0) {
          cotBenPhai.add(const SizedBox(height: 4));
          cotBenPhai.add(
            CircleAvatar(
              radius: 9,
              backgroundColor: landlordBlue,
              child: Text(
                '${hoiThoai.unread}',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          );
        }

        // Thêm thẻ cuộc trò chuyện vào danh sách hiển thị
        danhSachWidget.add(
          LandlordCard(
            padding: EdgeInsets.zero,
            onTap: () {
              _moKhungChat(hoiThoai);
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: landlordBlue.withValues(alpha: 0.1),
                child: Text(
                  hoiThoai.tenantName[0],
                  style: TextStyle(
                    color: landlordBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                '${hoiThoai.tenantName} · ${hoiThoai.room}',
                style: TextStyle(fontWeight: doDamTieuDe),
              ),
              subtitle: Text(
                lastMessage?.text ?? 'Chưa có tin nhắn',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: cotBenPhai,
              ),
            ),
          ),
        );
      }
    }

    return LandlordPageFrame(children: danhSachWidget);
  }
}
