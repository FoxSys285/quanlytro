import 'dart:ui' show Locale;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/tenant_area_selection.dart';

class TenantLocationFailure implements Exception {
  const TenantLocationFailure(this.message);
  final String message;
}

class TenantLocationService {
  const TenantLocationService();

  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const TenantLocationFailure(
        'Hãy bật dịch vụ vị trí trên thiết bị.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const TenantLocationFailure(
        'Chưa cấp quyền vị trí. Hãy cấp quyền trong cài đặt thiết bị.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  Future<TenantAreaSelection> currentArea() async {
    final position = await currentPosition();
    return areaAt(position.latitude, position.longitude);
  }

  Future<TenantAreaSelection> areaAt(double latitude, double longitude) async {
    final places = await Geocoding(locale: const Locale('vi', 'VN'))
        .placemarkFromCoordinates(latitude, longitude)
        .timeout(const Duration(seconds: 12));
    if (places.isEmpty) {
      throw const TenantLocationFailure(
        'Không tra được địa chỉ. Vui lòng chọn khu vực tìm phòng.',
      );
    }
    final first = selectionFromPlacemark(places.first, latitude, longitude);
    if (first.ward != null) return first;
    for (final place in places.skip(1)) {
      try {
        final candidate = selectionFromPlacemark(place, latitude, longitude);
        if (sameLocationName(candidate.city, first.city) &&
            candidate.ward != null) {
          return candidate;
        }
      } on TenantLocationFailure {
        continue;
      }
    }
    return first;
  }

  static TenantAreaSelection selectionFromPlacemark(
    Placemark place,
    double latitude,
    double longitude,
  ) {
    String? firstName(List<String?> values) {
      for (final value in values) {
        if (value != null && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }

    final wardPrefix = RegExp(
      r'^(phường|xã|thị trấn|ward|commune|township)\s',
      caseSensitive: false,
    );
    final districtPrefix = RegExp(
      r'^(quận|huyện|district)\s',
      caseSensitive: false,
    );
    final city = firstName([
      place.administrativeArea,
      if (!wardPrefix.hasMatch(place.locality ?? '') &&
          !districtPrefix.hasMatch(place.locality ?? ''))
        place.locality,
    ]);
    if (city == null) {
      throw const TenantLocationFailure(
        'Không xác định được tỉnh/thành phố. Vui lòng chọn khu vực tìm phòng.',
      );
    }
    // A district is not a ward. If the provider omits the ward, filter by city.
    final locality = firstName([
      for (final candidate in [
        place.subLocality,
        place.locality,
        place.subAdministrativeArea,
        place.name,
      ])
        if (candidate != null && wardPrefix.hasMatch(candidate)) candidate,
      if (!districtPrefix.hasMatch(place.subLocality ?? '')) place.subLocality,
    ]);
    final ward =
        locality != null &&
            !sameLocationName(locality, city) &&
            !districtPrefix.hasMatch(locality)
        ? locality
        : null;
    return TenantAreaSelection(
      city: city,
      ward: ward,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
