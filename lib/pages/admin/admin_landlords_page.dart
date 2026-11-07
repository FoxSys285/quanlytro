import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../shared/widgets/list_pagination.dart';
import 'admin_ui.dart';

class AdminLandlordsPage extends StatefulWidget {
  const AdminLandlordsPage({super.key});

  @override
  State<AdminLandlordsPage> createState() => _AdminLandlordsPageState();
}

class _AdminLandlordsPageState extends State<AdminLandlordsPage> {
  String _query = '';
  String _verification = 'all';
  int _page = 0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      RentalPortfolio.instance,
      AdminStore.instance,
    ]),
    builder: (context, _) {
      final stores = RentalPortfolio.instance.stores;
      final admin = AdminStore.instance;
      final matched = stores.where((store) {
        final property = store.property;
        final verified = admin.isVerified(property.id);
        final text =
            '${property.ownerName} ${property.phone} ${property.name} ${property.address}'
                .toLowerCase();
        return text.contains(_query) &&
            (_verification == 'all' ||
                (_verification == 'verified' ? verified : !verified));
      }).toList();
      final roomCount = matched.fold<int>(
        0,
        (sum, store) => sum + store.catalog.length,
      );
      final page = _page.clamp(0, ListPagination.lastPage(matched.length, 10));

      return AdminFrame(
        title: 'Quản lý chủ trọ',
        subtitle:
            'Xem quy mô phòng, trạng thái xác minh và hồ sơ từng nhà trọ.',
        children: [
          const AdminSyncBar(),
          Row(
            children: [
              Expanded(
                child: _summary(
                  '${stores.length}',
                  'Chủ trọ',
                  Icons.people_alt_rounded,
                  adminBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summary(
                  '$roomCount',
                  'Phòng trong kết quả',
                  Icons.door_front_door_rounded,
                  adminPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summary(
                  '${stores.where((s) => admin.isVerified(s.property.id)).length}',
                  'Đã xác minh',
                  Icons.verified_rounded,
                  adminGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tìm chủ trọ, nhà trọ, số điện thoại',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() {
                    _query = value.trim().toLowerCase();
                    _page = 0;
                  }),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final option in const [
                      (id: 'all', label: 'Tất cả'),
                      (id: 'pending', label: 'Chưa xác minh'),
                      (id: 'verified', label: 'Đã xác minh'),
                    ])
                      ChoiceChip(
                        label: Text(option.label),
                        selected: _verification == option.id,
                        onSelected: (_) => setState(() {
                          _verification = option.id;
                          _page = 0;
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          AdminSection(
            'Danh sách chủ trọ',
            caption: '${matched.length} hồ sơ phù hợp · 10 hồ sơ mỗi trang',
          ),
          if (matched.isEmpty)
            const AdminPanel(
              child: Text('Không tìm thấy hồ sơ chủ trọ phù hợp.'),
            ),
          for (final store in matched.skip(page * 10).take(10))
            _landlordCard(context, store, admin),
          ListPagination(
            total: matched.length,
            page: page,
            pageSize: 10,
            onChanged: (value) => setState(() => _page = value),
          ),
          const SizedBox(height: 4),
          const Text(
            'Các tài khoản hiện dùng Free mặc định. Hệ thống chưa lưu trạng thái đăng ký hoặc giao dịch nâng cấp gói trả phí.',
            style: TextStyle(color: adminMuted, fontSize: 12, height: 1.45),
          ),
        ],
      );
    },
  );

  Widget _summary(String value, String label, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: adminLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: adminInk,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: adminMuted, fontSize: 11),
            ),
          ],
        ),
      );

  Widget _landlordCard(
    BuildContext context,
    LandlordDemoStore store,
    AdminStore admin,
  ) {
    final property = store.property;
    final verified = admin.isVerified(property.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: adminBlue.withValues(alpha: .1),
                  foregroundColor: adminBlue,
                  child: const Icon(Icons.person_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.ownerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: adminInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${property.phone} · Mã ${property.id}',
                        style: const TextStyle(fontSize: 12, color: adminMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      AdminStatus(
                        verified ? 'Đã xác minh' : 'Chưa xác minh',
                        color: verified ? adminGreen : adminGold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _detail(
                    'Nhà trọ',
                    property.name,
                    Icons.home_work_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _detail(
                    'Số phòng',
                    '${store.catalog.length} phòng',
                    Icons.door_front_door_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _detail(
                    'Gói hiện tại',
                    'Free · mặc định',
                    Icons.workspace_premium_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              property.address,
              style: const TextStyle(color: adminMuted, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _showPropertyDetail(context, store, verified),
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('Xem hồ sơ nhà trọ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value, IconData icon) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 17, color: adminPurple),
      const SizedBox(width: 7),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: adminMuted, fontSize: 10),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: adminInk,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  void _showPropertyDetail(
    BuildContext context,
    LandlordDemoStore store,
    bool verified,
  ) {
    final property = store.property;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(property.name),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminStatus(
                  verified ? 'Đã xác minh' : 'Chưa xác minh',
                  color: verified ? adminGreen : adminGold,
                ),
                const SizedBox(height: 16),
                _propertyLine('Chủ trọ', property.ownerName),
                _propertyLine('Điện thoại', property.phone),
                _propertyLine('Địa chỉ', property.address),
                _propertyLine('Số phòng', '${store.catalog.length}'),
                _propertyLine('Mã hồ sơ', property.id),
                const SizedBox(height: 10),
                Text(
                  property.description,
                  style: const TextStyle(color: adminMuted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.pop(context);
              RoleLayoutShell.navigateTo(context, 'property_verification');
            },
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Tới trang xác minh'),
          ),
        ],
      ),
    );
  }

  Widget _propertyLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: adminMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: adminInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
