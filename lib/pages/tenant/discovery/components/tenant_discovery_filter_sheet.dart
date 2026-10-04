import 'package:flutter/material.dart';

import '../../tenant_ui.dart';

class TenantDiscoveryFilterSelection {
  const TenantDiscoveryFilterSelection({
    required this.maxRent,
    required this.city,
    required this.ward,
    required this.electricityRange,
    required this.waterType,
    required this.area,
  });

  final int maxRent;
  final String? city;
  final String? ward;
  final RangeValues electricityRange;
  final String waterType;
  final String? area;
}

class TenantDiscoveryFilterSheet extends StatefulWidget {
  const TenantDiscoveryFilterSheet({
    required this.initialRent,
    required this.initialCity,
    required this.initialWard,
    required this.initialElectricityRange,
    required this.initialWaterType,
    required this.initialArea,
  });

  final int initialRent;
  final String? initialCity;
  final String? initialWard;
  final RangeValues initialElectricityRange;
  final String initialWaterType;
  final String? initialArea;

  @override
  State<TenantDiscoveryFilterSheet> createState() =>
      TenantDiscoveryFilterSheetState();
}

class TenantDiscoveryFilterSheetState
    extends State<TenantDiscoveryFilterSheet> {
  static const _cities = ['TP. Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng'];
  static const _wardsByCity = <String, List<String>>{
    'TP. Hồ Chí Minh': [
      'Phường 25',
      'Phường 26',
      'Phường 17',
      'Phường 2',
      'Phường 13',
      'Phường Thảo Điền',
      'Phường 8',
      'Phường 4',
    ],
    'Hà Nội': ['Phường Cầu Giấy', 'Phường Dịch Vọng', 'Phường Mỹ Đình'],
    'Đà Nẵng': ['Phường Hải Châu', 'Phường Mỹ An', 'Phường An Hải'],
  };

  late int _maxRent = widget.initialRent;
  late String? _city = widget.initialCity;
  late String? _ward = widget.initialWard;
  late RangeValues _electricityRange = widget.initialElectricityRange;
  late String _waterType = widget.initialWaterType;
  late String? _area = widget.initialArea;
  late final _rentController = TextEditingController(
    text: _formatRent(widget.initialRent),
  );

  List<String> get _wards => _wardsByCity[_city] ?? const [];

  @override
  void dispose() {
    _rentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TenantBottomSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TenantSheetHandle(),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lọc',
                  style: TextStyle(
                    color: tenantInk,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: _reset,
                child: const Text(
                  'Đặt lại',
                  style: TextStyle(color: tenantGreenDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const TenantSectionHeading('Tiền trọ mỗi tháng'),
          TextField(
            controller: _rentController,
            keyboardType: TextInputType.number,
            onChanged: _onRentTextChanged,
            onEditingComplete: _normalizeRentInput,
            decoration: InputDecoration(
              labelText: 'Mức tiền tối đa',
              suffixText: 'đ / tháng',
              prefixIcon: const Icon(Icons.payments_outlined, size: 19),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: tenantLine),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: tenantLine),
              ),
            ),
          ),
          Slider(
            value: _maxRent.toDouble().clamp(0.0, 20000000.0).toDouble(),
            min: 0,
            max: 20000000,
            divisions: 100,
            activeColor: tenantGreen,
            label: '${(_maxRent / 1000000).toStringAsFixed(1)} triệu',
            onChanged: _onRentSliderChanged,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 đ', style: TextStyle(color: tenantMuted, fontSize: 10)),
                Text(
                  '20 triệu đ',
                  style: TextStyle(color: tenantMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const TenantSectionHeading('Tỉnh / Thành phố và Xã / Phường'),
          _FilterDropdown(
            label: 'Tỉnh / Thành phố',
            hint: 'Chọn tỉnh / thành phố',
            icon: Icons.location_city_outlined,
            value: _city,
            options: _cities,
            onChanged: (value) {
              setState(() {
                _city = value;
                _ward = null;
              });
            },
          ),
          const SizedBox(height: 10),
          _FilterDropdown(
            label: 'Xã / Phường',
            hint: _city == null
                ? 'Chọn tỉnh / thành phố trước'
                : 'Chọn xã / phường',
            icon: Icons.place_outlined,
            value: _ward,
            options: _wards,
            onChanged: _city == null
                ? null
                : (value) => setState(() => _ward = value),
          ),
          if (widget.initialCity != null && widget.initialWard != null) ...[
            const SizedBox(height: 7),
            const Row(
              children: [
                Icon(Icons.my_location_rounded, size: 14, color: tenantGreen),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Đã điền theo vị trí hiện tại của bạn',
                    style: TextStyle(color: tenantGreenDark, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          const TenantSectionHeading('Diện tích phòng'),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final area in const [
                'Dưới 20 m²',
                '20–30 m²',
                '30–40 m²',
                '40–50 m²',
                'Trên 50 m²',
              ])
                ChoiceChip(
                  label: Text(area),
                  selected: _area == area,
                  onSelected: (selected) =>
                      setState(() => _area = selected ? area : null),
                  selectedColor: tenantGreen.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: _area == area ? tenantGreen : tenantLine,
                  ),
                  labelStyle: TextStyle(
                    color: _area == area ? tenantGreenDark : tenantMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 18),
          TenantSectionHeading(
            'Tiền điện',
            trailing: Text(
              '${(_electricityRange.start * 1000).round()} – ${(_electricityRange.end * 1000).round()} đ/kWh',
              style: const TextStyle(color: tenantGreenDark, fontSize: 10),
            ),
          ),
          RangeSlider(
            values: _electricityRange,
            min: 0,
            max: 5,
            divisions: 10,
            activeColor: tenantGreen,
            labels: RangeLabels(
              '${(_electricityRange.start * 1000).round()} đ',
              '${(_electricityRange.end * 1000).round()} đ',
            ),
            onChanged: (value) => setState(() => _electricityRange = value),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0 đ/kWh',
                  style: TextStyle(color: tenantMuted, fontSize: 10),
                ),
                Text(
                  '5.000 đ/kWh',
                  style: TextStyle(color: tenantMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          const TenantSectionHeading('Tiền nước'),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final type in ['Tất cả', 'Theo tháng', 'Theo m³'])
                ChoiceChip(
                  label: Text(type),
                  selected: _waterType == type,
                  onSelected: (_) => setState(() => _waterType = type),
                  selectedColor: tenantGreen.withValues(alpha: 0.12),
                  side: BorderSide(
                    color: _waterType == type ? tenantGreen : tenantLine,
                  ),
                  labelStyle: TextStyle(
                    color: _waterType == type ? tenantGreenDark : tenantMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TenantSurface(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  _waterType == 'Theo m³'
                      ? Icons.water_drop_outlined
                      : Icons.calendar_month_outlined,
                  color: const Color(0xFF4784C7),
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _waterType == 'Theo tháng'
                        ? 'Phí cố định mỗi tháng · ví dụ 100.000 đ/tháng'
                        : _waterType == 'Theo m³'
                        ? 'Tính theo lượng sử dụng · ví dụ 3.000 đ/m³'
                        : 'Chọn cách tính theo tháng hoặc theo khối nước (m³)',
                    style: const TextStyle(
                      color: tenantMuted,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 21),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              TenantDiscoveryFilterSelection(
                maxRent: _maxRent,
                city: _city,
                ward: _ward,
                electricityRange: _electricityRange,
                waterType: _waterType,
                area: _area,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: tenantGreen,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text('Áp dụng bộ lọc'),
          ),
          SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
        ],
      ),
    );
  }

  void _onRentTextChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(digits);
    if (parsed == null) return;
    setState(() => _maxRent = parsed.clamp(0, 20000000).toInt());
  }

  void _onRentSliderChanged(double value) {
    final amount = value.round();
    setState(() => _maxRent = amount);
    _rentController.text = _formatRent(amount);
  }

  void _normalizeRentInput() {
    final digits = _rentController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = int.tryParse(digits);
    if (parsed != null) {
      final amount = parsed.clamp(0, 20000000).toInt();
      setState(() => _maxRent = amount);
      _rentController.text = _formatRent(amount);
    }
    FocusScope.of(context).unfocus();
  }

  void _reset() {
    setState(() {
      _maxRent = 20000000;
      _city = null;
      _ward = null;
      _electricityRange = const RangeValues(0, 5);
      _waterType = 'Tất cả';
      _area = null;
      _rentController.text = _formatRent(20000000);
    });
  }

  String _formatRent(int amount) =>
      formatTenantMoney(amount).replaceFirst(' đ', '');
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: tenantLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: tenantLine),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
