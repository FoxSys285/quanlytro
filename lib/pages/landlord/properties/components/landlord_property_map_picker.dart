import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../tenant/discovery/services/tenant_location_service.dart';
import '../../../shared/widgets/google_maps_actions.dart';

class LandlordPropertyMapPickerPage extends StatefulWidget {
  const LandlordPropertyMapPickerPage({
    super.key,
    required this.initialCity,
    this.initialPosition,
  });

  final String initialCity;
  final LatLng? initialPosition;

  @override
  State<LandlordPropertyMapPickerPage> createState() =>
      _LandlordPropertyMapPickerPageState();
}

class _LandlordPropertyMapPickerPageState
    extends State<LandlordPropertyMapPickerPage> {
  GoogleMapController? _controller;
  LatLng? _selectedPosition;
  late final LatLng _initialTarget;
  bool _locating = false;

  bool get _supportsGoogleMaps =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _initialTarget = widget.initialPosition ?? _cityCenter(widget.initialCity);
  }

  static LatLng _cityCenter(String city) {
    final name = city.trim().toLowerCase();
    if (name.contains('hà nội') || name.contains('ha noi')) {
      return const LatLng(21.0278, 105.8342);
    }
    if (name.contains('hồ chí minh') ||
        name.contains('ho chi minh') ||
        name.contains('hcm')) {
      return const LatLng(10.8231, 106.6297);
    }
    if (name.contains('đà nẵng') || name.contains('da nang')) {
      return const LatLng(16.0544, 108.2022);
    }
    if (name.contains('cần thơ') || name.contains('can tho')) {
      return const LatLng(10.0452, 105.7469);
    }
    if (name.contains('hải phòng') || name.contains('hai phong')) {
      return const LatLng(20.8449, 106.6881);
    }
    if (name.contains('huế') || name.contains('hue')) {
      return const LatLng(16.4637, 107.5909);
    }
    return const LatLng(16.0544, 108.2022);
  }

  void _selectPoint(LatLng point) {
    setState(() => _selectedPosition = point);
  }

  Future<void> _goToCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await const TenantLocationService().currentPosition();
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      _selectPoint(point);
      await _controller?.animateCamera(CameraUpdate.newLatLngZoom(point, 17));
    } on TenantLocationFailure catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Không lấy được vị trí hiện tại.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirm() {
    final position = _selectedPosition;
    if (position == null) return;
    Navigator.of(context).pop(position);
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsGoogleMaps) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chọn vị trí nhà trọ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bản đồ nhúng hiện khả dụng trên Android và iOS.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                GoogleMapsUrlFallbackButton(
                  address: widget.initialCity,
                  latitude: _initialTarget.latitude,
                  longitude: _initialTarget.longitude,
                  label: 'Mở vị trí bằng Google Maps URL',
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí nhà trọ'),
        actions: [
          TextButton(
            onPressed: _selectedPosition == null ? null : _confirm,
            child: const Text('Xong'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialTarget,
              zoom: widget.initialPosition == null ? 12 : 16,
            ),
            onMapCreated: (controller) => _controller = controller,
            onTap: _selectPoint,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            markers: {
              if (_selectedPosition case final point?)
                Marker(
                  markerId: const MarkerId('property-location'),
                  position: point,
                  draggable: true,
                  infoWindow: const InfoWindow(title: 'Vị trí nhà trọ'),
                  onDragEnd: _selectPoint,
                ),
            },
            compassEnabled: true,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            left: 12,
            top: 12,
            right: 64,
            child: IgnorePointer(
              child: Material(
                color: Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Text(
                    'Chạm vào bản đồ để ghim vị trí. Có thể kéo ghim để chỉnh chính xác.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton.small(
              heroTag: 'property-map-current-location',
              tooltip: 'Về vị trí hiện tại',
              onPressed: _locating ? null : _goToCurrentLocation,
              child: _locating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _selectedPosition == null
                    ? 'Chưa chọn điểm trên bản đồ'
                    : 'Vĩ độ ${_selectedPosition!.latitude.toStringAsFixed(6)}  ·  Kinh độ ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              GoogleMapsUrlFallbackButton(
                address: widget.initialCity,
                latitude: (_selectedPosition ?? _initialTarget).latitude,
                longitude: (_selectedPosition ?? _initialTarget).longitude,
                label: 'Nếu bản đồ lỗi, mở Google Maps URL',
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _selectedPosition == null ? null : _confirm,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Dùng vị trí này'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
