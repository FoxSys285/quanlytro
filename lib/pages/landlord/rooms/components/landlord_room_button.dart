import 'package:flutter/material.dart';

import '../../../shared/media/room_photo_gallery.dart';
import '../../finance/landlord_finance_models.dart';
import '../../incidents/models/landlord_suco.dart';
import '../../landlord_theme.dart';
import '../../landlord_ui.dart';
import '../models/landlord_room.dart';

enum LandlordRoomHighlight {
  vacant,
  occupied,
  upcoming,
  unpaid,
  overdue,
  expiring,
  maintenance,
}

class LandlordRoomAction {
  const LandlordRoomAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
}

class LandlordRoomButton extends StatelessWidget {
  const LandlordRoomButton({
    super.key,
    required this.details,
    required this.onTap,
    this.highlight,
    this.invoice,
    this.incident,
    this.actions = const [],
    this.onEdit,
    this.onDelete,
    this.compact = false,
  });

  final LandlordRoomDetails details;
  final VoidCallback onTap;
  final LandlordRoomHighlight? highlight;
  final LandlordInvoice? invoice;
  final LandlordIncident? incident;
  final List<LandlordRoomAction> actions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool compact;

  LandlordRoomHighlight get _state =>
      highlight ??
      switch (details.status) {
        LandlordRoomStatus.vacant => LandlordRoomHighlight.vacant,
        LandlordRoomStatus.occupied => LandlordRoomHighlight.occupied,
        LandlordRoomStatus.upcoming => LandlordRoomHighlight.upcoming,
      };

  Color get _color => switch (_state) {
    LandlordRoomHighlight.vacant => const Color(0xFF059669),
    LandlordRoomHighlight.occupied => const Color(0xFF2563EB),
    LandlordRoomHighlight.upcoming => const Color(0xFF7C64C6),
    LandlordRoomHighlight.unpaid => const Color(0xFFD28720),
    LandlordRoomHighlight.overdue => const Color(0xFFE04747),
    LandlordRoomHighlight.expiring => const Color(0xFFE29A17),
    LandlordRoomHighlight.maintenance => const Color(0xFF728198),
  };

  String get _label => switch (_state) {
    LandlordRoomHighlight.vacant => 'Phòng trống',
    LandlordRoomHighlight.occupied => 'Đang thuê',
    LandlordRoomHighlight.upcoming => 'Sắp nhận phòng',
    LandlordRoomHighlight.unpaid => 'Chưa thanh toán',
    LandlordRoomHighlight.overdue => 'Quá hạn',
    LandlordRoomHighlight.expiring => 'Sắp hết hạn',
    LandlordRoomHighlight.maintenance => 'Đang sửa chữa',
  };

  String _description() {
    if (_state == LandlordRoomHighlight.overdue && invoice != null) {
      final days = DateTime.now().difference(invoice!.dueDate).inDays;
      return 'Quá hạn ${days < 1 ? 1 : days} ngày · Còn nợ ${formatLandlordMoney(invoice!.remaining)}';
    }
    if (_state == LandlordRoomHighlight.expiring && details.lease != null) {
      final days = details.lease!.endDate.difference(DateTime.now()).inDays;
      return 'Hợp đồng còn ${days < 0 ? 0 : days + 1} ngày';
    }
    if (_state == LandlordRoomHighlight.maintenance && incident != null) {
      return incident!.title;
    }
    if (_state == LandlordRoomHighlight.upcoming && details.lease != null) {
      return 'Nhận phòng ${landlordDate(details.lease!.startDate)}';
    }
    if (_state == LandlordRoomHighlight.vacant) {
      return 'Sẵn sàng đón khách thuê';
    }
    if (_state == LandlordRoomHighlight.unpaid) {
      return 'Có hóa đơn đang chờ thanh toán';
    }
    return '${details.room.area} m² · Tối đa ${details.room.capacity} người';
  }

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final lease = details.lease;
    final photos = details.type?.photos ?? const [];
    final showPhoto =
        photos.isNotEmpty &&
        (_state == LandlordRoomHighlight.vacant || compact);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_color, _color, palette.surface, palette.surface],
            stops: const [0, 0.01, 0.01, 1],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.line),
          boxShadow: [
            BoxShadow(
              color: palette.ink.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 7, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: _color.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              details.room.code,
                              style: TextStyle(
                                color: _color,
                                fontSize: compact ? 11 : 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              details.typeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: compact ? 12 : 14,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                          if (!compact) ...[
                            Container(
                              constraints: const BoxConstraints(maxWidth: 96),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _label,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Tùy chọn phòng ${details.room.code}',
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: palette.muted,
                                size: 19,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') onEdit?.call();
                                if (value == 'delete') onDelete?.call();
                                if (value == 'detail') onTap();
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'detail',
                                  child: Text('Xem chi tiết'),
                                ),
                                if (onEdit != null)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Chỉnh sửa phòng'),
                                  ),
                                if (onDelete != null)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Xóa phòng'),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tầng ${details.room.floor} · ${details.room.area} m² · ${details.room.capacity} người',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.muted, fontSize: 11),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          _description(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _state == LandlordRoomHighlight.overdue
                                ? _color
                                : palette.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (showPhoto)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: compact ? 84 : 112,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RoomPhotoImage(
                          photo: photos.first,
                          label: 'Ảnh phòng ${details.room.code}',
                        ),
                        Positioned(
                          left: 8,
                          bottom: 7,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${photos.length} ảnh',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!compact && lease != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: _color.withValues(alpha: 0.13),
                        child: Text(
                          lease.tenantName.trim().isEmpty
                              ? '?'
                              : lease.tenantName
                                    .trim()
                                    .split(' ')
                                    .last[0]
                                    .toUpperCase(),
                          style: TextStyle(
                            color: _color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lease.tenantName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Hạn HĐ: ${landlordDate(lease.endDate)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (invoice?.status == LandlordInvoiceStatus.paid)
                        _PaymentPill(
                          label: 'Đã đóng',
                          color: const Color(0xFF059669),
                        ),
                      if (invoice != null &&
                          invoice!.remaining > 0 &&
                          invoice!.status != LandlordInvoiceStatus.paid)
                        _PaymentPill(
                          label: 'Còn nợ',
                          color: const Color(0xFFE04747),
                        ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lease == null ? 'Giá niêm yết' : 'Giá thuê tháng',
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              details.monthlyRent == null
                                  ? 'Chưa có giá thuê'
                                  : formatLandlordMoney(details.monthlyRent!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _state == LandlordRoomHighlight.overdue
                                    ? _color
                                    : palette.ink,
                                fontSize: compact ? 13 : 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (compact)
                        IconButton(
                          tooltip: 'Xem phòng ${details.room.code}',
                          onPressed: onTap,
                          icon: Icon(
                            Icons.arrow_forward_rounded,
                            color: _color,
                            size: 19,
                          ),
                        ),
                    ],
                  ),
                  if (!compact && actions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (
                          var index = 0;
                          index < actions.take(2).length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _ActionButton(
                              action: actions[index],
                              color: _color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentPill extends StatelessWidget {
  const _PaymentPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.color});
  final LandlordRoomAction action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return action.primary
        ? FilledButton.icon(
            onPressed: action.onTap,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            icon: Icon(action.icon, size: 15),
            label: Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          )
        : TextButton.icon(
            onPressed: action.onTap,
            style: TextButton.styleFrom(
              backgroundColor: color.withValues(alpha: 0.1),
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            icon: Icon(action.icon, size: 15),
            label: Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          );
  }
}
