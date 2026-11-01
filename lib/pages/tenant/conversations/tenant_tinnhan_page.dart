import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import '../../shared/conversations/conversation_store.dart';
import 'components/tenant_bongbongtinnhan.dart';
import 'models/tenant_cuoctrochuyen.dart';
import '../../landlord/landlord_demo_store.dart';

// Tên Class chính bằng tiếng Việt
class TenantTinNhanPage extends StatefulWidget {
  const TenantTinNhanPage({super.key, this.conversation});

  final TenantConversation? conversation;

  @override
  State<TenantTinNhanPage> createState() => _TenantTinNhanPageState();
}

class _TenantTinNhanPageState extends State<TenantTinNhanPage> {
  // Controller để điều khiển ô nhập tin nhắn
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  // Cuộc trò chuyện đang mở
  late final TenantConversation _cuocTroChuyen;

  @override
  void initState() {
    super.initState();
    // Nếu có truyền cuộc trò chuyện vào thì lấy, không thì lấy cuộc trò chuyện mẫu đầu tiên
    if (widget.conversation != null) {
      _cuocTroChuyen = widget.conversation!;
    } else {
      _cuocTroChuyen = TenantConversation.demoConversations.first;
    }
    if (_cuocTroChuyen.source == null) _cuocTroChuyen.unread = 0;

    // Lắng nghe thay đổi từ kho dữ liệu tin nhắn chung
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
    ConversationStore.instance.removeListener(_capNhat);
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToLatest() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    final source = _cuocTroChuyen.source;
    if (source != null && source.tenantUnread > 0) {
      ConversationStore.instance.markRead(source, landlord: false);
    }
  });

  void _showInfo() {
    final source = _cuocTroChuyen.source;
    final property = source == null
        ? null
        : RentalPortfolio.instance.byId(source.propertyId)?.property;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin cuộc trò chuyện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _cuocTroChuyen.landlordName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(_cuocTroChuyen.contextLabel),
            if (property != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                '${property.name}\n${property.address}\n${property.phone}',
              ),
            ],
            if (source?.leaseId != null) ...[
              const SizedBox(height: 12),
              SelectableText('Hợp đồng: ${source!.leaseId}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _quickMessage() async {
    final text = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final text in [
              'Chào chủ trọ, tôi muốn hỏi thêm về hợp đồng thuê phòng.',
              'Tôi đã thanh toán, nhờ chủ trọ kiểm tra giúp.',
              'Phòng đang có sự cố, nhờ chủ trọ hỗ trợ kiểm tra.',
            ])
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(text),
                onTap: () => Navigator.pop(context, text),
              ),
          ],
        ),
      ),
    );
    if (!mounted || text == null) return;
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
  }

  // Hàm gửi tin nhắn
  void _guiTinNhan() {
    final noiDung = _controller.text.trim();
    if (noiDung.isEmpty) {
      return;
    }

    final gioHienTai = TimeOfDay.now().format(context);
    setState(() {
      _cuocTroChuyen.send(noiDung, gioHienTai);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final danhSachTinNhan = _cuocTroChuyen.messages;

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
            onPressed: _showInfo,
            icon: const Icon(Icons.info_outline_rounded, color: tenantGreen),
          ),
        ],
      ),
      body: Column(
        children: [
          // Dải thông tin ngữ cảnh phòng trọ ở đầu khung chat
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
          // Danh sách các tin nhắn trao đổi
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(15, 18, 15, 14),
              itemCount: danhSachTinNhan.length + 1,
              itemBuilder: (context, index) {
                // Mục đầu tiên là huy hiệu bắt đầu cuộc trò chuyện
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
                // Các tin nhắn tiếp theo
                final tinNhan = danhSachTinNhan[index - 1];
                return TenantMessageBubble(message: tinNhan);
              },
            ),
          ),
          // Khung nhập tin nhắn và nút gửi ở dưới đáy
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
                    tooltip: 'Tin nhắn gợi ý',
                    onPressed: _quickMessage,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: tenantMuted,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
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
}
