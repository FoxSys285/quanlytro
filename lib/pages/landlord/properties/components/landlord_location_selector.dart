import 'package:flutter/material.dart';

import '../../../tenant/discovery/models/tenant_area_selection.dart';
import '../../../tenant/discovery/services/tenant_administrative_service.dart';

class LandlordLocationSelector extends StatefulWidget {
  const LandlordLocationSelector({
    super.key,
    required this.initialCity,
    required this.initialWard,
    required this.onChanged,
    this.service,
  });

  final String initialCity;
  final String initialWard;
  final void Function(String city, String ward) onChanged;
  final TenantAdministrativeService? service;

  @override
  State<LandlordLocationSelector> createState() =>
      _LandlordLocationSelectorState();
}

class _LandlordLocationSelectorState extends State<LandlordLocationSelector> {
  TenantAdministrativeService get _service =>
      widget.service ?? TenantAdministrativeService.instance;

  List<TenantAdministrativeUnit> _provinces = const [];
  List<TenantAdministrativeUnit> _wards = const [];
  String? _city;
  String? _ward;
  String? _provinceError;
  String? _wardError;
  bool _loadingProvinces = false;
  bool _loadingWards = false;
  int _wardRequest = 0;

  @override
  void initState() {
    super.initState();
    _city = widget.initialCity.trim().isEmpty
        ? null
        : widget.initialCity.trim();
    _ward = widget.initialWard.trim().isEmpty
        ? null
        : widget.initialWard.trim();
    _loadProvinces();
  }

  String? get _selectedCity =>
      _provinces.any((unit) => unit.name == _city) ? _city : null;
  String? get _selectedWard =>
      _wards.any((unit) => unit.name == _ward) ? _ward : null;

  Future<void> _loadProvinces() async {
    if (!mounted) return;
    setState(() {
      _loadingProvinces = true;
      _provinceError = null;
    });
    try {
      final provinces = await _service.provinces();
      if (!mounted) return;
      final selected = provinces
          .where((unit) => _city != null && sameLocationName(unit.name, _city!))
          .firstOrNull;
      setState(() {
        _provinces = provinces;
        if (selected != null) _city = selected.name;
      });
      if (selected != null) {
        widget.onChanged(selected.name, _ward ?? '');
        await _loadWards(selected, preserveCurrent: true);
      }
    } on TenantAdministrativeFailure catch (error) {
      if (mounted) setState(() => _provinceError = error.message);
    } finally {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadWards(
    TenantAdministrativeUnit province, {
    bool preserveCurrent = false,
  }) async {
    final request = ++_wardRequest;
    setState(() {
      _loadingWards = true;
      _wardError = null;
      _wards = const [];
    });
    try {
      final wards = await _service.wards(province.code);
      if (!mounted || request != _wardRequest) return;
      final selected = wards
          .where(
            (unit) =>
                preserveCurrent &&
                _ward != null &&
                sameLocationName(unit.name, _ward!),
          )
          .firstOrNull;
      setState(() {
        _wards = wards;
        _ward = selected?.name;
      });
      widget.onChanged(_city ?? '', _ward ?? '');
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

  void _selectCity(String? name) {
    if (name == null) return;
    final province = _provinces.firstWhere((unit) => unit.name == name);
    setState(() {
      _city = name;
      _ward = null;
      _wards = const [];
    });
    widget.onChanged(name, '');
    _loadWards(province);
  }

  void _selectWard(String? name) {
    if (name == null) return;
    setState(() => _ward = name);
    widget.onChanged(_city ?? '', name);
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _retryIcon({required bool provinces}) => IconButton(
    tooltip: 'Tải lại danh sách',
    onPressed: provinces
        ? _loadProvinces
        : () {
            final province = _provinces
                .where((unit) => unit.name == _city)
                .firstOrNull;
            if (province != null) _loadWards(province);
          },
    icon: const Icon(Icons.refresh_rounded),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<String>(
        initialValue: _selectedCity,
        isExpanded: true,
        decoration: _decoration(
          'Tỉnh / Thành phố',
          Icons.location_city_outlined,
          suffix: _loadingProvinces
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _provinceError == null
              ? null
              : _retryIcon(provinces: true),
        ),
        items: [
          for (final unit in _provinces)
            DropdownMenuItem(value: unit.name, child: Text(unit.name)),
        ],
        onChanged: _loadingProvinces ? null : _selectCity,
        validator: (_) => _selectedCity == null
            ? 'Chọn tỉnh / thành phố từ danh sách.'
            : null,
      ),
      if (_provinceError != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            _provinceError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        initialValue: _selectedWard,
        isExpanded: true,
        decoration: _decoration(
          'Xã / Phường',
          Icons.location_on_outlined,
          suffix: _loadingWards
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _wardError == null
              ? null
              : _retryIcon(provinces: false),
        ),
        items: [
          for (final unit in _wards)
            DropdownMenuItem(value: unit.name, child: Text(unit.name)),
        ],
        onChanged: _selectedCity == null || _loadingWards ? null : _selectWard,
        validator: (_) =>
            _selectedWard == null ? 'Chọn xã / phường từ danh sách.' : null,
      ),
      if (_wardError != null)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            _wardError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
    ],
  );
}
