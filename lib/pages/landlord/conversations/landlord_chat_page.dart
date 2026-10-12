import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import 'models/landlord_conversation.dart';

class LandlordChatPage extends StatefulWidget {
  const LandlordChatPage({super.key, required this.conversation});

  final LandlordConversation conversation;

  @override
  State<LandlordChatPage> createState() => _LandlordChatPageState();
}

class _LandlordChatPageState extends State<LandlordChatPage> {
  // Bộ điều khiển ô nhập tin nhắn
  final TextEditingController _boDieuKhienNhapTin = TextEditingController();

  @override
  void dispose() {
    _boDieuKhienNhapTin.dispose();
    super.dispose();
  }

  // Hàm gửi tin nhắn mới
  void _guiTinNhan() {
    final noiDung = _boDieuKhienNhapTin.text.trim();
    // Nếu tin nhắn trống thì không gửi
    if (noiDung.isEmpty) {
      return;
    }

    // Định dạng giờ phút 24h
    final bayGio = DateTime.now();
    final gio = bayGio.hour.toString().padLeft(2, '0');
    final phut = bayGio.minute.toString().padLeft(2, '0');
    final thoiGianGui = '$gio:$phut';

    setState(() {
      widget.conversation.messages.add(
        LandlordMessage(
          text: noiDung,
          time: thoiGianGui,
          fromLandlord: true, // Tin nhắn do chủ trọ gửi
        ),
      );
      _boDieuKhienNhapTin.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final danhSachTinNhan = widget.conversation.messages;

    return Scaffold(
      backgroundColor: landlordCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${widget.conversation.tenantName} · ${widget.conversation.room}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Danh sách hiển thị các bong bóng tin nhắn
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: danhSachTinNhan.length,
              itemBuilder: (context, index) {
                final tinNhan = danhSachTinNhan[index];
                return _BongBongTinNhan(tinNhan: tinNhan);
              },
            ),
          ),

          // Thanh công cụ nhập và gửi tin nhắn ở dưới đáy màn hình
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _boDieuKhienNhapTin,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: landlordCanvas,
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
                    style: IconButton.styleFrom(backgroundColor: landlordBlue),
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

// Widget hiển thị từng bong bóng tin nhắn trong cuộc trò chuyện
class _BongBongTinNhan extends StatelessWidget {
  const _BongBongTinNhan({required this.tinNhan});

  final LandlordMessage tinNhan;

  @override
  Widget build(BuildContext context) {
    // Xác định tin nhắn là của chủ trọ gửi hay người thuê gửi
    final bool laCuaChuTro = tinNhan.fromLandlord;

    Alignment canLeBongBong;
    Color mauNenBongBong;
    Border? vienBongBong;
    Color mauChuTinNhan;
    Color mauChuThoiGian;

    // Phân biệt kiểu dáng bong bóng bằng if-else tường minh
    if (laCuaChuTro) {
      canLeBongBong = Alignment.centerRight;
      mauNenBongBong = landlordBlue;
      vienBongBong = null;
      mauChuTinNhan = Colors.white;
      mauChuThoiGian = Colors.white70;
    } else {
      canLeBongBong = Alignment.centerLeft;
      mauNenBongBong = Colors.white;
      vienBongBong = Border.all(color: landlordLine);
      mauChuTinNhan = landlordInk;
      mauChuThoiGian = landlordMuted;
    }

    return Align(
      alignment: canLeBongBong,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: mauNenBongBong,
          borderRadius: BorderRadius.circular(14),
          border: vienBongBong,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              tinNhan.text,
              style: TextStyle(
                color: mauChuTinNhan,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tinNhan.time,
              style: TextStyle(
                color: mauChuThoiGian,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
