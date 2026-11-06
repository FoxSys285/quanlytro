import 'package:flutter/material.dart';

import '../../landlord_theme.dart';
import '../models/landlord_room.dart';

enum LandlordRoomHighlight {
  vacant,
  occupied,
  upcoming,
  unpaid,
  overdue,
  expiring,
  maintenance,
  pendingReview,
  paid,
  unbilled,
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
    this.actions = const [],
    this.compact = false,
    this.secondaryText,
    this.valueText,
  });

  final LandlordRoomDetails details;
  final VoidCallback onTap;
  final LandlordRoomHighlight? highlight;
  final List<LandlordRoomAction> actions;
  final bool compact;
  final String? secondaryText;
  final String? valueText;

  LandlordRoomHighlight get _state =>
      highlight ??
      switch (details.status) {
        LandlordRoomStatus.vacant => LandlordRoomHighlight.vacant,
        LandlordRoomStatus.occupied => LandlordRoomHighlight.occupied,
        LandlordRoomStatus.upcoming => LandlordRoomHighlight.upcoming,
      };

  Color get _statusColor => switch (_state) {
    LandlordRoomHighlight.vacant => const Color(0xFF16836F),
    LandlordRoomHighlight.occupied => const Color(0xFF198754),
    LandlordRoomHighlight.upcoming => const Color(0xFF63738B),
    LandlordRoomHighlight.unpaid ||
    LandlordRoomHighlight.overdue => const Color(0xFFD64545),
    LandlordRoomHighlight.expiring => const Color(0xFFD99412),
    LandlordRoomHighlight.maintenance => const Color(0xFF8054B8),
    LandlordRoomHighlight.pendingReview => const Color(0xFFD99412),
    LandlordRoomHighlight.paid => const Color(0xFF17A374),
    LandlordRoomHighlight.unbilled => const Color(0xFFB78427),
  };

  String get _label => switch (_state) {
    LandlordRoomHighlight.vacant => 'Phòng trống',
    LandlordRoomHighlight.occupied => 'Đang thuê',
    LandlordRoomHighlight.upcoming => 'Sắp nhận phòng',
    LandlordRoomHighlight.unpaid => 'Chưa đóng tiền',
    LandlordRoomHighlight.overdue => 'Chưa đóng tiền',
    LandlordRoomHighlight.expiring => 'Sắp hết hạn',
    LandlordRoomHighlight.maintenance => 'Đang sửa chữa',
    LandlordRoomHighlight.pendingReview => 'Đang chờ duyệt',
    LandlordRoomHighlight.paid => 'Đã đóng tiền',
    LandlordRoomHighlight.unbilled => 'Chưa lập phiếu thu',
  };

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final color = _statusColor;
    final vacant = _state == LandlordRoomHighlight.vacant;
    final fill = vacant
        ? palette.surface
        : color.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? .16 : .07,
          );
    final border = vacant ? palette.line : color.withValues(alpha: .28);
    final statusPill = Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: vacant ? palette.surfaceAlt : color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: vacant ? palette.muted : color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Semantics(
      button: true,
      label: 'Phòng ${details.room.code}, ${details.typeName}, $_label',
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .07),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Phòng ${details.room.code}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: compact ? 15 : 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.25,
                          ),
                        ),
                      ),
                      if (!compact) ...[const SizedBox(width: 8), statusPill],
                    ],
                  ),
                  if (compact) ...[
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerLeft, child: statusPill),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    details.typeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                  if (secondaryText?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      secondaryText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
                  ],
                  if (valueText?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      valueText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    if (compact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var index = 0;
                            index < actions.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(height: 7),
                            _ActionButton(action: actions[index], color: color),
                          ],
                        ],
                      )
                    else
                      Row(
                        children: [
                          for (
                            var index = 0;
                            index < actions.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _ActionButton(
                                action: actions[index],
                                color: color,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.color});
  final LandlordRoomAction action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = action.primary
        ? FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 38),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: .35)),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 38),
          );
    final label = Text(
      action.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    );
    return action.primary
        ? FilledButton.icon(
            onPressed: action.onTap,
            style: style,
            icon: Icon(action.icon, size: 16),
            label: label,
          )
        : OutlinedButton.icon(
            onPressed: action.onTap,
            style: style,
            icon: Icon(action.icon, size: 16),
            label: label,
          );
  }
}
