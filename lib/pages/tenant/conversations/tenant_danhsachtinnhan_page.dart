import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import '../../shared/conversations/conversation_store.dart';
import 'models/tenant_conversation.dart';
import 'tenant_tinnhan_page.dart';

// Tên Class chính bằng tiếng Việt
class TenantDanhSachTinNhanPage extends StatefulWidget {
  const TenantDanhSachTinNhanPage({super.key});

  @override
  State<TenantDanhSachTinNhanPage> createState() =>
      _TenantDanhSachTinNhanPageState();
}

class _TenantDanhSachTinNhanPageState extends State<TenantDanhSachTinNhanPage> {
  // 1. DỮ KIỆN (Biến trạng thái đưa lên đầu)
  String _tuKhoaTimKiem = '';

  // 2. VÒNG ĐỜI VÀ LẮNG NGHE DỮ LIỆU
  @override
  void initState() {
    super.initState();
    ConversationStore.instance.addListener(_capNhat);
  }

  void _capNhat() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    ConversationStore.instance.removeListener(_capNhat);
    super.dispose();
  }

  // 3. CÁC HÀM XỬ LÝ (Viết trước hàm build)
  // Hàm chuyển sang màn hình chat chi tiết với chủ trọ
  Future<void> _moManHinhTroChuyen(TenantConversation cuocTroChuyen) async {
    setState(() {
      cuocTroChuyen.unread = 0;
    });
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            TenantTinNhanPage(conversation: cuocTroChuyen),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  // 4. HÀM BUILD ĐẶT Ở DƯỚI CÙNG, CHẠY MỘT MẠCH LIỀN
  @override
  Widget build(BuildContext context) {
    // Lọc danh sách cuộc trò chuyện theo từ khóa tìm kiếm
    final List<TenantConversation> danhSachHoiThoai = [];
    for (int i = 0; i < TenantConversation.demoConversations.length; i++) {
      final cuocTroChuyen = TenantConversation.demoConversations[i];
      final chuoiTimKiem =
          '${cuocTroChuyen.landlordName} ${cuocTroChuyen.contextLabel}'
              .toLowerCase();
      if (chuoiTimKiem.contains(_tuKhoaTimKiem)) {
        danhSachHoiThoai.add(cuocTroChuyen);
      }
    }

    // Danh sách widget hiển thị trên toàn màn hình
    final List<Widget> danhSachWidget = [
      const TenantPageTitle(
        title: 'Tin nhắn',
        subtitle: 'Trao đổi với chủ trọ về chỗ ở và phòng bạn quan tâm.',
      ),
      TextField(
        onChanged: (giaTri) {
          setState(() {
            _tuKhoaTimKiem = giaTri.trim().toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm chủ trọ, nhà trọ hoặc phòng...',
          prefixIcon: const Icon(Icons.search_rounded, color: tenantMuted),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: tenantLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: tenantLine),
          ),
        ),
      ),
      const SizedBox(height: 20),
      TenantSectionHeading('Cuộc trò chuyện (${danhSachHoiThoai.length})'),
    ];

    // Kiểm tra nếu danh sách rỗng thì hiển thị thông báo trống
    if (danhSachHoiThoai.isEmpty) {
      danhSachWidget.add(
        const TenantEmptyState(
          icon: Icons.forum_outlined,
          title: 'Không tìm thấy cuộc trò chuyện',
          subtitle: 'Thử tìm bằng tên chủ trọ, nhà trọ hoặc số phòng khác.',
        ),
      );
    } else {
      // Duyệt qua từng cuộc trò chuyện để tạo thẻ ListTile hiển thị
      for (int i = 0; i < danhSachHoiThoai.length; i++) {
        final cuocTroChuyen = danhSachHoiThoai[i];

        // Nếu có tin nhắn chưa đọc thì in đậm tiêu đề
        FontWeight doDamTieuDe;
        if (cuocTroChuyen.unread > 0) {
          doDamTieuDe = FontWeight.w800;
        } else {
          doDamTieuDe = FontWeight.w600;
        }

        // Lấy nội dung tin nhắn cuối cùng để hiển thị bản xem trước
        String noiDungTinNhanCuoi;
        if (cuocTroChuyen.messages.isEmpty) {
          noiDungTinNhanCuoi = 'Chưa có tin nhắn';
        } else {
          final tinNhanCuoi = cuocTroChuyen.messages.last;
          if (tinNhanCuoi.fromTenant) {
            noiDungTinNhanCuoi = 'Bạn: ${tinNhanCuoi.text}';
          } else {
            noiDungTinNhanCuoi = tinNhanCuoi.text;
          }
        }

        // Lấy thời gian của tin nhắn cuối
        String thoiGianTinNhan = '';
        if (cuocTroChuyen.messages.isNotEmpty) {
          thoiGianTinNhan = cuocTroChuyen.messages.last.time;
        }

        // Tạo huy hiệu số tin nhắn chưa đọc nếu có
        Widget? huyHieuChuaDoc;
        if (cuocTroChuyen.unread > 0) {
          huyHieuChuaDoc = Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              label: '${cuocTroChuyen.unread} tin nhắn chưa đọc',
              child: CircleAvatar(
                radius: 10,
                backgroundColor: tenantGreen,
                child: Text(
                  '${cuocTroChuyen.unread}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }

        // Gom các widget bên phải của thẻ item (thời gian + huy hiệu chưa đọc)
        final List<Widget> danhSachWidgetBenPhai = [
          Text(
            thoiGianTinNhan,
            style: const TextStyle(
              color: tenantMuted,
              fontSize: 10,
            ),
          ),
        ];
        if (huyHieuChuaDoc != null) {
          danhSachWidgetBenPhai.add(huyHieuChuaDoc);
        }

        danhSachWidget.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TenantSurface(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  onTap: () {
                    _moManHinhTroChuyen(cuocTroChuyen);
                  },
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8F2EE),
                    child: Text(
                      cuocTroChuyen.initials,
                      style: const TextStyle(
                        color: tenantGreenDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    cuocTroChuyen.landlordName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tenantInk,
                      fontSize: 14,
                      fontWeight: doDamTieuDe,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cuocTroChuyen.contextLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: tenantMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        noiDungTinNhanCuoi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: tenantInk, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: danhSachWidgetBenPhai,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return TenantPageFrame(
      children: danhSachWidget,
    );
  }
}
