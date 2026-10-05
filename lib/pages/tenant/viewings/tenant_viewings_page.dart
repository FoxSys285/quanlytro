import 'package:flutter/material.dart';

import '../../shared/viewings/models/room_viewing.dart';
import '../../shared/viewings/viewing_store.dart';
import '../tenant_ui.dart';
import 'components/tenant_viewing_card.dart';

class TenantViewingsPage extends StatefulWidget {
  const TenantViewingsPage({
    super.key,
    this.store,
    this.tenantId = ViewingStore.demoTenantId,
  });
  final ViewingStore? store;
  // Pass the authenticated tenant's ID when the backend is connected.
  final String tenantId;

  @override
  State<TenantViewingsPage> createState() => _TenantViewingsPageState();
}

class _TenantViewingsPageState extends State<TenantViewingsPage> {
  String _query = '';
  ViewingStatus? _status;
  ViewingStore get _store => widget.store ?? ViewingStore.instance;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final query = _query.trim().toLowerCase();
      final viewings = _store
          .forTenant(widget.tenantId)
          .where(
            (item) =>
                (_status == null || item.status == _status) &&
                '${item.roomName} ${item.address}'.toLowerCase().contains(
                  query,
                ),
          )
          .toList();
      return TenantPageFrame(
        children: [
          const TenantPageTitle(
            title: 'Lịch xem phòng',
            subtitle: 'Các phòng bạn đã đặt lịch, xếp từ sớm đến muộn.',
          ),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Tìm phòng hoặc địa chỉ',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: tenantLine),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _status == null,
                onSelected: (_) => setState(() => _status = null),
              ),
              for (final status in ViewingStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: _status == status,
                  onSelected: (selected) =>
                      setState(() => _status = selected ? status : null),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${viewings.length} lịch xem phòng',
            style: const TextStyle(
              color: tenantInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (viewings.isEmpty)
            const TenantSurface(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Chưa có lịch xem phòng phù hợp.',
                    style: TextStyle(color: tenantMuted),
                  ),
                ),
              ),
            ),
          for (final viewing in viewings)
            TenantViewingCard(key: ValueKey(viewing.id), viewing: viewing),
        ],
      );
    },
  );
}
