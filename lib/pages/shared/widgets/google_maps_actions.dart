import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

String googleMapsDestination(
  String address, {
  double? latitude,
  double? longitude,
}) => latitude != null && longitude != null
    ? '$latitude,$longitude'
    : address.trim();

Uri googleMapsSearchUri(
  String address, {
  double? latitude,
  double? longitude,
}) => Uri.https('www.google.com', '/maps/search/', {
  'api': '1',
  'query': googleMapsDestination(
    address,
    latitude: latitude,
    longitude: longitude,
  ),
});

Uri googleMapsDirectionsUri(
  String address, {
  double? latitude,
  double? longitude,
}) => Uri.https('www.google.com', '/maps/dir/', {
  'api': '1',
  'destination': googleMapsDestination(
    address,
    latitude: latitude,
    longitude: longitude,
  ),
  'travelmode': 'driving',
});

class GoogleMapsActions extends StatelessWidget {
  const GoogleMapsActions({
    super.key,
    required this.address,
    this.latitude,
    this.longitude,
    this.launch,
  });

  final String address;
  final double? latitude;
  final double? longitude;
  final Future<bool> Function(Uri)? launch;

  bool get _hasDestination =>
      address.trim().isNotEmpty || (latitude != null && longitude != null);

  void _message(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _open(BuildContext context, {bool directions = false}) async {
    try {
      final uri = directions
          ? googleMapsDirectionsUri(
              address,
              latitude: latitude,
              longitude: longitude,
            )
          : googleMapsSearchUri(
              address,
              latitude: latitude,
              longitude: longitude,
            );
      final opened =
          await (launch?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!context.mounted) return;
      if (!opened) {
        _message(context, 'Không mở được bản đồ. Hãy sao chép liên kết.');
      }
    } catch (_) {
      if (!context.mounted) return;
      _message(context, 'Không mở được bản đồ. Hãy sao chép liên kết.');
    }
  }

  Future<void> _copy(BuildContext context) async {
    try {
      await Clipboard.setData(
        ClipboardData(
          text: googleMapsSearchUri(
            address,
            latitude: latitude,
            longitude: longitude,
          ).toString(),
        ),
      );
      if (!context.mounted) return;
      _message(context, 'Đã sao chép liên kết Google Maps.');
    } catch (_) {
      if (!context.mounted) return;
      _message(context, 'Không sao chép được liên kết. Vui lòng thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      OutlinedButton.icon(
        onPressed: _hasDestination ? () => _open(context) : null,
        icon: const Icon(Icons.map_outlined, size: 18),
        label: const Text('Mở Google Maps'),
      ),
      OutlinedButton.icon(
        onPressed: _hasDestination
            ? () => _open(context, directions: true)
            : null,
        icon: const Icon(Icons.directions_rounded, size: 18),
        label: const Text('Chỉ đường'),
      ),
      TextButton.icon(
        onPressed: _hasDestination ? () => _copy(context) : null,
        icon: const Icon(Icons.copy_outlined, size: 16),
        label: const Text('Sao chép liên kết'),
      ),
    ],
  );
}
