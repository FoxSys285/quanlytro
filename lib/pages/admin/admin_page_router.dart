import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../landlord/landlord_ui.dart';
import '../landlord/finance/landlord_finance_models.dart';
import '../shared/help/support_tickets_page.dart';
import '../shared/notifications/notification_settings_page.dart';
import '../shared/profile/account_profile_page.dart';
import '../shared/settings/account_settings_page.dart';

Widget buildAdminPage(BuildContext context, RoleDestination destination) =>
    switch (destination.id) {
      'support' => const SupportTicketsPage(role: AppRole.admin),
      'profile' => const AccountProfilePage(role: AppRole.admin),
      'notifications' => const NotificationSettingsPage(role: AppRole.admin),
      'settings' => const _AdminSettings(),
      _ => _AdminDataPage(destination: destination),
    };

class _AdminSettings extends StatelessWidget {
  const _AdminSettings();
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AdminStore.instance,
    builder: (context, _) => ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: LandlordCard(
            child: SwitchListTile(
              title: const Text('Tiếp nhận lịch xem phòng'),
              subtitle: const Text('Áp dụng cho các nhà trọ trên thiết bị.'),
              value: AdminStore.instance.acceptingViewings,
              onChanged: AdminStore.instance.setAcceptingViewings,
            ),
          ),
        ),
        const AccountSettingsPage(role: AppRole.admin),
      ],
    ),
  );
}

class _AdminDataPage extends StatefulWidget {
  const _AdminDataPage({required this.destination});
  final RoleDestination destination;
  @override
  State<_AdminDataPage> createState() => _AdminDataPageState();
}

