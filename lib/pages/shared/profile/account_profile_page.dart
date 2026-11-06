import 'package:flutter/material.dart';

import '../../../layouts/role_layout.dart';
import '../../landlord/landlord_ui.dart';
import 'account_store.dart';
import 'contact_details.dart';
import 'contact_editor.dart';
import '../rental/tenant_session.dart';
import '../../tenant/tenant_detail_ui.dart';
import '../../tenant/tenant_ui.dart';
import '../../tenant/tenant_feature_ui.dart';

class AccountProfilePage extends StatelessWidget {
  const AccountProfilePage({super.key, required this.role, this.store});
  final AppRole role;
  final AccountStore? store;
  AccountStore get _store => store ?? AccountStore.instance;

  Future<void> _edit(BuildContext context) async {
    final contact = await showDialog<ContactDetails>(
      context: context,
      builder: (_) => role == AppRole.tenant || role == AppRole.landlord
          ? TenantDetailTheme(
              landlordStyle: role == AppRole.landlord,
              child: ContactEditor(
                title: 'Chỉnh sửa hồ sơ',
                initial: _store.profile(role),
                tenantStyle: true,
                subtitle: role == AppRole.landlord
                    ? 'Thông tin giúp người thuê và đối tác liên hệ với bạn.'
                    : 'Thông tin giúp chủ trọ liên hệ và hỗ trợ bạn.',
              ),
            )
          : ContactEditor(
              title: 'Chỉnh sửa hồ sơ',
              initial: _store.profile(role),
            ),
    );
    if (contact == null || !context.mounted) return;
    _store.saveProfile(role, contact);
    showLandlordMessage(context, 'Đã cập nhật hồ sơ cá nhân.');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final contact = _store.profile(role);
      final color = role == AppRole.tenant
          ? const Color(0xFF16836F)
          : landlordBlue;
      final lease = role == AppRole.tenant
          ? _store.rental.currentLeaseForTenant(TenantSession.currentTenantId)
          : null;
      if (role == AppRole.tenant || role == AppRole.landlord) {
        final isTenant = role == AppRole.tenant;
        return TenantFeatureFrame(
          artwork: isTenant
              ? TenantFeatureArtwork.settings
              : TenantFeatureArtwork.landlordSettings,
          title: 'Hồ sơ cá nhân',
          subtitle: isTenant
              ? 'Thông tin liên hệ để kết nối với chủ trọ dễ dàng hơn.'
              : 'Thông tin liên hệ để người thuê dễ dàng kết nối với bạn.',
          children: [
            TenantSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TenantProfileAvatar(name: contact.name, radius: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.name,
                              style: const TextStyle(
                                color: tenantInk,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TenantStatusPill(
                              role.label,
                              color: isTenant
                                  ? TenantUiColors.tenant.primary
                                  : TenantUiColors.landlord.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const TenantSectionHeading('Thông tin liên hệ'),
            TenantSurface(
              child: Column(
                children: [
                  _tenantLine(
                    Icons.phone_outlined,
                    'Số điện thoại',
                    contact.phone,
                  ),
                  const TenantThinDivider(),
                  _tenantLine(Icons.email_outlined, 'Email', contact.email),
                  const TenantThinDivider(),
                  if (isTenant) ...[
                    _tenantLine(
                      Icons.link_rounded,
                      'Mã liên kết để chủ trọ lập hợp đồng',
                      TenantSession.currentTenantId,
                    ),
                  ],
                  const TenantThinDivider(),
                  _tenantLine(
                    Icons.location_on_outlined,
                    'Địa chỉ liên hệ',
                    contact.address,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TenantSectionHeading(
              isTenant ? 'Chỗ ở hiện tại' : 'Nhà trọ quản lý',
            ),
            TenantSurface(
              child: _tenantLine(
                Icons.home_work_outlined,
                isTenant ? _store.rental.property.name : 'Nhà trọ',
                isTenant
                    ? lease == null
                          ? 'Chưa có phòng đang thuê'
                          : 'Phòng ${lease.room}'
                    : _store.rental.property.name,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Chỉnh sửa hồ sơ'),
              ),
            ),
          ],
        );
      }
      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Hồ sơ cá nhân',
            subtitle: 'Thông tin tài khoản ${role.label.toLowerCase()}.',
          ),
          LandlordCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(role.icon, color: color, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LandlordStatusPill(role.label, color: color),
                const Divider(height: 28),
                _line(Icons.phone_outlined, 'Số điện thoại', contact.phone),
                _line(Icons.email_outlined, 'Email', contact.email),
                _line(
                  Icons.location_on_outlined,
                  'Địa chỉ liên hệ',
                  contact.address.isEmpty ? 'Chưa cập nhật' : contact.address,
                ),
                _line(
                  Icons.home_work_outlined,
                  role == AppRole.landlord
                      ? 'Nhà trọ quản lý'
                      : 'Chỗ ở hiện tại',
                  role == AppRole.landlord
                      ? _store.rental.property.name
                      : lease == null
                      ? 'Chưa có phòng đang thuê'
                      : '${_store.rental.property.name} · Phòng ${lease.room}',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _edit(context),
                  style: FilledButton.styleFrom(backgroundColor: color),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Chỉnh sửa hồ sơ'),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  Widget _tenantLine(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TenantDetailIcon(icon),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: tenantMuted, fontSize: 11),
            ),
            const SizedBox(height: 5),
            SelectableText(
              value.isEmpty ? 'Chưa cập nhật' : value,
              style: const TextStyle(
                color: tenantInk,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _line(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: landlordMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: landlordMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
