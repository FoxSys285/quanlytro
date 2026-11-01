import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

Uri googleMapsSearchUri(String address) => Uri.https(
  'www.google.com',
  '/maps/search/',
  {'api': '1', 'query': address.trim()},
);

class GoogleMapsActions extends StatelessWidget {
  const GoogleMapsActions({super.key, required this.address, this.launch});

  final String address;
  final Future<bool> Function(Uri)? launch;

  void _message(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _open(BuildContext context) async {
    try {
      final uri = googleMapsSearchUri(address);
      final opened = await (launch?.call(uri) ?? launchUrl(uri, mode: LaunchMode.externalApplication));
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
        ClipboardData(text: googleMapsSearchUri(address).toString()),
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
        onPressed: address.trim().isEmpty ? null : () => _open(context),
        icon: const Icon(Icons.map_outlined, size: 18),
        label: const Text('Mở Google Maps'),
      ),
      TextButton.icon(
        onPressed: address.trim().isEmpty ? null : () => _copy(context),
        icon: const Icon(Icons.copy_outlined, size: 16),
        label: const Text('Sao chép liên kết'),
      ),
    ],
  );
}
