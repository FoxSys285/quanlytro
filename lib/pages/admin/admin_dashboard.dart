import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/admin_store.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../landlord/finance/landlord_finance_models.dart';
import '../landlord/landlord_ui.dart' show formatLandlordMoney;
import 'admin_ui.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({
    super.key,
    required this.stores,
    required this.admin,
    this.userCount,
  });
  final List<LandlordDemoStore> stores;
  final AdminStore admin;
  final int? userCount;

  @override
  Widget build(BuildContext context) {
    final auth = LocalAuth.instance;
    final pending = stores
        .where((s) => !admin.isVerified(s.property.id))
        .toList();
    final rooms = stores.fold<int>(0, (n, s) => n + s.catalog.length);
    final occupied = stores.fold<int>(0, (n, s) => n + s.activeLeases.length);
    final debt = admin.statements.fold<int>(0, (n, s) => n + s.remaining);
    final tickets = admin.tickets.where((t) => !t.closed).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B192C),
                  Color(0xFF0F2942),
                  Color(0xFF0C4A6E),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Toàn cảnh nền tảng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Color(0xFFBAE6FD),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              landlordDate(DateTime.now()),
                              style: const TextStyle(
                                color: Color(0xFFBAE6FD),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              auth.isCloudMode ? '● Trực tuyến' : '● Sẵn sàng',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: Color(0xFF2DD4BF),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _stat(
                              auth.isCloudMode
                                  ? (userCount?.toString() ?? '—')
                                  : '${auth.localAccounts.length}',
                              'Tài khoản',
                              Icons.people_alt_outlined,
                              const Color(0xFF2DD4BF),
                            ),
                            _stat(
                              '${stores.length}',
                              'Nhà trọ',
                              Icons.apartment_rounded,
                              const Color(0xFF38BDF8),
                            ),
                            _stat(
                              '$occupied / $rooms',
                              'Phòng thuê',
                              Icons.door_front_door_outlined,
                              const Color(0xFF7DD3FC),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AdminSyncBar(),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: adminBlue.withValues(alpha: 0.1),
                              foregroundColor: adminBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: adminBlue.withValues(alpha: 0.2),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => RoleLayoutShell.navigateTo(
                              context,
                              'property_verification',
                            ),
                            icon: const Icon(
                              Icons.verified_user_outlined,
                              size: 20,
                            ),
                            label: Text(
                              pending.isNotEmpty
                                  ? 'Xác minh (${pending.length})'
                                  : 'Xác minh',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: adminInk,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: adminLine),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () =>
                                RoleLayoutShell.navigateTo(context, 'support'),
                            icon: const Icon(
                              Icons.support_agent_outlined,
                              size: 20,
                              color: adminMuted,
                            ),
                            label: Text(
                              'Hỗ trợ ($tickets)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Hồ sơ cần xem xét',
                            style: TextStyle(
                              color: adminInk,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AdminStatus(
                          '${pending.length} hồ sơ',
                          color: adminGold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (pending.isEmpty)
                      const AdminPanel(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.task_alt_rounded,
                            color: adminGreen,
                            size: 28,
                          ),
                          title: Text('Đã kiểm tra toàn bộ nhà trọ'),
                          subtitle: Text(
                            'Hồ sơ mới hoặc thông tin thay đổi sẽ xuất hiện tại đây.',
                          ),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, c) {
                          final width = c.maxWidth >= 840
                              ? (c.maxWidth - 32) / 3
                              : c.maxWidth >= 580
                              ? (c.maxWidth - 16) / 2
                              : c.maxWidth - 24;
                          return SizedBox(
                            height:
                                252 +
                                (MediaQuery.textScalerOf(context).scale(14) -
                                        14) *
                                    6,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: pending.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, i) => SizedBox(
                                width: width,
                                child: _property(context, pending[i]),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                    AdminPanel(
                      backgroundColor: const Color(0xFFE0F2FE),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: adminBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: adminBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Đối soát hoa hồng',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: adminInk,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Còn phải thu trong các kỳ đã chốt',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: adminMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    formatLandlordMoney(debt),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: adminBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              onPressed: () => RoleLayoutShell.navigateTo(
                                context,
                                'commissions',
                              ),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                              label: const Text('Mở đối soát'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AdminSection('Danh mục nhà trọ'),
                    AdminPanel(
                      child: Column(
                        children: [
                          for (var i = 0; i < stores.length; i++) ...[
                            if (i > 0)
                              const Divider(height: 24, color: adminLine),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _preview(context, stores[i]),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: AdminPropertyPhoto(
                                          property: stores[i].property,
                                          height: 64,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            stores[i].property.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: adminInk,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text:
                                                      '${stores[i].catalog.length} phòng · ',
                                                ),
                                                TextSpan(
                                                  text:
                                                      admin.isVerified(
                                                            stores[i]
                                                                .property
                                                                .id,
                                                          )
                                                          ? 'Đã xác minh'
                                                          : 'Chưa xác minh',
                                                  style: TextStyle(
                                                    color:
                                                        admin.isVerified(
                                                              stores[i]
                                                                  .property
                                                                  .id,
                                                            )
                                                            ? adminGreen
                                                            : adminGold,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: adminMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: adminMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          RoleLayoutShell.navigateTo(context, 'activity'),
                      icon: const Icon(Icons.sensors_outlined, size: 20),
                      label: Text(
                        'Phiên trên thiết bị: ${auth.role != null && auth.isForeground ? 1 : 0} · Xem phạm vi theo dõi',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon, Color accent) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x18FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x20FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFD1DCF2),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _property(BuildContext context, LandlordDemoStore store) {
    final issues = AdminStore.verificationIssues(store);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: adminLine),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _preview(context, store),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: AdminPropertyPhoto(property: store.property, height: 116),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.property.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: adminInk,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        size: 18,
                        color: adminBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    store.property.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: adminMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        issues.isEmpty
                            ? Icons.fact_check_outlined
                            : Icons.info_outline_rounded,
                        color: issues.isEmpty ? adminBlue : adminGold,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          issues.isEmpty
                              ? 'Đủ thông tin · chờ kiểm tra'
                              : 'Cần bổ sung ${issues.length} mục',
                          style: TextStyle(
                            color: issues.isEmpty ? adminBlue : adminGold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _preview(BuildContext context, LandlordDemoStore store) async {
    HapticFeedback.selectionClick();
    final issues = AdminStore.verificationIssues(store);
    final openReview = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 260),
              reverseDuration: Duration(milliseconds: 180),
            ),
      backgroundColor: Colors.white,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AdminPropertyPhoto(
                  property: store.property,
                  height: 190,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                store.property.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: adminInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                store.property.address,
                style: const TextStyle(color: adminMuted),
              ),
              const SizedBox(height: 16),
              Text('${store.property.ownerName} · ${store.property.phone}'),
              const SizedBox(height: 16),
              if (issues.isEmpty)
                const Text(
                  'Thông tin cơ bản đầy đủ. Cần kiểm tra nội dung và ảnh trước khi xác minh.',
                  style: TextStyle(color: adminBlue),
                )
              else ...[
                const Text(
                  'Thông tin cần bổ sung',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final issue in issues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 17,
                          color: adminGold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(issue)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Mở danh sách xác minh'),
              ),
            ],
          ),
        ),
      ),
    );
    if (openReview == true && context.mounted) {
      RoleLayoutShell.navigateTo(context, 'property_verification');
    }
  }
}
