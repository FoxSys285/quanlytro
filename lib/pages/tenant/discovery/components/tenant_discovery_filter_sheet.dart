import 'package:flutter/material.dart';

import '../../tenant_ui.dart';
import '../models/tenant_room_listing.dart';
import '../services/tenant_administrative_service.dart';
import '../services/tenant_location_service.dart';
import 'tenant_area_picker_page.dart';

class TenantDiscoveryFilterSelection {
  const TenantDiscoveryFilterSelection({
    required this.maxRent,
    required this.city,
    required this.ward,
    required this.electricityRange,
    required this.waterType,
    required this.area,
    this.minArea,
    this.maxArea,
    this.amenities = const {},
  });

  final int maxRent;
  final String? city;
  final String? ward;
  final RangeValues electricityRange;
  final String waterType;
  final String? area;
  final double? minArea;
  final double? maxArea;
  final Set<String> amenities;
}

class TenantDiscoveryFilterSheet extends StatefulWidget {
  const TenantDiscoveryFilterSheet({
    super.key,
    required this.initialRent,
    required this.initialCity,
    required this.initialWard,
    required this.initialElectricityRange,
    required this.initialWaterType,
    required this.initialArea,
    this.initialMinArea,
    this.initialMaxArea,
    this.initialAmenities = const {},
    this.locationService = const TenantLocationService(),
    this.availableRooms = const [],
    this.administrativeService,
  });

  final int initialRent;
  final String? initialCity;
  final String? initialWard;
  final RangeValues initialElectricityRange;
  final String initialWaterType;
  final String? initialArea;
  final double? initialMinArea;
  final double? initialMaxArea;
  final Set<String> initialAmenities;
  final TenantLocationService locationService;
  final List<TenantRoomListing> availableRooms;
  final TenantAdministrativeService? administrativeService;

  @override
  State<TenantDiscoveryFilterSheet> createState() =>
      TenantDiscoveryFilterSheetState();
}

