import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../viewings/data/viewing_conversation_store.dart';
import 'landlord_chat_page.dart';
import 'models/landlord_conversation.dart';

class LandlordConversationsPage extends StatefulWidget {
  const LandlordConversationsPage({super.key});

  @override
  State<LandlordConversationsPage> createState() =>
      _LandlordConversationsPageState();
}

class _LandlordConversationsPageState extends State<LandlordConversationsPage> {
  // Danh sách các cuộc trò chuyện mẫu với người thuê
  final List<LandlordConversation> _danhSachCuocTroChuyen = [
    LandlordConversation(
      tenantName: 'Minh Anh',
      room: 'A.302',
      unread: 1,
      messages: [
        const LandlordMessage(
          text: 'Chào bạn, bạn cần hỗ trợ gì về phòng đang thuê?',
          time: '09:12',
          fromLandlord: true,
        ),
        const LandlordMessage(
          text: 'Dạ em muốn hỏi về lịch sửa máy lạnh ạ.',
          time: '09:15',
          fromLandlord: false,
        ),
      ],
    ),
    LandlordConversation(
      tenantName: 'Lê Văn Khoa',
      room: 'A.101',
      messages: [
        const LandlordMessage(
          text: 'Anh ơi hóa đơn tháng này em chuyển khoản rồi nhé.',
          time: 'Hôm qua',
          fromLandlord: false,
        ),
        const LandlordMessage(
          text: 'Ok em, anh sẽ kiểm tra và xác nhận.',
          time: 'Hôm qua',
          fromLandlord: true,
        ),
      ],
    ),
    LandlordConversation(
      tenantName: 'Phạm Quốc Bảo',
      room: 'B.105',
      unread: 2,
      messages: [
        const LandlordMessage(
          text: 'Em muốn thêm bạn vào ở cùng phòng được không anh?',
          time: '08:40',
          fromLandlord: false,
        ),
      ],
    ),
  ];

  // Hàm mở màn hình chat chi tiết với người thuê
  Future<void> _moManHinhTroChuyen(LandlordConversation cuocTroChuyen) async {
    // Đánh dấu đã đọc hết tin nhắn
    setState(() {
      cuocTroChuyen.unread = 0;
    });

    // Chuyển sang màn hình chat
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LandlordChatPage(conversation: cuocTroChuyen),
      ),
    );

    // Cập nhật lại tin nhắn cuối sau khi quay về
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gom tất cả cuộc trò chuyện từ hệ thống xem phòng và danh sách nội bộ
    final List<LandlordConversation> tatCaCuocTroChuyen = [];
    tatCaCuocTroChuyen.addAll(ViewingConversationStore.instance.conversations);
    tatCaCuocTroChuyen.addAll(_danhSachCuocTroChuyen);

    // Danh sách widget hiển thị trên giao diện
    final List<Widget> danhSachWidget = [
      const LandlordPageTitle(
        title: 'Tin nhắn',
        subtitle: 'Trao đổi với người thuê theo từng phòng.',
      ),
    ];

    // Kiểm tra nếu chưa có cuộc trò chuyện nào
    if (tatCaCuocTroChuyen.isEmpty) {
      danhSachWidget.add(
        const LandlordEmptyState(message: 'Chưa có cuộc trò chuyện nào.'),
      );
    } else {
      for (int i = 0; i < tatCaCuocTroChuyen.length; i++) {
        final cuocTroChuyen = tatCaCuocTroChuyen[i];

        // Nếu có tin nhắn chưa đọc thì in đậm tiêu đề
        FontWeight doDamTieuDe;
        if (cuocTroChuyen.unread > 0) {
          doDamTieuDe = FontWeight.w800;
        } else {
          doDamTieuDe = FontWeight.w600;
        }

        // Tạo chấm thông báo số tin nhắn chưa đọc
        Widget? huyHieuChuaDoc;
        if (cuocTroChuyen.unread > 0) {
          huyHieuChuaDoc = Padding(
            padding: const EdgeInsets.only(top: 4),
            child: CircleAvatar(
              radius: 9,
              backgroundColor: landlordBlue,
              child: Text(
                '${cuocTroChuyen.unread}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          );
        }

        // Cột bên phải: hiển thị thời gian và số tin chưa đọc nếu có
        final List<Widget> danhSachCotPhai = [
          Text(
            cuocTroChuyen.lastMessage.time,
            style: const TextStyle(color: landlordMuted, fontSize: 11),
          ),
        ];

        if (huyHieuChuaDoc != null) {
          danhSachCotPhai.add(huyHieuChuaDoc);
        }

        // Thêm thẻ cuộc trò chuyện vào danh sách hiển thị
        danhSachWidget.add(
          LandlordCard(
            padding: EdgeInsets.zero,
            onTap: () {
              _moManHinhTroChuyen(cuocTroChuyen);
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: landlordBlue.withValues(alpha: 0.1),
                child: Text(
                  cuocTroChuyen.tenantName[0],
                  style: const TextStyle(
                    color: landlordBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                '${cuocTroChuyen.tenantName} · ${cuocTroChuyen.room}',
                style: TextStyle(
                  fontWeight: doDamTieuDe,
                ),
              ),
              subtitle: Text(
                cuocTroChuyen.lastMessage.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: danhSachCotPhai,
              ),
            ),
          ),
        );
      }
    }

    return LandlordPageFrame(
      children: danhSachWidget,
    );
  }
}
