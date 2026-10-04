import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import 'models/landlord_meter_reading.dart';

class LandlordMeterReadingsPage extends StatefulWidget {
  const LandlordMeterReadingsPage({super.key});

  @override
  State<LandlordMeterReadingsPage> createState() =>
      _LandlordMeterReadingsPageState();
}

class _LandlordMeterReadingsPageState extends State<LandlordMeterReadingsPage> {
  static const _electricPrice = 3500;
  static const _waterPrice = 15000;

  String _period = 'Tháng 10/2026';

  final _readings = <LandlordMeterReading>[
    LandlordMeterReading(
      room: 'A.101',
      oldElectric: 1250,
      oldWater: 320,
      newElectric: 1362,
      newWater: 328,
    ),
    LandlordMeterReading(room: 'A.102', oldElectric: 980, oldWater: 210),
    LandlordMeterReading(
      room: 'A.302',
      oldElectric: 2104,
      oldWater: 455,
      newElectric: 2230,
      newWater: 462,
    ),
    LandlordMeterReading(room: 'B.105', oldElectric: 640, oldWater: 150),
    LandlordMeterReading(room: 'B.201', oldElectric: 1530, oldWater: 298),
  ];

  @override
  Widget build(BuildContext context) {
    final doneCount = _readings.where((r) => r.isDone).length;

    return LandlordPageFrame(
      children: [
        const LandlordPageTitle(
          title: 'Chỉ số điện nước',
          subtitle: 'Nhập chỉ số cuối kỳ cho từng phòng.',
        ),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _period,
                decoration: const InputDecoration(
                  labelText: 'Kỳ ghi chỉ số',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Tháng 10/2026',
                    child: Text('Tháng 10/2026'),
                  ),
                  DropdownMenuItem(
                    value: 'Tháng 9/2026',
                    child: Text('Tháng 9/2026'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _period = value ?? _period),
              ),
            ),
            const SizedBox(width: 12),
            LandlordStatusPill(
              'Đã nhập $doneCount/${_readings.length}',
              color: doneCount == _readings.length
                  ? const Color(0xFF16836F)
                  : const Color(0xFFE08A1E),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final reading in _readings) _buildReadingCard(reading),
      ],
    );
  }

  Widget _buildReadingCard(LandlordMeterReading reading) {
    return LandlordCard(
      onTap: () => _openInput(reading),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Phòng ${reading.room}',
                style: const TextStyle(
                  color: landlordInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              reading.isDone
                  ? const LandlordStatusPill(
                      'Đã nhập',
                      color: Color(0xFF16836F),
                    )
                  : const LandlordStatusPill(
                      'Chưa nhập',
                      color: Color(0xFFE08A1E),
                    ),
            ],
          ),
          const SizedBox(height: 10),
          _meterRow(
            icon: Icons.bolt_outlined,
            label: 'Điện',
            oldValue: reading.oldElectric,
            newValue: reading.newElectric,
            usage: reading.electricUsage,
            unit: 'kWh',
            price: _electricPrice,
          ),
          const SizedBox(height: 6),
          _meterRow(
            icon: Icons.water_drop_outlined,
            label: 'Nước',
            oldValue: reading.oldWater,
            newValue: reading.newWater,
            usage: reading.waterUsage,
            unit: 'm³',
            price: _waterPrice,
          ),
        ],
      ),
    );
  }

  Widget _meterRow({
    required IconData icon,
    required String label,
    required int oldValue,
    required int? newValue,
    required int usage,
    required String unit,
    required int price,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: landlordBlue),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $oldValue → ${newValue ?? '...'}',
            style: const TextStyle(color: landlordInk, fontSize: 13),
          ),
        ),
        Text(
          newValue == null
              ? '--'
              : '$usage $unit · ${formatLandlordMoney(usage * price)}',
          style: const TextStyle(color: landlordMuted, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _openInput(LandlordMeterReading reading) async {
    final electricController = TextEditingController(
      text: reading.newElectric?.toString() ?? '',
    );
    final waterController = TextEditingController(
      text: reading.newWater?.toString() ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nhập chỉ số phòng ${reading.room}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: electricController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Chỉ số điện mới',
                helperText: 'Chỉ số cũ: ${reading.oldElectric}',
              ),
            ),
            TextField(
              controller: waterController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Chỉ số nước mới',
                helperText: 'Chỉ số cũ: ${reading.oldWater}',
              ),
            ),
          ],
        ),
        actions: [
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
    );

    if (saved != true || !mounted) return;

    final electric = int.tryParse(electricController.text.trim());
    final water = int.tryParse(waterController.text.trim());
    if (electric == null || water == null) {
      showLandlordMessage(context, 'Vui lòng nhập số hợp lệ.');
      return;
    }
    // Chỉ số mới không được nhỏ hơn chỉ số cũ.
    if (electric < reading.oldElectric || water < reading.oldWater) {
      showLandlordMessage(context, 'Chỉ số mới không được nhỏ hơn chỉ số cũ.');
      return;
    }

    setState(() {
      reading
        ..newElectric = electric
        ..newWater = water;
    });
    showLandlordMessage(context, 'Đã lưu chỉ số phòng ${reading.room}.');
  }
}
