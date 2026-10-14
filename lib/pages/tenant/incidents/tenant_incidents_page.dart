import 'package:flutter/material.dart';

import '../tenant_ui.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../landlord/incidents/models/landlord_incident.dart';
import '../../shared/rental/tenant_session.dart';

class TenantIncidentsPage extends StatefulWidget {
  const TenantIncidentsPage({
    super.key,
    this.store,
    this.tenantId = TenantSession.tenantId,
  });
  final LandlordDemoStore? store;
  final String tenantId;

  @override
  State<TenantIncidentsPage> createState() => _TenantIncidentsPageState();
}

class _TenantIncidentsPageState extends State<TenantIncidentsPage> {
  static const _categories = ['Điện', 'Nước', 'Điện lạnh', 'Internet', 'Khác'];

  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;
  List<LandlordIncident> get _incidents =>
      _store.incidentsForTenant(widget.tenantId);
  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TenantPageFrame(
      children: [
        TenantPageTitle(
          title: 'Báo sự cố',
          subtitle:
              'Gửi yêu cầu sửa chữa cho chủ trọ${_store.currentLeaseForTenant(widget.tenantId) == null ? '' : ' phòng ${_store.currentLeaseForTenant(widget.tenantId)!.room}'}.',
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _store.currentLeaseForTenant(widget.tenantId) == null
                ? null
                : _openCreateSheet,
            style: FilledButton.styleFrom(backgroundColor: tenantGreen),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tạo yêu cầu mới'),
          ),
        ),
        const SizedBox(height: 18),
        const TenantSectionHeading('Yêu cầu của tôi'),
        if (_incidents.isEmpty)
          const TenantEmptyState(
            icon: Icons.build_outlined,
            title: 'Chưa có sự cố nào',
            subtitle: 'Khi phòng có vấn đề, hãy gửi yêu cầu cho chủ trọ.',
          ),
        for (final incident in _incidents) ...[
          TenantSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        incident.title,
                        style: const TextStyle(
                          color: tenantInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TenantStatusPill(
                      incident.status.label,
                      color: incident.status.color,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${incident.category} · ${incident.date}',
                  style: const TextStyle(color: tenantMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.description,
                  style: const TextStyle(color: tenantInk, fontSize: 13),
                ),
                // Khi chủ trọ báo đã xử lý, người thuê xác nhận hoặc mở lại.
                if (incident.status == IncidentStatus.resolved) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            _changeStatus(incident, IncidentStatus.newly),
                        child: const Text('Mở lại'),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: () =>
                            _changeStatus(incident, IncidentStatus.closed),
                        style: FilledButton.styleFrom(
                          backgroundColor: tenantGreen,
                        ),
                        child: const Text('Xác nhận'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _changeStatus(LandlordIncident incident, IncidentStatus status) {
    _store.updateIncident(incident, status, tenantId: widget.tenantId);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đã cập nhật: ${status.label}')));
  }

  Future<void> _openCreateSheet() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var category = _categories.first;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => TenantBottomSheetSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TenantSheetHandle(),
              const Text(
                'Tạo yêu cầu sửa chữa',
                style: TextStyle(
                  color: tenantInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Loại sự cố',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final item in _categories)
                    DropdownMenuItem(value: item, child: Text(item)),
                ],
                onChanged: (value) =>
                    setSheetState(() => category = value ?? category),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(backgroundColor: tenantGreen),
                  child: const Text('Gửi yêu cầu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final title = titleController.text.trim();
    final description = descController.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề và mô tả.')),
      );
      return;
    }

    try {
      _store.createIncident(
        tenantId: widget.tenantId,
        title: title,
        category: category,
        description: description,
      );
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message.toString())));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi yêu cầu cho chủ trọ.')),
    );
  }
}
