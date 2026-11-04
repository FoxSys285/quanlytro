import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../landlord_theme.dart';

import '../landlord_demo_store.dart';
import 'components/landlord_property_editor.dart';
import 'components/landlord_property_image.dart';
import 'models/landlord_property.dart';
import 'property_portfolio_page.dart';
import '../../shared/widgets/google_maps_actions.dart';

class LandlordPropertiesPage extends StatelessWidget {
  const LandlordPropertiesPage({super.key, this.store});
  final LandlordDemoStore? store;
  LandlordDemoStore get _store => store ?? LandlordDemoStore.activeInstance;

  Future<void> _edit(BuildContext context) async {
    final result = await showDialog<LandlordProperty>(
      context: context,
      builder: (_) => LandlordPropertyEditor(property: _store.property),
    );
    if (result == null) return;
    _store.updateProperty(result);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin nhà trọ.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (store == null && RentalPortfolio.instance.stores.length > 1) {
      return const PropertyPortfolioPage();
    }
    return ListenableBuilder(
      listenable: Listenable.merge([_store, AdminStore.instance]),
      builder: (context, _) {
        final property = _store.property;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin nhà trọ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  if (AdminStore.instance.reviewNote(property.id).isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Yêu cầu từ quản trị viên: ${AdminStore.instance.reviewNote(property.id)}',
                        ),
                      ),
                    ),
                  LandlordPropertyImage(
                    url: property.imageUrl,
                    bytes: property.imageBytes,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: LandlordPalette.of(context).surface,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3769D6),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _Detail(
                            icon: Icons.location_on_outlined,
                            label: 'Vị trí',
                            value: property.address,
                          ),
                          GoogleMapsActions(
                            address:
                                [property.address, property.ward, property.city]
                                    .where((part) => part.trim().isNotEmpty)
                                    .join(', '),
                          ),
                          const SizedBox(height: 16),
                          _Detail(
                            icon: Icons.person_outline,
                            label: 'Chủ trọ',
                            value: property.ownerName,
                          ),
                          const SizedBox(height: 16),
                          _Detail(
                            icon: Icons.phone_outlined,
                            label: 'Số điện thoại',
                            value: property.phone,
                          ),
                          if (property.description.isNotEmpty) ...[
                            const Divider(height: 32),
                            const Text(
                              'Giới thiệu',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              property.description,
                              style: const TextStyle(height: 1.5),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => _edit(context),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Chỉnh sửa thông tin'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thông tin và hình ảnh được lưu trên thiết bị.',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFF3769D6)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            SelectableText(value),
          ],
        ),
      ),
    ],
  );
}