class _AdminDataPageState extends State<_AdminDataPage> {
  String _query = '';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      RentalPortfolio.instance,
      AdminStore.instance,
      LocalAuth.instance,
    ]),
    builder: (context, _) {
      final portfolio = RentalPortfolio.instance;
      final admin = AdminStore.instance;
      final stores = portfolio.stores;
      final id = widget.destination.id;
      final children = <Widget>[
        LandlordPageTitle(
          title: widget.destination.label,
          subtitle: 'Quản trị dữ liệu và hoạt động trên thiết bị.',
        ),
      ];
      if (id == 'dashboard') {
        final rooms = stores.fold<int>(0, (sum, s) => sum + s.catalog.length);
        final leases = stores.fold<int>(
          0,
          (sum, s) => sum + s.activeLeases.length,
        );
        final debt = stores.fold<int>(
          0,
          (sum, s) =>
              sum +
              s.payableInvoices.fold<int>(0, (sum, i) => sum + i.remaining),
        );
        children.add(
          LandlordCard(
            child: Wrap(
              spacing: 32,
              runSpacing: 24,
              children: [
                _metric('${stores.length}', 'Nhà trọ'),
                _metric('$rooms', 'Phòng'),
                _metric('$leases', 'Hợp đồng hiệu lực'),
                _metric(formatLandlordMoney(debt), 'Công nợ'),
                _metric(
                  '${admin.tickets.where((t) => !t.closed).length}',
                  'Yêu cầu hỗ trợ đang mở',
                ),
              ],
            ),
          ),
        );
        children.add(const SizedBox(height: 18));
        children.add(
          const Text(
            'Tình hình các nhà trọ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        );
        for (final store in stores) {
          children.add(
            LandlordCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.apartment_rounded,
                  color: landlordBlue,
                ),
                title: Text(store.property.name),
                subtitle: Text(
                  '${store.catalog.length} phòng · ${store.activeLeases.length} đang thuê\n${store.property.address}',
                ),
                isThreeLine: true,
                trailing: Icon(
                  admin.isVerified(store.property.id)
                      ? Icons.verified_outlined
                      : Icons.pending_outlined,
                  color: admin.isVerified(store.property.id)
                      ? Colors.teal
                      : Colors.orange,
                ),
              ),
            ),
          );
        }
      } else if (id == 'users') {
        children.add(
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm người dùng, số điện thoại, phòng',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        );
        children.add(const SizedBox(height: 16));
        children.add(
          const Text(
            'Tài khoản đăng nhập',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        );
        for (final role in AppRole.values) {
          children.add(
            LandlordCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(role.icon),
                title: Text(role.label),
                subtitle: Text(LocalAuth.emailFor(role)),
                trailing: role == AppRole.admin
                    ? const Text('Quản trị')
                    : Switch(
                        value: !LocalAuth.instance.isDisabled(role),
                        onChanged: (v) {
                          LocalAuth.instance.setDisabled(role, !v);
                          admin.record(
                            '${v ? 'Mở khóa' : 'Khóa'} tài khoản ${LocalAuth.emailFor(role)}',
                          );
                        },
                      ),
              ),
            ),
          );
        }
        children.add(const SizedBox(height: 16));
        children.add(
          const Text(
            'Hồ sơ người thuê',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        );
        final matched = [
          for (final store in stores)
            for (final member in store.members)
              if ('${member.name} ${member.phone} ${store.leaseById(member.leaseId)?.room ?? ''}'
                  .toLowerCase()
                  .contains(_query))
                (store: store, member: member),
        ];
        children.add(
          Text(
            '${matched.length} hồ sơ phù hợp',
            style: const TextStyle(color: landlordMuted),
          ),
        );
        for (final entry in matched.take(50)) {
          children.add(
            LandlordCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(entry.member.name),
                subtitle: Text(
                  '${entry.member.phone}\n${entry.store.property.name} · Phòng ${entry.store.leaseById(entry.member.leaseId)?.room ?? '—'}',
                ),
                isThreeLine: true,
              ),
            ),
          );
        }
        if (matched.length > 50) {
          children.add(
            const Text(
              'Hiển thị 50 hồ sơ đầu. Nhập tên hoặc phòng để thu hẹp kết quả.',
            ),
          );
        }
      } else if (id == 'property_verification' || id == 'moderation') {
        for (final store in stores) {
          final p = store.property;
          final verified = admin.isVerified(p.id);
          children.add(
            LandlordCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${p.address}\n${p.ownerName} · ${p.phone}'),
                  const SizedBox(height: 12),
                  Text(p.description),
                  const SizedBox(height: 12),
                  if (id == 'property_verification')
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(verified ? 'Đã xác minh' : 'Chờ xác minh'),
                        OutlinedButton.icon(
                          onPressed: () => admin.verify(p.id, !verified),
                          icon: Icon(
                            verified ? Icons.undo : Icons.verified_outlined,
                          ),
                          label: Text(
                            verified ? 'Thu hồi xác minh' : 'Xác minh nhà trọ',
                          ),
                        ),
                      ],
                    )
                  else
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hiển thị tin trong Khám phá'),
                      subtitle: Text(
                        '${store.catalog.length} phòng · ${admin.isHidden(p.id) ? 'Đang ẩn' : 'Đang hiển thị'}',
                      ),
                      value: !admin.isHidden(p.id),
                      onChanged: (v) => admin.setHidden(p.id, !v),
                    ),
                ],
              ),
            ),
          );
        }
      } else if (id == 'audit_logs') {
        if (admin.logs.isEmpty) {
          children.add(
            const LandlordEmptyState(
              message: 'Chưa có hoạt động được ghi nhận.',
            ),
          );
        }
        for (final log in admin.logs) {
          final at = DateTime.parse(log['at']!);
          children.add(
            LandlordCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded),
                title: Text(log['action']!),
                subtitle: Text(
                  '${log['actor']} · ${landlordDate(at)} ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          );
        }
      }
      return LandlordPageFrame(children: children);
    },
  );

  Widget _metric(String value, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: landlordBlue,
        ),
      ),
      Text(label),
    ],
  );
}
