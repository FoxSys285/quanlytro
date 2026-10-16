import 'package:flutter/material.dart';

import '../models/tenant_conversation_message.dart';
import '../../tenant_ui.dart';

class TenantMessageBubble extends StatelessWidget {
  const TenantMessageBubble({super.key, required this.message});
  final TenantConversationMessage message;

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem tin nhắn có phải do người thuê gửi hay không
    final laTinNhanNguoiThue = message.fromTenant;

    // Các biến định dạng giao diện cho bong bóng chat
    Alignment canLe;
    Color mauNenBongBong;
    Border? vienBongBong;
    Color mauChu;
    Color mauThoiGian;
    Radius boGocDuoiTrai;
    Radius boGocDuoiPhai;

    // Nếu người thuê gửi: căn phải, nền xanh, chữ trắng
    // Nếu chủ trọ gửi: căn trái, nền trắng, chữ đậm
    if (laTinNhanNguoiThue) {
      canLe = Alignment.centerRight;
      mauNenBongBong = tenantGreen;
      vienBongBong = null;
      mauChu = Colors.white;
      mauThoiGian = Colors.white70;
      boGocDuoiTrai = const Radius.circular(16);
      boGocDuoiPhai = const Radius.circular(4);
    } else {
      canLe = Alignment.centerLeft;
      mauNenBongBong = Colors.white;
      vienBongBong = Border.all(color: tenantLine);
      mauChu = tenantInk;
      mauThoiGian = tenantMuted;
      boGocDuoiTrai = const Radius.circular(4);
      boGocDuoiPhai = const Radius.circular(16);
    }

    return Align(
      alignment: canLe,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 7),
        decoration: BoxDecoration(
          color: mauNenBongBong,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: boGocDuoiTrai,
            bottomRight: boGocDuoiPhai,
          ),
          border: vienBongBong,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: mauChu,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              message.time,
              style: TextStyle(
                color: mauThoiGian,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
