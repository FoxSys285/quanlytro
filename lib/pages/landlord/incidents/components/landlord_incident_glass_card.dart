import 'package:flutter/material.dart';

import '../../landlord_demo_store.dart';
import '../../landlord_glass.dart';
import '../../landlord_theme.dart';
import '../../landlord_ui.dart';
import '../models/landlord_suco.dart';

Future<void> showLandlordIncidentDetails(
  BuildContext context,
  LandlordDemoStore store,
  LandlordIncident incident,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            incident.title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text('Phòng ${incident.room} · ${incident.category}'),
          Text(
            '${incident.reporter} · ${incident.date}',
            style: TextStyle(
              color: LandlordPalette.of(context).muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(incident.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 20),
          const Text(
            'Cập nhật trạng thái',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final status in IncidentStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: incident.status == status,
                  onSelected: (_) {
                    try {
                      store.updateIncident(incident, status);
                    } on ArgumentError catch (error) {
                      showLandlordMessage(context, error.message.toString());
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    ),
  ),
);

class LandlordIncidentGlassCard extends StatelessWidget {
  const LandlordIncidentGlassCard({
    super.key,
    required this.incident,
    required this.store,
  });
  final LandlordIncident incident;
  final LandlordDemoStore store;
  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return LandlordGlassCard(
      tint: incident.status.color,
      onTap: () => showLandlordIncidentDetails(context, store, incident),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 44,
            decoration: BoxDecoration(
              color: incident.status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              incident.urgent
                  ? Icons.warning_amber_rounded
                  : Icons.handyman_outlined,
              color: incident.status.color,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.title,
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phòng ${incident.room} · ${incident.reporter}',
                  style: TextStyle(color: palette.muted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    LandlordStatusPill(
                      incident.status.label,
                      color: incident.status.color,
                    ),
                    if (incident.urgent)
                      const LandlordStatusPill(
                        'Khẩn cấp',
                        color: Color(0xFFDA4458),
                      ),
                    Text(
                      incident.date,
                      style: TextStyle(color: palette.muted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: propertyBlue,
            size: 22,
          ),
        ],
      ),
    );
  }
}
