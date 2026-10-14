import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import 'models/landlord_service.dart';

class LandlordServicesPage extends StatefulWidget {
  const LandlordServicesPage({super.key});

  @override
  State<LandlordServicesPage> createState() => _LandlordServicesPageState();
}

class _LandlordServicesPageState extends State<LandlordServicesPage> {
  static const _bases = ['Theo chỉ số', 'Theo phòng', 'Theo người', 'Cố định'];

  final _store = LandlordDemoStore.instance;
  List<LandlordService> get _services => _store.services;
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
    return LandlordPageFrame(
      children: [
        LandlordPageTitle(
          title: 'Dịch vụ và bảng giá',
          subtitle: 'Bảng giá cho tin đăng và hợp đồng mới. Hợp đồng hiện tại giữ đơn giá đã thỏa thuận.',
          trailing: FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm'),
          ),
        ),
        if (_services.isEmpty)
          const LandlordEmptyState(message: 'Chưa có dịch vụ nào.'),
        for (final service in _services)
          LandlordCard(
            onTap: () => _openForm(service: service),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: landlordBlue.withValues(alpha: 0.1),
                  child: Icon(_iconFor(service.name), color: landlordBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          color: landlordInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatLandlordMoney(service.price)} / ${service.unit} · ${service.basis}',
                        style: const TextStyle(
                          color: landlordMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: service.active,
                  onChanged: (value) => _store.setServiceActive(service, value),
                ),
              ],
            ),
          ),
      ],
    );
  }

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('điện')) return Icons.bolt_outlined;
    if (lower.contains('nước')) return Icons.water_drop_outlined;
    if (lower.contains('internet') || lower.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (lower.contains('xe')) return Icons.two_wheeler_outlined;
    return Icons.room_service_outlined;
  }

  Future<void> _openForm({LandlordService? service}) async {
    final nameController = TextEditingController(text: service?.name ?? '');
    final unitController = TextEditingController(text: service?.unit ?? '');
    final priceController = TextEditingController(
      text: service == null ? '' : service.price.toString(),
    );
    var basis = service?.basis ?? _bases.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(service == null ? 'Thêm dịch vụ' : 'Sửa dịch vụ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên dịch vụ'),
                ),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Đơn vị (kWh, m³, phòng...)',
                  ),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Đơn giá (đ)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: basis,
                  decoration: const InputDecoration(labelText: 'Cách tính'),
                  items: [
                    for (final item in _bases)
                      DropdownMenuItem(value: item, child: Text(item)),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => basis = value ?? basis),
                ),
              ],
            ),
          ),
          actions: [
            if (service != null)
              TextButton(
                onPressed: () {
                  _store.deleteService(service);
                  Navigator.pop(context, false);
                },
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final name = nameController.text.trim();
    final unit = unitController.text.trim();
    final price = int.tryParse(priceController.text.trim());
    if (name.isEmpty || unit.isEmpty || price == null || price < 0) {
      showLandlordMessage(context, 'Vui lòng nhập đầy đủ và đúng đơn giá.');
      return;
    }

    _store.saveService(
      existing: service,
      name: name,
      unit: unit,
      basis: basis,
      price: price,
    );
    showLandlordMessage(context, 'Đã lưu dịch vụ $name.');
  }
}
