import 'package:flutter/material.dart';

import '../../../layouts/landlord_navigation.dart';
import '../landlord_theme.dart';
import '../landlord_glass.dart';

import '../../shared/conversations/conversation_store.dart';
import '../landlord_demo_store.dart';
import 'landlord_tenant_info_page.dart';
import 'models/landlord_cuoctrochuyen.dart';

// Tên Class chính bằng tiếng Việt
class LandlordTinNhanPage extends StatefulWidget {
  const LandlordTinNhanPage({super.key, required this.conversation});

  final LandlordConversation conversation;

  @override
  State<LandlordTinNhanPage> createState() => _LandlordTinNhanPageState();
}

class _LandlordTinNhanPageState extends State<LandlordTinNhanPage> {
  // Controller để điều khiển ô nhập tin nhắn
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Đăng ký lắng nghe tin nhắn mới từ kho lưu trữ chung
    ConversationStore.instance.addListener(_capNhat);
    _scrollToLatest();
  }

  void _capNhat() {
    if (mounted) {
      setState(() {});
      _scrollToLatest();
    }
  }

  @override
  void dispose() {
    // Hủy đăng ký lắng nghe khi thoát màn hình để giải phóng RAM
    ConversationStore.instance.removeListener(_capNhat);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToLatest() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    if (widget.conversation.unread > 0) {
      ConversationStore.instance.markRead(widget.conversation, landlord: true);
    }
  });

  // Hàm gửi tin nhắn từ phía chủ trọ
  void _guiTinNhan() {
    final noiDung = _controller.text.trim();
    if (noiDung.isEmpty) {
      return;
    }

    final gioHienTai = TimeOfDay.now().format(context);
    ConversationStore.instance.send(
      widget.conversation,
      text: noiDung,
      time: gioHienTai,
      fromLandlord: true,
    );
    setState(() {
      _controller.clear();
    });
  }

  void _showTenantInfo() {
    LandlordNavigation.push<void>(
      context,
      page: LandlordTenantInfoPage(conversation: widget.conversation),
      destinationId: 'conversations',
    );
  }

  @override
  Widget build(BuildContext context) {
    final danhSachTinNhan = widget.conversation.messages;
    final initials = widget.conversation.tenantName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: LandlordPalette.of(context).canvas,
      appBar: AppBar(
        backgroundColor: LandlordPalette.of(context).surface
            .withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: propertyBlue,
              child: Text(
                initials.isEmpty ? 'N' : initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.conversation.tenantName.trim().isEmpty
                        ? 'Người thuê'
                        : widget.conversation.tenantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.conversation.propertyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: LandlordPalette.of(context).muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Thông tin người thuê trọ',
            onPressed: _showTenantInfo,
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: PropertyPortfolioBackdrop(
        child: Column(
          children: [
            // Danh sách các tin nhắn cuộn lên xuống
            Expanded(
              child: danhSachTinNhan.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bắt đầu cuộc trò chuyện với người thuê.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(14),
                      itemCount: danhSachTinNhan.length,
                      itemBuilder: (context, index) {
                        final tinNhan = danhSachTinNhan[index];
                        return _BongBongTinNhan(message: tinNhan);
                      },
                    ),
            ),
            // Khung nhập tin nhắn và nút gửi ở đáy màn hình
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                color: LandlordPalette.of(context).surface,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          filled: true,
                          fillColor: LandlordPalette.of(context).canvas,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      tooltip: 'Gửi tin nhắn',
                      onPressed: _guiTinNhan,
                      style: IconButton.styleFrom(
                        backgroundColor: propertyBlue,
                      ),
                      icon: Icon(Icons.send_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget bong bóng hiển thị từng tin nhắn
class _BongBongTinNhan extends StatelessWidget {
  const _BongBongTinNhan({required this.message});

  final LandlordMessage message;

  @override
  Widget build(BuildContext context) {
    final laTinNhanChuTro = message.fromLandlord;

    // Định nghĩa các biến kiểu dáng giao diện
    Alignment canLe;
    Color mauNen;
    Border? vien;
    Color mauChu;
    Color mauThoiGian;

    // Phân loại: Tin của chủ trọ nằm bên phải nền xanh, tin của người thuê nằm bên trái nền trắng
    if (laTinNhanChuTro) {
      canLe = Alignment.centerRight;
      mauNen = propertyBlue;
      vien = null;
      mauChu = Colors.white;
      mauThoiGian = Colors.white70;
    } else {
      canLe = Alignment.centerLeft;
      mauNen = LandlordPalette.of(context).surface;
      vien = Border.all(color: LandlordPalette.of(context).line);
      mauChu = LandlordPalette.of(context).ink;
      mauThoiGian = LandlordPalette.of(context).muted;
    }

    return Align(
      alignment: canLe,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: mauNen,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(laTinNhanChuTro ? 18 : 5),
            bottomRight: Radius.circular(laTinNhanChuTro ? 5 : 18),
          ),
          gradient: laTinNhanChuTro
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF279FFF), propertyBlue],
                )
              : null,
          border: vien,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SelectableText(
              message.text,
              style: TextStyle(color: mauChu, fontSize: 13),
            ),
            const SizedBox(height: 3),
            Text(
              message.time,
              style: TextStyle(color: mauThoiGian, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
