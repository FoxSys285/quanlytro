import 'package:flutter/material.dart';

import '../tenant_ui.dart';

class TenantIncident {
  TenantIncident({
    required this.title,
    required this.category,
    required this.description,
    required this.date,
    this.status = 'Mới gửi',
  });

  final String title;
  final String category;
  final String description;
  final String date;

  /// Mới gửi / Đang xử lý / Đã xử lý / Đã xác nhận.
  String status;
}

class TenantIncidentsPage extends StatefulWidget {
  const TenantIncidentsPage({super.key});

  @override
  State<TenantIncidentsPage> createState() => _TenantIncidentsPageState();
}

class _TenantIncidentsPageState extends State<TenantIncidentsPage> {
  static const _categories = ['Điện', 'Nước', 'Điện lạnh', 'Internet', 'Khác'];

  final _incidents = <TenantIncident>[
    TenantIncident(
      title: 'Máy lạnh không lạnh',
      category: 'Điện lạnh',
      description: 'Máy lạnh chạy nhưng không ra hơi lạnh từ tối qua.',
      date: '04/10/2026',
    ),
    TenantIncident(
      title: 'Bóng đèn nhà tắm hỏng',
      category: 'Điện',
      description: 'Bóng đèn không sáng.',
      date: '20/09/2026',
      status: 'Đã xử lý',
    ),
  ];

  Color _statusColor(String status) => switch (status) {
    'Mới gửi' => const Color(0xFFD64545),
    'Đang xử lý' => const Color(0xFFE08A1E),
    'Đã xử lý' => tenantGreen,
    _ => tenantMuted,
  };

  @override
  Widget build(BuildContext context) {
    return TenantPageFrame(
      children: [
        const TenantPageTitle(
          title: 'Báo sự cố',
          subtitle: 'Gửi yêu cầu sửa chữa cho chủ trọ phòng A.302.',
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openCreateSheet,
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
                      incident.status,
                      color: _statusColor(incident.status),
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
                if (incident.status == 'Đã xử lý') ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _changeStatus(incident, 'Mới gửi'),
                        child: const Text('Mở lại'),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: () =>
                            _changeStatus(incident, 'Đã xác nhận'),
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

  void _changeStatus(TenantIncident incident, String status) {
    setState(() => incident.status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật: $status')),
    );
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

    final now = DateTime.now();
    setState(() {
      _incidents.insert(
        0,
        TenantIncident(
          title: title,
          category: category,
          description: description,
          date: '${now.day}/${now.month}/${now.year}',
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi yêu cầu cho chủ trọ.')),
    );
  }
}
