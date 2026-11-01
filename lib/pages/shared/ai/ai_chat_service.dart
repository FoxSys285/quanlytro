import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_demo_store.dart';
import '../rental/tenant_session.dart';

class AiMessage {
  const AiMessage({required this.role, required this.content});
  final String role;
  final String content;
}

class AiChatException implements Exception {
  const AiChatException(this.message);
  final String message;
}

class AiChatReply {
  const AiChatReply(this.text, {this.truncated = false});
  final String text;
  final bool truncated;
}

class AiChatService {
  AiChatService({this.client, Uri? endpoint})
    : _endpoint = endpoint ?? defaultEndpoint;

  final http.Client? client;
  final Uri _endpoint;

  static Uri get defaultEndpoint {
    const configured = String.fromEnvironment('AI_PROXY_URL');
    final base = configured.isNotEmpty
        ? configured
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8765'
        : 'http://127.0.0.1:8765';
    return Uri.parse('${base.replaceAll(RegExp(r'/+$'), '')}/api/chat');
  }

  Future<AiChatReply> reply({
    required AppRole role,
    required List<AiMessage> messages,
    required String context,
  }) async {
    // Keep complete user/assistant pairs, ending with the latest question.
    final history = [...messages];
    while (history.length > 19 ||
        (history.length > 1 &&
            history.fold<int>(0, (total, item) => total + item.content.length) >
                18000)) {
      history.removeRange(0, 2);
    }
    final body = jsonEncode({
      'role': role.name,
      'messages': [
        for (final message in history)
          {
            'role': message.role,
            'content': message.content.length > 6000
                ? message.content.substring(0, 6000)
                : message.content,
          },
      ],
      'context': context,
    });
    http.Response response;
    try {
      final post = client?.post ?? http.post;
      response = await post(
        _endpoint,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 55));
    } on TimeoutException {
      throw const AiChatException('AI phản hồi quá lâu. Bạn thử lại nhé.');
    } catch (_) {
      throw const AiChatException(
        'Chưa kết nối được trợ lý AI. Kiểm tra mạng và dịch vụ AI rồi thử lại nhé.',
      );
    }
    Map<String, dynamic> data;
    try {
      data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw const AiChatException(
        'Dịch vụ AI trả về dữ liệu không hợp lệ. Bạn thử lại sau nhé.',
      );
    }
    if (response.statusCode != 200) {
      // Only accept known proxy errors, not HTML or arbitrary upstream details.
      final error = data['error'];
      throw AiChatException(
        error is String && error.length < 300
            ? error
            : 'AI tạm thời không trả lời được. Bạn thử lại sau nhé.',
      );
    }
    final answer = data['answer'];
    if (answer is! String || answer.trim().isEmpty) {
      throw const AiChatException(
        'AI chưa trả về câu trả lời. Bạn thử hỏi lại nhé.',
      );
    }
    return AiChatReply(answer.trim(), truncated: data['truncated'] == true);
  }
}

String buildAiContext(AppRole role, LandlordDemoStore store) {
  final data = <String, Object?>{
    'vaiTro': role.label,
    'duLieu': 'Bản xem trước, chỉ lưu trong phiên chạy; không phải dữ liệu đã xác thực.',
    'nhaTro': store.property.name,
  };
  if (role == AppRole.tenant) {
    final lease = store.currentLeaseForTenant(TenantSession.tenantId);
    data['choOHienTai'] = lease == null
        ? null
        : {
            'phong': lease.room,
            'tienThueThang': lease.monthlyRent,
            'tienDatCoc': lease.deposit,
            'ngayDongTien': lease.dueDay,
            'giaDienKwh': lease.electricityPrice,
            'giaNuoc': lease.waterPrice,
            'cachTinhNuoc': lease.waterType,
            'phiXe': lease.vehicleFee,
            'phiDichVu': lease.serviceFee,
            'soNguoiDaDuyet': store.membersForLease(lease.id).length,
            'sucChua': store.roomByCode(lease.room)?.capacity,
          };
    data['hoaDonCuaBan'] = [
      for (final invoice
          in store
              .invoicesForTenant(TenantSession.tenantId)
              .where((item) => !item.cancelled))
        {
          'ky': '${invoice.period.month}/${invoice.period.year}',
          'conPhaiTra': invoice.remaining,
        },
    ];
  } else {
    data['tongSoPhong'] = store.roomDetails.length;
    data['soHopDongDangHieuLuc'] = store.activeLeases.length;
  }
  data['phongTrong'] = [
    for (final room in store.roomDetails.where(
      (item) => item.lease == null && item.type != null,
    ))
      {
        'phong': room.room.code,
        'tang': room.room.floor,
        'loai': room.typeName,
        'giaThang': room.monthlyRent,
        'dienTichM2': room.room.area,
        'sucChua': room.room.capacity,
      },
  ];
  // No citizen IDs, contact numbers, bank accounts, images or other tenants' records.
  return jsonEncode(data);
}
