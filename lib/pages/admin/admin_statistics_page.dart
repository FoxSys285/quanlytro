import 'package:flutter/material.dart';

import '../../data/firebase_account_gateway.dart';
import '../../data/landlord_plans.dart';
import '../../data/landlord_subscription_service.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import 'admin_ui.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  late final _subscriptions = LandlordSubscriptionService.instance;
  late final _orders = _subscriptions.watchAllOrders();

  @override
  Widget build(BuildContext context) {
    final session = LocalAuth.instance.session;
    if (session == null || session.role != AppRole.admin) {
      return AdminFrame(
        title: 'Gói dịch vụ & thanh toán',
        subtitle: 'Theo dõi gói dịch vụ và các giao dịch giả lập.',
        children: const [
          AdminPanel(
            child: Text(
              'Đăng nhập bằng tài khoản quản trị Firebase để tiếp tục.',
            ),
          ),
        ],
      );
    }

    return StreamBuilder<List<LandlordPlanOrder>>(
      stream: _orders,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AdminFrame(
            title: 'Gói dịch vụ & thanh toán',
            subtitle: 'Không tải được dữ liệu gói dịch vụ.',
            children: [AdminPanel(child: Text('${snapshot.error}'))],
          );
        }
        final orders = snapshot.data ?? const <LandlordPlanOrder>[];
        final paid = orders.where((order) => order.status == 'approved');
        final revenue = paid.fold<int>(0, (sum, order) => sum + order.amount);
        final submitted = orders
            .where((order) => order.status == 'submitted')
            .length;
        final waitingPayment = orders
            .where((order) => order.status == 'awaiting_payment')
            .length;
        final packageCounts = <String, int>{};
        for (final order in paid) {
          packageCounts.update(
            order.planName,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
        final mostPopular = packageCounts.entries.isEmpty
            ? 'Chưa có'
            : packageCounts.entries
                  .reduce((a, b) => a.value >= b.value ? a : b)
                  .key;

        return AdminFrame(
          title: 'Gói dịch vụ & thanh toán',
          subtitle: 'Theo dõi các giao dịch giả lập và thời hạn gói dịch vụ.',
          children: [
            const AdminSyncBar(),
            AdminBanner(
              title: 'Chế độ thanh toán giả lập',
              subtitle: 'Không kết nối ngân hàng hoặc SePay. Xác nhận giả lập sẽ kích hoạt gói trong 30 ngày.',
              icon: Icons.science_outlined,
            ),
            const SizedBox(height: 14),
            const AdminPanel(
              child: Text(
                'Các đơn mới được ghi nhận là giao dịch mô phỏng; không thu tiền thật. Thao tác này phục vụ trình bày đồ án.',
              ),
            ),
            const SizedBox(height: 18),
            AdminSection(
              'Danh mục gói',
              caption: '${LandlordPlan.all.length} gói đang áp dụng',
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 2 : 1;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final plan in LandlordPlan.all)
                      SizedBox(
                        width:
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns,
                        child: _PlanSummaryCard(plan: plan),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 680 ? 3 : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryCard(
                      width: width,
                      title: 'Giá trị đơn đã duyệt',
                      value: _money(revenue),
                      icon: Icons.payments_rounded,
                      color: adminBlue,
                    ),
                    _SummaryCard(
                      width: width,
                      title: 'Chờ xử lý',
                      value: '$submitted yêu cầu',
                      icon: Icons.receipt_long_rounded,
                      color: adminPurple,
                    ),
                    _SummaryCard(
                      width: width,
                      title: 'Chưa hoàn tất',
                      value: '$waitingPayment yêu cầu',
                      icon: Icons.hourglass_top_rounded,
                      color: adminTeal,
                    ),
                    _SummaryCard(
                      width: width,
                      title: 'Gói được duyệt nhiều nhất',
                      value: mostPopular,
                      icon: Icons.workspace_premium_rounded,
                      color: adminGold,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            AdminSection(
              'Đơn đăng ký cần xử lý',
              caption: '$submitted yêu cầu đang chờ admin xem xét',
            ),
            if (!snapshot.hasData)
              const AdminPanel(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (submitted == 0)
              const AdminPanel(
                child: Text('Chưa có yêu cầu đăng ký cần xử lý.'),
              )
            else
              for (final order in orders.where(
                (order) => order.status == 'submitted',
              ))
                _OrderCard(
                  order: order,
                  onReview: (approve) =>
                      _review(context, session, order, approve),
                ),
            const SizedBox(height: 22),
            AdminSection(
              'Lịch sử đơn gói',
              caption: '${orders.length} yêu cầu đã tạo',
            ),
            if (orders.isEmpty)
              const AdminPanel(child: Text('Chưa có yêu cầu đăng ký gói.'))
            else
              for (final order in orders.take(40)) _OrderCard(order: order),
          ],
        );
      },
    );
  }

  Future<void> _review(
    BuildContext context,
    FirebaseAccountSession session,
    LandlordPlanOrder order,
    bool approve,
  ) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewDialog(order: order, approve: approve),
    );
    if (note == null || !context.mounted) return;
    try {
      await _subscriptions.reviewOrder(
        order: order,
        adminUid: session.uid,
        approve: approve,
        note: note,
      );
      if (context.mounted) {
        _message(
          context,
          approve
              ? 'Đã kích hoạt gói ${order.planName}.'
              : 'Đã từ chối yêu cầu đăng ký.',
        );
      }
    } catch (error) {
      if (context.mounted) _message(context, '$error', error: true);
    }
  }

  void _message(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? adminOrange : null,
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.order, required this.approve});
  final LandlordPlanOrder order;
  final bool approve;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = (MediaQuery.sizeOf(context).width - 88)
        .clamp(280.0, 420.0)
        .toDouble();
    return AlertDialog(
      scrollable: true,
      title: Text(widget.approve ? 'Duyệt đăng ký gói' : 'Từ chối đăng ký'),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.order.landlordName} · ${widget.order.planName} · ${_money(widget.order.amount)}',
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.order.isSimulated ? 'Mã giao dịch giả lập' : 'Mã chuyển khoản'}: ${widget.order.paymentReference}',
            ),
            Text(
              '${widget.order.isSimulated ? 'Trạng thái mô phỏng' : 'Thông tin chủ trọ gửi'}: ${widget.order.paymentNote}',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: widget.approve
                    ? 'Ghi chú đối soát (không bắt buộc)'
                    : 'Lý do từ chối',
                border: const OutlineInputBorder(),
              ),
            ),
            if (widget.approve) ...[
              const SizedBox(height: 9),
              const Text(
                'Gói có hiệu lực 30 ngày. Nếu đang còn gói đã duyệt, gói mới sẽ bắt đầu sau ngày hết hạn hiện tại.',
                style: TextStyle(color: adminMuted, fontSize: 12, height: 1.4),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quay lại'),
        ),
        FilledButton(
          style: widget.approve
              ? null
              : FilledButton.styleFrom(backgroundColor: adminOrange),
          onPressed: () {
            if (!widget.approve && _note.text.trim().isEmpty) return;
            Navigator.pop(context, _note.text.trim());
          },
          child: Text(widget.approve ? 'Xác nhận và kích hoạt' : 'Từ chối'),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, this.onReview});
  final LandlordPlanOrder order;
  final ValueChanged<bool>? onReview;

  @override
  Widget build(BuildContext context) {
    final (status, color) = switch (order.status) {
      'awaiting_payment' => ('Chờ thanh toán', adminGold),
      'submitted' => ('Chờ đối soát', adminBlue),
      'approved' =>
        order.isActive
            ? ('Đang hoạt động', adminGreen)
            : ('Đã duyệt / hết hạn', adminTeal),
      'rejected' => ('Đã từ chối', adminOrange),
      'cancelled' => ('Đã hủy', adminMuted),
      _ => ('Không xác định', adminMuted),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdminPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${order.planName} · ${_money(order.amount)}',
                    style: const TextStyle(
                      color: adminInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                AdminStatus(status, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 18,
              runSpacing: 6,
              children: [
                _SettingValue(label: 'Chủ trọ', value: order.landlordName),
                if (order.landlordEmail.isNotEmpty)
                  _SettingValue(label: 'Email', value: order.landlordEmail),
                _SettingValue(
                  label: order.isSimulated
                      ? 'Mã giao dịch giả lập'
                      : 'Mã chuyển khoản',
                  value: order.paymentReference,
                ),
                if (!order.isSimulated && order.paymentSettings != null)
                  _SettingValue(
                    label: 'Tài khoản nhận tại thời điểm tạo đơn',
                    value:
                        '${order.paymentSettings!.bankName} · ${order.paymentSettings!.accountNumber}',
                  ),
                _SettingValue(
                  label: 'Ngày tạo',
                  value: order.createdAt == null
                      ? '—'
                      : _dateLabel(order.createdAt!),
                ),
              ],
            ),
            if (order.paymentNote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '${order.isSimulated ? 'Trạng thái mô phỏng' : 'Xác nhận của chủ trọ'}: ${order.paymentNote}',
                style: const TextStyle(color: adminInk, fontSize: 12),
              ),
            ],
            if (order.startsAt != null && order.expiresAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Hiệu lực: ${_dateLabel(order.startsAt!)} – ${_dateLabel(order.expiresAt!)}',
                style: const TextStyle(color: adminMuted, fontSize: 12),
              ),
            ],
            if (order.adminNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Ghi chú admin: ${order.adminNote}',
                style: const TextStyle(color: adminMuted, fontSize: 12),
              ),
            ],
            if (onReview != null) ...[
              const Divider(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => onReview!(false),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Từ chối'),
                  ),
                  FilledButton.icon(
                    onPressed: () => onReview!(true),
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Xác nhận và kích hoạt'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingValue extends StatelessWidget {
  const _SettingValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 300),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: adminMuted, fontSize: 11)),
        Text(
          value,
          style: const TextStyle(
            color: adminInk,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({required this.plan});
  final LandlordPlan plan;

  @override
  Widget build(BuildContext context) {
    final color = plan.id == 'plus' ? adminPurple : adminBlue;
    return AdminPanel(
      backgroundColor: Color.alphaBlend(
        color.withValues(alpha: .045),
        Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: adminInk,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            plan.monthlyPriceLabel,
            style: TextStyle(
              color: Color.lerp(color, adminInk, .12),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.propertyLimitLabel} · ${plan.roomLimitLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: adminMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: AdminPanel(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: adminMuted, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: adminInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String _money(int amount) {
  final digits = amount.toString();
  final output = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) output.write('.');
    output.write(digits[i]);
  }
  return '${output.toString()} đ';
}

String _dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
