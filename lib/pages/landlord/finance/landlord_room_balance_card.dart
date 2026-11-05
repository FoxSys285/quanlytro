import 'package:flutter/material.dart';

import '../landlord_glass.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
import 'landlord_room_balance.dart';

Color roomPaymentColor(RoomPaymentState state) => switch (state) {
  RoomPaymentState.unpaid => const Color(0xFFDA4458),
  RoomPaymentState.paid => const Color(0xFF17A374),
  RoomPaymentState.unbilled => const Color(0xFFB78427),
  RoomPaymentState.vacant => const Color(0xFF8092AE),
};

class LandlordRoomBalanceCard extends StatelessWidget {
  const LandlordRoomBalanceCard({
    super.key,
    required this.balance,
    required this.onTap,
  });
  final LandlordRoomBalance balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = roomPaymentColor(balance.state);
    final palette = LandlordPalette.of(context);
    final details = balance.details;
    return Semantics(
      label: 'Phòng ${details.room.code}, ${balance.label}',
      child: LandlordGlassCard(
        tint: color,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 49,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                balance.state == RoomPaymentState.paid
                    ? Icons.check_circle_rounded
                    : Icons.meeting_room_rounded,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Phòng ${details.room.code}',
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: color, size: 21),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details.lease?.tenantName ?? 'Chưa có người thuê',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        balance.label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (balance.remaining > 0)
                        Text(
                          formatLandlordMoney(balance.remaining),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        )
                      else if (balance.state == RoomPaymentState.paid)
                        Text(
                          formatLandlordMoney(balance.monthlyPaid),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
