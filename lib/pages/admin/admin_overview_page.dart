import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../shared/widgets/list_pagination.dart';
import 'admin_ui.dart';

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  int _ticketPage = 0;
  bool _grid = true;
  late Future<({int total, int active})> _accountCounts = _loadAccountCounts();

  Future<({int total, int active})> _loadAccountCounts() async {
    final auth = LocalAuth.instance;
    if (!auth.isCloudMode) {
      final accounts = auth.localAccounts;
      return (
        total: accounts.length,
        active: accounts.where((account) => !account.disabled).length,
      );
    }
    if (auth.role != AppRole.admin) return (total: 0, active: 0);
    final users = FirebaseFirestore.instance.collection('users');
    final results = await Future.wait([
      users.count().get(),
      users.where('disabled', isEqualTo: false).count().get(),
    ]);
    return (total: results[0].count ?? 0, active: results[1].count ?? 0);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      RentalPortfolio.instance,
      AdminStore.instance,
      LocalAuth.instance,
    ]),
    builder: (context, _) {
      final stores = RentalPortfolio.instance.stores;
      final admin = AdminStore.instance;
      final pending = stores
          .where(
            (store) =>
                !admin.isVerified(store.property.id) &&
                store.property.verificationSubmittedAt != null,
          )
          .length;
      final verified = stores
          .where((store) => admin.isVerified(store.property.id))
          .length;
      final tickets = admin.tickets;
      final lastPage = ListPagination.lastPage(tickets.length, 10);
      if (_ticketPage > lastPage) _ticketPage = lastPage;
      final visibleTickets = tickets.skip(_ticketPage * 10).take(10).toList();

      return AdminFrame(
        title: 'Tổng quan hệ thống',
        subtitle: 'Theo dõi hoạt động nhà trọ, tài khoản và yêu cầu hỗ trợ.',
        children: [
          const AdminSyncBar(),
          _welcomeBanner(context),
          const SizedBox(height: 18),
          FutureBuilder<({int total, int active})>(
            future: _accountCounts,
            builder: (context, snapshot) {
              final counts = snapshot.data;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 880
                      ? 3
                      : constraints.maxWidth >= 540
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) / columns;
                  final metrics = <Widget>[
                    _MetricCard(
                      width: width,
                      title: 'Nhà trọ đã đăng ký',
                      value: '${stores.length}',
                      detail: 'Tổng số cơ sở trên nền tảng',
                      icon: Icons.apartment_rounded,
                      color: adminBlue,
                    ),
                    _MetricCard(
                      width: width,
                      title: 'Lượt tải ứng dụng',
                      value: '—',
                      detail: 'Chưa có dữ liệu phân tích lượt tải',
                      icon: Icons.download_rounded,
                      color: adminPurple,
                    ),
                    _MetricCard(
                      width: width,
                      title: 'Tài khoản hoạt động',
                      value: snapshot.connectionState == ConnectionState.waiting
                          ? '…'
                          : snapshot.hasError
                          ? '—'
                          : '${counts?.active ?? 0}',
                      detail: 'Tài khoản chưa bị khóa',
                      icon: Icons.people_alt_rounded,
                      color: adminTeal,
                    ),
                    _MetricCard(
                      width: width,
                      title: 'Chờ duyệt xác minh',
                      value: '$pending',
                      detail: 'Hồ sơ chưa được duyệt',
                      icon: Icons.pending_actions_rounded,
                      color: adminGold,
                      onTap: () => RoleLayoutShell.navigateTo(
                        context,
                        'property_verification',
                      ),
                    ),
                    _MetricCard(
                      width: width,
                      title: 'Đã xác minh',
                      value: '$verified',
                      detail: 'Nhà trọ đã hoàn tất kiểm duyệt',
                      icon: Icons.verified_rounded,
                      color: adminGreen,
                      onTap: () => RoleLayoutShell.navigateTo(
                        context,
                        'property_verification',
                      ),
                    ),
                    _MetricCard(
                      width: width,
                      title: 'Tổng tài khoản',
                      value: snapshot.connectionState == ConnectionState.waiting
                          ? '…'
                          : snapshot.hasError
                          ? '—'
                          : '${counts?.total ?? 0}',
                      detail: 'Quản trị viên, chủ trọ và người thuê',
                      icon: Icons.manage_accounts_rounded,
                      color: adminInk,
                      onTap: () => RoleLayoutShell.navigateTo(context, 'users'),
                    ),
                  ];
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: metrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 168,
                    ),
                    itemBuilder: (context, index) => metrics[index],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Expanded(
                child: AdminSection(
                  'Yêu cầu hỗ trợ',
                  caption: 'Tối đa 10 yêu cầu trên mỗi trang',
                ),
              ),
              IconButton(
                tooltip: 'Hiển thị dạng danh sách',
                onPressed: () => setState(() => _grid = false),
                isSelected: !_grid,
                icon: const Icon(Icons.view_list_rounded),
              ),
              IconButton(
                tooltip: 'Hiển thị dạng lưới',
                onPressed: () => setState(() => _grid = true),
                isSelected: _grid,
                icon: const Icon(Icons.grid_view_rounded),
              ),
            ],
          ),
          if (tickets.isEmpty)
            const AdminPanel(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Chưa có yêu cầu hỗ trợ nào.')),
              ),
            )
          else if (_grid)
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 980
                    ? 3
                    : constraints.maxWidth >= 620
                    ? 2
                    : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleTickets.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 154,
                  ),
                  itemBuilder: (context, index) =>
                      _TicketCard(ticket: visibleTickets[index]),
                );
              },
            )
          else
            Column(
              children: [
                for (final ticket in visibleTickets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TicketCard(ticket: ticket, compact: true),
                  ),
              ],
            ),
          ListPagination(
            total: tickets.length,
            page: _ticketPage,
            pageSize: 10,
            onChanged: (page) => setState(() => _ticketPage = page),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => RoleLayoutShell.navigateTo(context, 'support'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Mở trung tâm hỗ trợ'),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lượt tải và số người đang online chưa được ứng dụng ghi nhận. Chỉ số tài khoản hoạt động hiện phản ánh các tài khoản chưa bị khóa.',
            style: TextStyle(color: adminMuted, fontSize: 12, height: 1.45),
          ),
        ],
      );
    },
  );

  Widget _welcomeBanner(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B192C), Color(0xFF123A66), Color(0xFF5133A5)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x241D4ED8),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trung tâm điều hành',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Xin chào ${LocalAuth.instance.session?.displayName.isNotEmpty == true ? LocalAuth.instance.session!.displayName : 'Quản trị viên'} · ${MaterialLocalizations.of(context).formatMediumDate(DateTime.now())}',
                style: const TextStyle(color: Color(0xFFD7E7FF), fontSize: 13),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFFD7C7FF),
          size: 34,
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final double width;
  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 142),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: adminLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_outward_rounded,
                      color: adminMuted,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(
                  color: adminInk,
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: adminInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(
                  color: adminMuted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, this.compact = false});
  final SupportTicket ticket;
  final bool compact;

  @override
  Widget build(BuildContext context) => AdminPanel(
    padding: EdgeInsets.all(compact ? 14 : 17),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ticket.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: adminInk,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AdminStatus(
              ticket.closed ? 'Đã xử lý' : 'Đang mở',
              color: ticket.closed ? adminGreen : adminGold,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          ticket.content,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: adminMuted, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 9),
        Text(
          '${ticket.role.label} · ${MaterialLocalizations.of(context).formatShortDate(ticket.createdAt)}',
          style: const TextStyle(color: adminMuted, fontSize: 11),
        ),
      ],
    ),
  );
}
