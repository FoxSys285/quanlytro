import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import 'components/tenant_message_bubble.dart';
import 'models/tenant_conversation.dart';
import 'models/tenant_conversation_message.dart';

class TenantLandlordConversationPage extends StatefulWidget {
  const TenantLandlordConversationPage({super.key, this.conversation});

  final TenantConversation? conversation;

  @override
  State<TenantLandlordConversationPage> createState() =>
      _TenantLandlordConversationPageState();
}

class _TenantLandlordConversationPageState
    extends State<TenantLandlordConversationPage> {
  // Bộ điều khiển ô nhập tin nhắn
  final _oNhapTinNhan = TextEditingController();

  // Thông tin cuộc trò chuyện hiện tại
  late final TenantConversation _cuocTroChuyen;

  // Lấy danh sách tin nhắn từ cuộc trò chuyện
  List<TenantConversationMessage> get _danhSachTinNhan => _cuocTroChuyen.messages;

  @override
  void initState() {
    super.initState();
    // Nếu có truyền cuộc trò chuyện vào thì dùng, không thì lấy mẫu đầu tiên
    if (widget.conversation != null) {
      _cuocTroChuyen = widget.conversation!;
    } else {
      _cuocTroChuyen = TenantConversation.demoConversations.first;
    }
    // Đánh dấu đã đọc hết tin nhắn
    _cuocTroChuyen.unread = 0;
  }

  @override
  void dispose() {
    _oNhapTinNhan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tenantCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFFE8F2EE),
              child: Text(
                _cuocTroChuyen.initials,
                style: const TextStyle(
                  color: tenantGreenDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cuocTroChuyen.landlordName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: tenantInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _cuocTroChuyen.contextLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: tenantMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Thông tin cuộc trò chuyện',
            onPressed: () => showTenantPreviewNotice(context),
            icon: const Icon(Icons.info_outline_rounded, color: tenantGreen),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            color: const Color(0xFFEDF4F1),
            child: Row(
              children: [
                const Icon(
                  Icons.home_outlined,
                  size: 15,
                  color: tenantGreenDark,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _cuocTroChuyen.contextLabel,
                    style: const TextStyle(
                      color: tenantGreenDark,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(15, 18, 15, 14),
              itemCount: _danhSachTinNhan.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(
                      child: TenantStatusPill(
                        'Cuộc trò chuyện',
                        color: tenantMuted,
                      ),
                    ),
                  );
                }
                final tinNhan = _danhSachTinNhan[index - 1];
                return TenantMessageBubble(message: tinNhan);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: tenantLine)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => showTenantPreviewNotice(context),
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: tenantMuted,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _oNhapTinNhan,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: tenantCanvas,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  IconButton.filled(
                    tooltip: 'Gửi tin nhắn',
                    onPressed: _guiTinNhan,
                    style: IconButton.styleFrom(
                      backgroundColor: tenantGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm gửi tin nhắn đi
  void _guiTinNhan() {
    final noiDung = _oNhapTinNhan.text.trim();
    if (noiDung.isEmpty) {
      return;
    }
    // Lấy thời gian hiện tại định dạng giờ:phút
    final bayGio = DateTime.now();
    final gio = bayGio.hour.toString().padLeft(2, '0');
    final phut = bayGio.minute.toString().padLeft(2, '0');

    setState(() {
      _danhSachTinNhan.add(
        TenantConversationMessage(
          text: noiDung,
          time: '$gio:$phut',
          fromTenant: true,
        ),
      );
      _oNhapTinNhan.clear();
    });
  }
}
