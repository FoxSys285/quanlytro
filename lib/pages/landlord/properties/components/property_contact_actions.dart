import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/google_maps_actions.dart';
import '../models/landlord_property.dart';

class PropertyContactActions extends StatelessWidget {
  const PropertyContactActions({super.key, required this.property});

  final LandlordProperty property;

  Future<void> _call(BuildContext context) async {
    final number = property.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    try {
      final opened = await launchUrl(Uri(scheme: 'tel', path: number));
      if (opened || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Không mở được ứng dụng gọi điện.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final number = property.phone.replaceAll(RegExp(r'\D'), '');
    final canCall =
        !property.phoneIsSynthetic &&
        number.length >= 9 &&
        !RegExp(r'^0+$').hasMatch(number);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (property.latitude != null && property.longitude != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Tọa độ: ${property.latitude!.toStringAsFixed(6)}, '
              '${property.longitude!.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        GoogleMapsActions(
          address: [
            property.address,
            property.ward,
            property.city,
          ].where((part) => part.trim().isNotEmpty).join(', '),
          latitude: property.latitude,
          longitude: property.longitude,
        ),
        OutlinedButton.icon(
          onPressed: canCall ? () => _call(context) : null,
          icon: const Icon(Icons.call_outlined, size: 18),
          label: Text(
            canCall ? 'Gọi ${property.phone}' : 'Chưa có số điện thoại liên hệ',
          ),
        ),
      ],
    );
  }
}
