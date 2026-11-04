import 'package:flutter/material.dart';

import '../../landlord/incidents/models/landlord_suco.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../shared/rental/tenant_session.dart';
import '../tenant_detail_ui.dart';
import '../tenant_ui.dart';
import '../tenant_feature_ui.dart';

class TenantBaoSuCoPage extends StatefulWidget {
  const TenantBaoSuCoPage({
    super.key,
    this.store,
    this.tenantId = TenantSession.tenantId,
  });

  final LandlordDemoStore? store;
  final String tenantId;

  @override
  State<TenantBaoSuCoPage> createState() => _TenantBaoSuCoPageState();
}

class _TenantBaoSuCoPageState extends State<TenantBaoSuCoPage> {
  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;

  void _updateStatus(LandlordIncident incident, IncidentStatus status) {
    _store.updateIncident(incident, status, tenantId: widget.tenantId);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đã cập nhật: ${status.label}')));
  }

  Future<void> _createRequest() async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TenantDetailTheme(
        child: _IncidentRequestSheet(store: _store, tenantId: widget.tenantId),
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu cho chủ trọ.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final lease = _store.currentLeaseForTenant(widget.tenantId);
      final incidents = _store.incidentsForTenant(widget.tenantId);
      final waiting = incidents
          .where((i) => i.status == IncidentStatus.newly)
          .length;
      final processing = incidents
          .where((i) => i.status == IncidentStatus.inProgress)
          .length;
      final completed = incidents.length - waiting - processing;
      return TenantFeatureFrame(
        artwork: TenantFeatureArtwork.incidents,
        title: 'Báo cáo sự cố',
        subtitle: lease == null
            ? 'Gửi yêu cầu sửa chữa và theo dõi tiến độ xử lý.'
            : 'Gửi yêu cầu sửa chữa cho chủ trọ phòng ${lease.room}.',
        children: [
          TenantSurface(
            child: Row(
              children: [
                _metric('$waiting', 'Mới gửi', const Color(0xFFD64545)),
                _metric('$processing', 'Đang xử lý', const Color(0xFFB57920)),
                _metric('$completed', 'Đã xử lý', tenantGreenDark),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: lease == null ? null : _createRequest,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Tạo yêu cầu mới'),
            ),
          ),
          if (lease == null) ...[
            const SizedBox(height: 12),
            const TenantDetailNote(
              'Bạn cần có hợp đồng đang hiệu lực để gửi yêu cầu sửa chữa.',
            ),
          ],
          const SizedBox(height: 24),
          TenantSectionHeading(
            'Yêu cầu của tôi',
            trailing: Text(
              '${incidents.length} yêu cầu',
              style: const TextStyle(color: tenantMuted, fontSize: 11),
            ),
          ),
          if (incidents.isEmpty)
            const TenantEmptyState(
              icon: Icons.build_outlined,
              title: 'Chưa có sự cố nào',
              subtitle: 'Khi phòng có vấn đề, hãy gửi yêu cầu cho chủ trọ.',
            ),
          for (final incident in incidents) ...[
            TenantSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TenantDetailIcon(switch (incident.category) {
                        'Điện' => Icons.electrical_services_rounded,
                        'Nước' => Icons.water_drop_outlined,
                        'Internet' => Icons.wifi_rounded,
                        'Điện lạnh' => Icons.ac_unit_rounded,
                        _ => Icons.handyman_outlined,
                      }),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.title,
                              style: const TextStyle(
                                color: tenantInk,
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${incident.category} · ${incident.date}',
                              style: const TextStyle(
                                color: tenantMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  TenantStatusPill(
                    incident.status.label,
                    color: incident.status.color,
                  ),
                  const TenantThinDivider(),
                  Text(
                    incident.description,
                    style: const TextStyle(
                      color: tenantInk,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  if (incident.status == IncidentStatus.resolved) ...[
                    const SizedBox(height: 14),
                    const TenantDetailNote(
                      'Chủ trọ đã xử lý. Hãy kiểm tra và xác nhận kết quả.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                _updateStatus(incident, IncidentStatus.newly),
                            child: const Text('Mở lại'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () =>
                                _updateStatus(incident, IncidentStatus.closed),
                            child: const Text('Xác nhận'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          const TenantFeatureBanner(
            icon: Icons.support_agent_rounded,
            title: 'Theo dõi đến khi xử lý xong',
            subtitle: 'Kiểm tra kết quả sau khi chủ trọ xử lý. Bạn có thể xác nhận hoặc mở lại yêu cầu.',
          ),
        ],
      );
    },
  );

  Widget _metric(String value, String label, Color color) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: tenantMuted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _IncidentRequestSheet extends StatefulWidget {
  const _IncidentRequestSheet({required this.store, required this.tenantId});
  final LandlordDemoStore store;
  final String tenantId;

  @override
  State<_IncidentRequestSheet> createState() => _IncidentRequestSheetState();
}

class _IncidentRequestSheetState extends State<_IncidentRequestSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Điện';
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    try {
      widget.store.createIncident(
        tenantId: widget.tenantId,
        title: _title.text.trim(),
        category: _category,
        description: _description.text.trim(),
      );
      Navigator.pop(context, true);
    } on ArgumentError catch (error) {
      setState(() => _error = error.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) => TenantBottomSheetSurface(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TenantSheetHandle(),
          const TenantFormHeading(
            icon: Icons.handyman_rounded,
            title: 'Tạo yêu cầu sửa chữa',
            subtitle: 'Mô tả vấn đề để chủ trọ hỗ trợ bạn nhanh hơn.',
          ),
          const SizedBox(height: 20),
          TenantSurface(
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tiêu đề.'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Loại sự cố',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: [
                    for (final category in [
                      'Điện',
                      'Nước',
                      'Điện lạnh',
                      'Internet',
                      'Khác',
                    ])
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết',
                    alignLabelWithHint: true,
                    hintText: 'Vị trí xảy ra, biểu hiện và thời gian phát hiện sự cố…',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập mô tả.'
                      : null,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Gửi yêu cầu'),
            ),
          ),
        ],
      ),
    ),
  );
}
