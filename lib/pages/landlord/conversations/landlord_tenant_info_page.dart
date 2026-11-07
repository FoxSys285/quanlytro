import 'package:flutter/material.dart';

import '../../shared/viewings/viewing_store.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
import 'models/landlord_cuoctrochuyen.dart';

class LandlordTenantInfoPage extends StatelessWidget {
  const LandlordTenantInfoPage({super.key, required this.conversation});

  final LandlordConversation conversation;

  @override
  Widget build(BuildContext context) {
    final store = RentalPortfolio.instance.byId(conversation.propertyId);
    final lease = store == null
        ? null
        : (conversation.leaseId == null
                  ? null
                  : store.leaseById(conversation.leaseId!)) ??
              store.leasesForTenant(conversation.tenantId).firstOrNull;
    final tenantName = conversation.tenantName.trim();
    final viewings =
        ViewingStore.instance.forProperty(conversation.propertyId).where((
          viewing,
        ) {
          if (conversation.tenantId.trim().isNotEmpty) {
            return viewing.tenantId == conversation.tenantId;
          }
          return viewing.customerName.trim().toLowerCase() ==
              tenantName.toLowerCase();
        }).toList()..sort(
          (a, b) =>
              (b.createdAt ?? b.startsAt).compareTo(a.createdAt ?? a.startsAt),
        );
    final leasePhone = lease?.phone.trim() ?? '';
    final phone = leasePhone.isNotEmpty
        ? leasePhone
        : viewings.firstOrNull?.phone.trim() ?? '';
    final palette = LandlordPalette.of(context);

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: const Text('Thông tin người thuê trọ')),
      body: PropertyPortfolioBackdrop(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LandlordGlassSection(
                      title: 'Thông tin cá nhân',
                      subtitle: 'Thông tin liên hệ của người đang trò chuyện',
                    ),
                    LandlordGlassCard(
                      child: Column(
                        children: [
                          _InfoLine(
                            icon: Icons.person_outline_rounded,
                            label: 'Họ tên',
                            value: tenantName,
                            palette: palette,
                          ),
                          const Divider(height: 24),
                          _InfoLine(
                            icon: Icons.call_outlined,
                            label: 'Số điện thoại',
                            value: phone,
                            palette: palette,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final String value;
  final LandlordPalette palette;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: palette.primarySoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: palette.accent, size: 21),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: palette.muted, fontSize: 12)),
            const SizedBox(height: 5),
            SelectableText(
              value.isEmpty ? 'Chưa cập nhật' : value,
              style: TextStyle(
                color: palette.ink,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
