import 'package:flutter/material.dart';

import '../../../data/app_persistence.dart';
import '../../../data/admin_store.dart';
import '../../../data/local_auth.dart';
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

  Future<void> _createProperty(BuildContext context) async {
    final portfolio = RentalPortfolio.instance;
    if (portfolio.stores.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mỗi chủ trọ chỉ được quản lý một nhà trọ.'),
        ),
      );
      return;
    }
    final session = LocalAuth.instance.session;
    if (LocalAuth.instance.isCloudMode && session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.'),
        ),
      );
      return;
    }
    final draft = LandlordProperty(
      id: session?.uid ?? 'property-${DateTime.now().microsecondsSinceEpoch}',
      name: '',
      address: '',
      ownerName: session?.displayName ?? '',
      phone: '',
      description: '',
      city: '',
      ward: '',
    );
    final property = await showDialog<LandlordProperty>(
      context: context,
      builder: (_) => LandlordPropertyEditor(property: draft, creating: true),
    );
    if (property == null || !context.mounted) return;
    try {
      portfolio.createSingleProperty(property);
      await AppPersistence.current?.flush();
      if (!context.mounted) return;
      final saveError = AppPersistence.current?.error.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saveError ??
                'Đã tạo nhà trọ. Hãy thêm loại phòng và phòng trọ của bạn.',
          ),
        ),
      );
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message.toString())));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa lưu được nhà trọ. Hãy kiểm tra kết nối Firebase rồi thử lại.',
          ),
        ),
      );
    }
  }

  Widget _emptyPortfolio(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 34,
                  child: Icon(Icons.apartment_rounded, size: 34),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Chưa có nhà trọ nào',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tạo nhà trọ để bắt đầu quản lý thông tin, loại phòng và phòng cho thuê.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5, color: Colors.blueGrey),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => _createProperty(context),
                  icon: const Icon(Icons.add_home_work_outlined),
                  label: const Text('Tạo phòng trọ'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _edit(BuildContext context) async {
    final result = await showDialog<LandlordProperty>(
      context: context,
      builder: (_) => LandlordPropertyEditor(property: _store.property),
    );
    if (result == null) return;
    _store.updateProperty(result);
    try {
      await AppPersistence.current?.saveChanges();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppPersistence.current?.cloudConfirmed == true
                ? 'Đã cập nhật thông tin nhà trọ lên Firebase.'
                : 'Đã cập nhật thông tin nhà trọ trên máy.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (store == null) {
      if (RentalPortfolio.instance.stores.isNotEmpty) {
        return const PropertyPortfolioPage();
      }
      return ListenableBuilder(
        listenable: RentalPortfolio.instance,
        builder: (context, _) {
          if (RentalPortfolio.instance.stores.isEmpty) {
            return _emptyPortfolio(context);
          }
          return const PropertyPortfolioPage();
        },
      );
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
                    'Thông tin nhà trọ được lưu trên Firebase và đồng bộ theo quyền chủ sở hữu.',
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
