import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../tenant_ui.dart';
import '../../tenant_detail_ui.dart';
import '../models/tenant_area_selection.dart';
import '../services/tenant_location_service.dart';

export '../models/tenant_area_selection.dart';

class TenantAreaPickerPage extends StatefulWidget {
  const TenantAreaPickerPage({
    super.key,
    this.embedded = false,
    this.onSelected,
    this.initialPosition,
    this.locationService = const TenantLocationService(),
  });

  final bool embedded;
  final ValueChanged<TenantAreaSelection>? onSelected;
  final LatLng? initialPosition;
  final TenantLocationService locationService;

  @override
  State<TenantAreaPickerPage> createState() => _TenantAreaPickerPageState();
}

class _TenantAreaPickerPageState extends State<TenantAreaPickerPage> {
  static const _fallbackPosition = LatLng(13.0957, 109.3207);
  static const _selectedMarkerId = MarkerId('selected-area');
  GoogleMapController? _mapController;
  LatLng _selectedPosition = _fallbackPosition;
  TenantAreaSelection? _selection;
  String? _locationMessage;
  bool _locating = false;
  bool _resolvingAddress = false;
  bool _hasPosition = false;
  int _addressRequest = 0;
  int _locationRequest = 0;

  bool get _supportsGoogleMaps =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPosition;
    if (initial != null) {
      _selectedPosition = initial;
      _hasPosition = true;
      _resolveAddress(initial);
    } else {
      _locateCurrentPosition();
    }
  }

  @override
  void dispose() {
    _locationRequest++;
    _addressRequest++;
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = Column(
      children: [
        Expanded(child: _map()),
        _selectionPanel(),
      ],
    );
    if (widget.embedded) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(color: Colors.white, child: map),
      );
    }
    return TenantSubpageScaffold(title: 'Chọn vị trí', child: map);
  }

  Widget _map() => Stack(
    fit: StackFit.expand,
    children: [
      if (_supportsGoogleMaps)
        GoogleMap(
          key: const ValueKey('area-selection-map'),
          initialCameraPosition: CameraPosition(
            target: _selectedPosition,
            zoom: 14,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            if (_hasPosition) unawaited(_moveCamera(_selectedPosition));
          },
          onTap: _selectPoint,
          onLongPress: _selectPoint,
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          markers: {
            if (_hasPosition)
              Marker(
                markerId: _selectedMarkerId,
                position: _selectedPosition,
                infoWindow: const InfoWindow(title: 'Điểm đã chọn'),
                draggable: true,
                onDragEnd: _selectPoint,
              ),
          },
          compassEnabled: true,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        )
      else
        const ColoredBox(
          color: Color(0xFFEAF2EC),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Bản đồ Google khả dụng trên Android và iOS.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      const Positioned(
        left: 10,
        top: 10,
        right: 60,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                'Nhấn giữ bản đồ để chọn vị trí',
                style: TextStyle(color: tenantInk, fontSize: 11),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          child: IconButton(
            tooltip: 'Lấy vị trí hiện tại',
            onPressed: _locating ? null : _locateCurrentPosition,
            icon: _locating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, color: tenantGreen),
          ),
        ),
      ),
      if (widget.embedded)
        Positioned(
          bottom: 8,
          right: 8,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: IconButton(
              key: const ValueKey('current-location-map-preview'),
              tooltip: 'Mở bản đồ lớn',
              onPressed: _openMap,
              icon: const Icon(Icons.open_in_full_rounded, color: tenantGreen),
            ),
          ),
        ),
    ],
  );

  Widget _selectionPanel() {
    final selection = _selection;
    return SafeArea(
      top: false,
      bottom: !widget.embedded,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _locating
                  ? 'Đang xác định vị trí…'
                  : _resolvingAddress
                  ? 'Đang xác định tỉnh/thành, xã/phường…'
                  : 'Khu vực đã chọn',
              style: const TextStyle(
                color: tenantInk,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_hasPosition) ...[
              const SizedBox(height: 3),
              Text(
                '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}',
                style: const TextStyle(color: tenantMuted, fontSize: 10),
              ),
            ],
            const SizedBox(height: 5),
            Text(
              'Tỉnh / Thành phố: ${selection?.city ?? 'Chưa xác định'}',
              key: const ValueKey('map-selected-city'),
              style: const TextStyle(color: tenantInk, fontSize: 12),
            ),
            const SizedBox(height: 3),
            Text(
              'Xã / Phường: ${selection?.ward ?? 'Chưa xác định — tìm theo tỉnh/thành'}',
              key: const ValueKey('map-selected-ward'),
              style: const TextStyle(color: tenantInk, fontSize: 12),
            ),
            if (_locationMessage != null) ...[
              const SizedBox(height: 5),
              Text(
                _locationMessage!,
                style: const TextStyle(color: tenantMuted, fontSize: 11),
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const ValueKey('search-selected-map-area'),
              onPressed: selection == null || _locating || _resolvingAddress
                  ? null
                  : () => _confirmSelection(selection),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Tìm nhà trọ tại đây'),
              style: FilledButton.styleFrom(
                backgroundColor: tenantGreen,
                minimumSize: const Size.fromHeight(42),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap() async {
    final selection = await Navigator.of(context).push<TenantAreaSelection>(
      MaterialPageRoute<TenantAreaSelection>(
        builder: (_) => TenantAreaPickerPage(
          initialPosition: _hasPosition ? _selectedPosition : null,
          locationService: widget.locationService,
        ),
      ),
    );
    if (!mounted || selection == null) return;
    setState(() {
      _selection = selection;
      _selectedPosition = LatLng(selection.latitude, selection.longitude);
      _hasPosition = true;
    });
    _confirmSelection(selection);
  }

  Future<void> _moveCamera(LatLng point) async {
    try {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(point, 16),
      );
    } catch (_) {
      // Address lookup can finish while the native map is initializing.
    }
  }

  Future<void> _locateCurrentPosition() async {
    final request = ++_locationRequest;
    _addressRequest++;
    setState(() {
      _locating = true;
      _resolvingAddress = false;
      _selection = null;
      _locationMessage = null;
    });
    try {
      final position = await widget.locationService.currentPosition();
      if (!mounted || request != _locationRequest) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPosition = point;
        _hasPosition = true;
        _locating = false;
      });
      unawaited(_moveCamera(point));
      await _resolveAddress(point);
    } on TenantLocationFailure catch (error) {
      if (mounted && request == _locationRequest) {
        setState(() => _locationMessage = error.message);
      }
    } catch (_) {
      if (mounted && request == _locationRequest) {
        setState(
          () => _locationMessage = 'Không lấy được GPS. Bạn vẫn có thể nhấn giữ bản đồ để chọn điểm.',
        );
      }
    } finally {
      if (mounted && request == _locationRequest) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _selectPoint(LatLng point) async {
    _locationRequest++;
    setState(() {
      _locating = false;
      _selectedPosition = point;
      _hasPosition = true;
    });
    await _resolveAddress(point);
  }

  Future<void> _resolveAddress(LatLng point) async {
    final request = ++_addressRequest;
    setState(() {
      _selection = null;
      _resolvingAddress = true;
      _locationMessage = null;
    });
    try {
      final selection = await widget.locationService.areaAt(
        point.latitude,
        point.longitude,
      );
      if (!mounted || request != _addressRequest) return;
      setState(() => _selection = selection);
    } catch (_) {
      if (mounted && request == _addressRequest) {
        setState(
          () => _locationMessage = 'Không tra được địa chỉ. Hãy thử chọn điểm khác hoặc nhập khu vực ở trang danh sách.',
        );
      }
    } finally {
      if (mounted && request == _addressRequest) {
        setState(() => _resolvingAddress = false);
      }
    }
  }

  void _confirmSelection(TenantAreaSelection selection) {
    final callback = widget.onSelected;
    if (callback != null) {
      callback(selection);
    } else {
      Navigator.of(context).pop(selection);
    }
  }
}