class TenantDiscoveryFilterSheetState
    extends State<TenantDiscoveryFilterSheet> {
  late final _administrativeService =
      widget.administrativeService ?? TenantAdministrativeService.instance;
  List<TenantAdministrativeUnit> _provinces = const [];
  List<String> _wards = const [];
  bool _loadingProvinces = false;
  bool _loadingWards = false;
  String? _provinceError;
  String? _wardError;
  int _wardRequest = 0;

  late int _maxRent = widget.initialRent;
  late String? _city = widget.initialCity;
  late String? _ward = widget.initialWard;
  late RangeValues _electricityRange = widget.initialElectricityRange;
  late String _waterType = widget.initialWaterType;
  late String? _area = widget.initialArea;
  late final _minAreaController = TextEditingController(
    text: widget.initialMinArea?.toString() ?? '',
  );
  late final _maxAreaController = TextEditingController(
    text: widget.initialMaxArea?.toString() ?? '',
  );
  late final Set<String> _amenities = {...widget.initialAmenities};
  String? _areaError;
  bool _locating = false;
  int _locationRequest = 0;
  String? _locationError;
  double? _parseArea(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));
  List<String> get _amenityOptions => ({
    ...TenantRoomDemoData.allListings
        .expand((room) => room.tags)
        .where((tag) => !tag.startsWith('Tầng ')),
    ..._amenities,
  }.toList()..sort());
  late final _rentController = TextEditingController(
    text: _formatRent(widget.initialRent),
  );

  List<String> get _cities => _provinces.map((unit) => unit.name).toList();

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _loadingProvinces = true;
      _provinceError = null;
    });
    try {
      final provinces = await _administrativeService.provinces();
      if (!mounted) return;
      setState(() => _provinces = provinces);
      _loadWards();
    } on TenantAdministrativeFailure catch (error) {
      if (mounted) setState(() => _provinceError = error.message);
    } finally {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadWards() async {
    final request = ++_wardRequest;
    final province = _provinces
        .where((unit) => _city != null && sameLocationName(unit.name, _city!))
        .firstOrNull;
    setState(() {
      _wards = const [];
      _wardError = null;
      _loadingWards = province != null;
    });
    if (province == null) return;
    try {
      final wards = await _administrativeService.wards(province.code);
      if (mounted && request == _wardRequest) {
        setState(() => _wards = wards.map((unit) => unit.name).toList());
      }
    } on TenantAdministrativeFailure catch (error) {
      if (mounted && request == _wardRequest) {
        setState(() => _wardError = error.message);
      }
    } finally {
      if (mounted && request == _wardRequest) {
        setState(() => _loadingWards = false);
      }
    }
  }

  @override
  void dispose() {
    _minAreaController.dispose();
    _maxAreaController.dispose();
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
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: _pickOnMap,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Chọn trên bản đồ'),
              ),
              TextButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: Text(_locating ? 'Đang lấy vị trí…' : 'Vị trí hiện tại'),
              ),
            ],
          ),
          _LocationInput(
            label: 'Tỉnh / Thành phố',
            hint: 'Nhập hoặc chọn tỉnh / thành phố',
            icon: Icons.location_city_outlined,
            value: _city,
            options: _cities,
            loading: _loadingProvinces,
            onChanged: (value) {
              setState(() {
                _locationRequest++;
                _locating = false;
                _city = value;
                _ward = null;
              });
              _loadWards();
            },
          ),
          if (_provinceError != null)
            _loadError(_provinceError!, _loadProvinces),
          const SizedBox(height: 10),
          _LocationInput(
            label: 'Xã / Phường',
            hint: _city == null
                ? 'Chọn tỉnh / thành phố trước'
                : 'Nhập hoặc chọn xã / phường',
            icon: Icons.place_outlined,
            value: _ward,
            options: _wards,
            loading: _loadingWards,
            onChanged: _city == null
                ? null
                : (value) => setState(() {
                    _locationRequest++;
                    _locating = false;
                    _ward = value;
                  }),
          ),
          if (_wardError != null) _loadError(_wardError!, _loadWards),
          if (_locationError != null)
            Text(
              _locationError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          const SizedBox(height: 18),
          const TenantSectionHeading('Diện tích phòng'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('min-area'),
                  controller: _minAreaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Từ (m²)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const ValueKey('max-area'),
                  controller: _maxAreaController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Đến (m²)'),
                ),
              ),
            ],
          ),
          if (_areaError != null)
            Text(_areaError!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
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
          const TenantSectionHeading('Tiện ích'),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final amenity in _amenityOptions)
                FilterChip(
                  label: Text(amenity),
                  selected: _amenities.contains(amenity),
                  onSelected: (selected) => setState(() {
                    selected
                        ? _amenities.add(amenity)
                        : _amenities.remove(amenity);
                  }),
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
            onPressed: _apply,
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

  void _apply() {
    final min = _parseArea(_minAreaController.text);
    final max = _parseArea(_maxAreaController.text);
    if ((_minAreaController.text.trim().isNotEmpty &&
            (min == null || !min.isFinite || min < 0)) ||
        (_maxAreaController.text.trim().isNotEmpty &&
            (max == null || !max.isFinite || max < 0)) ||
        (min != null && max != null && min > max)) {
      setState(
        () => _areaError = 'Nhập diện tích hợp lệ; từ không vượt quá đến.',
      );
      return;
    }
    Navigator.of(context).pop(
      TenantDiscoveryFilterSelection(
        maxRent: _maxRent,
        city: _city,
        ward: _ward,
        electricityRange: _electricityRange,
        waterType: _waterType,
        area: _area,
        minArea: min,
        maxArea: max,
        amenities: _amenities,
      ),
    );
  }

  Future<void> _pickOnMap() async {
    setState(() {
      _locationRequest++;
      _locating = false;
    });
    final selection = await Navigator.of(context).push<TenantAreaSelection>(
      MaterialPageRoute(
        builder: (_) =>
            TenantAreaPickerPage(locationService: widget.locationService),
      ),
    );
    if (!mounted || selection == null) return;
    _setLocation(selection);
  }

  void _setLocation(TenantAreaSelection selection) {
    setState(() {
      _city = selection.city;
      _ward = selection.ward;
      _locationError = null;
    });
    _loadWards();
  }

  Future<void> _useCurrentLocation() async {
    final request = ++_locationRequest;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final selection = await widget.locationService.currentArea();
      if (mounted && request == _locationRequest) _setLocation(selection);
    } on TenantLocationFailure catch (error) {
      if (mounted && request == _locationRequest) {
        setState(() => _locationError = error.message);
      }
    } catch (_) {
      if (mounted && request == _locationRequest) {
        setState(
          () => _locationError = 'Không lấy được vị trí. Bạn có thể nhập khu vực hoặc chọn trên bản đồ.',
        );
      }
    } finally {
      if (mounted && request == _locationRequest) {
        setState(() => _locating = false);
      }
    }
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
      _locationRequest++;
      _locating = false;
      _locationError = null;
      _maxRent = 20000000;
      _city = null;
      _ward = null;
      _electricityRange = const RangeValues(0, 5);
      _waterType = 'Tất cả';
      _area = null;
      _minAreaController.clear();
      _maxAreaController.clear();
      _amenities.clear();
      _areaError = null;
      _rentController.text = _formatRent(20000000);
    });
    _loadWards();
  }

  Widget _loadError(String message, VoidCallback retry) => Row(
    children: [
      Expanded(
        child: Text(
          message,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
      TextButton(onPressed: retry, child: const Text('Thử lại')),
    ],
  );

  String _formatRent(int amount) =>
      formatTenantMoney(amount).replaceFirst(' đ', '');
}

class _LocationInput extends StatefulWidget {
  const _LocationInput({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
    this.loading = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String?>? onChanged;
  final bool loading;

  @override
  State<_LocationInput> createState() => _LocationInputState();
}

class _LocationInputState extends State<_LocationInput> {
  late final _controller = TextEditingController(text: widget.value ?? '');
  final _focus = FocusNode();

  @override
  void didUpdateWidget(covariant _LocationInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text.trim() != (widget.value ?? '')) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    key: ValueKey('location-input-${widget.label}'),
    controller: _controller,
    focusNode: _focus,
    enabled: widget.onChanged != null,
    onChanged: (value) =>
        widget.onChanged?.call(value.trim().isEmpty ? null : value.trim()),
    style: const TextStyle(fontSize: 12),
    decoration: InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      prefixIcon: Icon(widget.icon, size: 19),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.value != null)
            IconButton(
              tooltip: 'Xóa ${widget.label.toLowerCase()}',
              onPressed: widget.onChanged == null
                  ? null
                  : () {
                      _controller.clear();
                      widget.onChanged?.call(null);
                    },
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Chọn ${widget.label.toLowerCase()}',
              onPressed: widget.onChanged == null || widget.options.isEmpty
                  ? null
                  : _pickOption,
              icon: const Icon(Icons.expand_more_rounded),
            ),
        ],
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
    ),
  );

  Future<void> _pickOption() async {
    _focus.unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LocationOptions(
        label: widget.label,
        options: widget.options,
        selected: widget.value,
      ),
    );
    if (mounted && selected != null) widget.onChanged?.call(selected);
  }
}

class _LocationOptions extends StatefulWidget {
  const _LocationOptions({
    required this.label,
    required this.options,
    required this.selected,
  });

  final String label;
  final List<String> options;
  final String? selected;

  @override
  State<_LocationOptions> createState() => _LocationOptionsState();
}

class _LocationOptionsState extends State<_LocationOptions> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final options = widget.options
        .where(
          (option) =>
              option.toLowerCase().contains(_query.toLowerCase()) ||
              sameLocationName(option, _query),
        )
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn ${widget.label.toLowerCase()}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Tìm trong danh sách',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: options.isEmpty
                    ? const Center(child: Text('Không tìm thấy kết quả'))
                    : ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return ListTile(
                            title: Text(option),
                            selected:
                                widget.selected != null &&
                                sameLocationName(option, widget.selected!),
                            onTap: () => Navigator.of(context).pop(option),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
