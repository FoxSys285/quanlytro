import 'package:flutter/material.dart';

import '../../../data/firebase_account_gateway.dart';
import '../../../data/landlord_plans.dart';
import '../../../data/landlord_subscription_service.dart';
import '../../../data/local_auth.dart';
import '../../../layouts/role_layout.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';

class LandlordPlansPage extends StatefulWidget {
  const LandlordPlansPage({super.key});

  @override
  State<LandlordPlansPage> createState() => _LandlordPlansPageState();
}

class _LandlordPlansPageState extends State<LandlordPlansPage> {
  late final _subscriptions = LandlordSubscriptionService.instance;
  Stream<List<LandlordPlanOrder>>? _orders;
  String? _ordersUid;

  @override
  Widget build(BuildContext context) {
    final session = LocalAuth.instance.session;
    if (session != null && _ordersUid != session.uid) {
      _ordersUid = session.uid;
      _orders = _subscriptions.watchLandlordOrders(session.uid);
    }

    return LandlordGlassPage(
      title: 'Gói quản lý nhà trọ',
      subtitle: 'Chọn gói phù hợp với quy mô nhà trọ bạn đang vận hành.',
      kicker: 'GÓI DỊCH VỤ CHỦ TRỌ',
      children: [
        if (session == null || session.role != AppRole.landlord)
          const _InfoCard(
            message: 'Đăng nhập bằng tài khoản chủ trọ Firebase để đăng ký và lưu gói dịch vụ.',
          )
        else
          StreamBuilder<List<LandlordPlanOrder>>(
            stream: _orders,
            builder: (context, orderSnapshot) {
              if (orderSnapshot.hasError) {
                return _InfoCard(
                  message:
                      'Chưa tải được trạng thái gói: ${orderSnapshot.error}',
                  error: true,
                );
              }
              if (!orderSnapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _buildAccountPlans(context, orderSnapshot.data!);
            },
          ),
        const SizedBox(height: 20),
        LandlordGlassSection(
          title: 'Bảng giá',
          subtitle: 'Mỗi gói có giới hạn số nhà và số phòng riêng.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
            final orders = const <LandlordPlanOrder>[];
            return StreamBuilder<List<LandlordPlanOrder>>(
              stream: _orders,
              builder: (context, snapshot) {
                final current = LandlordSubscriptionService.activeOrder(
                  snapshot.data ?? orders,
                );
                final openOrders = (snapshot.data ?? orders)
                    .where((order) => order.isOpen)
                    .toList();
                final openOrder = openOrders.isEmpty ? null : openOrders.first;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final plan in LandlordPlan.all)
                      SizedBox(
                        width: width,
                        child: _PlanCard(
                          plan: plan,
                          current: current?.planId == plan.id,
                          openOrder: openOrder != null,
                          canRegister: session?.role == AppRole.landlord,
                          onRegister:
                              plan.id == 'free' ||
                                  openOrder != null ||
                                  session?.role != AppRole.landlord
                              ? null
                              : () => _startOrder(session!, plan, context),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        const _InfoCard(
          message: 'Chế độ thanh toán giả lập phục vụ báo cáo đồ án. Xác nhận để kích hoạt gói trong 30 ngày; không chuyển khoản và không phát sinh giao dịch tiền thật.',
        ),
        if (session != null && session.role == AppRole.landlord)
          StreamBuilder<List<LandlordPlanOrder>>(
            stream: _orders,
            builder: (context, snapshot) {
              final orders = snapshot.data ?? const <LandlordPlanOrder>[];
              if (orders.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  LandlordGlassSection(
                    title: 'Lịch sử đăng ký',
                    subtitle: 'Theo dõi trạng thái và thời hạn từng gói.',
                  ),
                  for (final order in orders.take(8))
                    _OrderCard(
                      order: order,
                      onContinue: order.isOpen
                          ? () => _continueOrder(session, order, context)
                          : null,
                      onCancel: order.status == 'awaiting_payment'
                          ? () => _cancelOrder(order, context)
                          : null,
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildAccountPlans(
    BuildContext context,
    List<LandlordPlanOrder> orders,
  ) {
    final active = LandlordSubscriptionService.activeOrder(orders);
    final plan = LandlordPlan.byId(active?.planId);
    final pendingOrders = orders.where((order) => order.isOpen).toList();
    final pending = pendingOrders.isEmpty ? null : pendingOrders.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LandlordGlassCard(
          tint: const Color(0xFF7046D3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFF7046D3),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gói hiện tại: ${plan.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${plan.monthlyPriceLabel} · ${plan.propertyLimitLabel} · ${plan.roomLimitLabel}',
                style: TextStyle(
                  color: LandlordPalette.of(context).muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              if (active?.expiresAt != null) ...[
                const SizedBox(height: 5),
                Text(
                  'Có hiệu lực đến ${_dateLabel(active!.expiresAt!)}',
                  style: TextStyle(
                    color: LandlordPalette.of(context).muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (pending != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _InfoCard(
              message:
                  'Bạn có yêu cầu ${pending.paymentReference} chưa hoàn tất. Mở lịch sử đăng ký bên dưới và chọn “Giả lập thanh toán” để hoàn tất.',
            ),
          ),
      ],
    );
  }

  Future<void> _startOrder(
    FirebaseAccountSession session,
    LandlordPlan plan,
    BuildContext context,
  ) async {
    await _openSimulation(session, plan: plan, context: context);
  }

  Future<void> _continueOrder(
    FirebaseAccountSession session,
    LandlordPlanOrder order,
    BuildContext context,
  ) async {
    await _openSimulation(session, order: order, context: context);
  }

  Future<void> _openSimulation(
    FirebaseAccountSession session, {
    LandlordPlan? plan,
    LandlordPlanOrder? order,
    required BuildContext context,
  }) async {
    final completed = await showDialog<LandlordPlanOrder>(
      context: context,
      builder: (_) =>
          _SimulatedPaymentDialog(session: session, plan: plan, order: order),
    );
    if (completed != null && context.mounted) {
      _message(
        context,
        'Đã giả lập thanh toán thành công cho gói ${completed.planName}.',
      );
    }
  }

  Future<void> _cancelOrder(
    LandlordPlanOrder order,
    BuildContext context,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy yêu cầu chưa thanh toán?'),
        content: Text(
          'Yêu cầu ${order.paymentReference} sẽ không còn giữ chỗ gói này. Bạn có thể đăng ký lại sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ yêu cầu'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy yêu cầu'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await _subscriptions.cancelUnpaidOrder(order.id);
      if (context.mounted) _message(context, 'Đã hủy yêu cầu đăng ký.');
    } catch (error) {
      if (context.mounted) _message(context, '$error');
    }
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.current,
    required this.openOrder,
    required this.canRegister,
    required this.onRegister,
  });

  final LandlordPlan plan;
  final bool current;
  final bool openOrder;
  final bool canRegister;
  final VoidCallback? onRegister;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final accent = plan.id == 'plus'
        ? const Color(0xFF7046D3)
        : const Color(0xFF087FC1);
    return LandlordGlassCard(
      tint: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (current)
                const Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('Đang dùng'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.monthlyPriceLabel,
            style: TextStyle(
              color: accent,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            plan.description,
            style: TextStyle(color: palette.muted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          _PlanFeature(
            icon: Icons.home_work_outlined,
            label: plan.propertyLimitLabel,
            accent: accent,
          ),
          const SizedBox(height: 10),
          _PlanFeature(
            icon: Icons.door_front_door_outlined,
            label: plan.roomLimitLabel,
            accent: accent,
          ),
          if (plan.id != 'free') ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRegister,
                icon: Icon(
                  current
                      ? Icons.autorenew_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  current
                      ? 'Gia hạn 30 ngày'
                      : openOrder
                      ? 'Đang có yêu cầu'
                      : 'Đăng ký gói',
                ),
              ),
            ),
            if (!canRegister)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Cần đăng nhập bằng tài khoản chủ trọ Firebase.',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: accent),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      const Icon(
        Icons.check_circle_rounded,
        size: 17,
        color: Color(0xFF0D9488),
      ),
    ],
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, this.onContinue, this.onCancel});

  final LandlordPlanOrder order;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: LandlordGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.planName} · ${_money(order.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(order: order),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${order.isSimulated ? 'Mã giao dịch giả lập' : 'Mã chuyển khoản'}: ${order.paymentReference}',
            style: const TextStyle(fontSize: 12),
          ),
          if (order.createdAt != null)
            Text(
              'Ngày tạo: ${_dateLabel(order.createdAt!)}',
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          if (order.expiresAt != null)
            Text(
              'Hiệu lực đến: ${_dateLabel(order.expiresAt!)}',
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          if (order.adminNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${order.isSimulated ? 'Ghi chú' : 'Phản hồi admin'}: ${order.adminNote}',
            ),
          ],
          if (onContinue != null) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                if (onCancel != null)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Hủy yêu cầu'),
                  ),
                OutlinedButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Giả lập thanh toán'),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _SimulatedPaymentDialog extends StatefulWidget {
  const _SimulatedPaymentDialog({required this.session, this.plan, this.order});

  final FirebaseAccountSession session;
  final LandlordPlan? plan;
  final LandlordPlanOrder? order;

  @override
  State<_SimulatedPaymentDialog> createState() =>
      _SimulatedPaymentDialogState();
}

class _SimulatedPaymentDialogState extends State<_SimulatedPaymentDialog> {
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final order = await LandlordSubscriptionService.instance.simulatePayment(
        session: widget.session,
        plan: widget.plan,
        orderId: widget.order?.id,
      );
      if (mounted) Navigator.pop(context, order);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planName = widget.order?.planName ?? widget.plan!.name;
    final amount = widget.order?.amount ?? widget.plan!.monthlyPrice;
    return AlertDialog(
      title: Text('Giả lập thanh toán gói $planName'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF7046D3).withValues(alpha: .08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.play_circle_outline_rounded,
                    color: Color(0xFF7046D3),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mô phỏng thanh toán gói $planName trong 30 ngày.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Giá gói: ${_money(amount)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Khi xác nhận, hệ thống sẽ ghi nhận giao dịch giả lập và kích hoạt gói. Không chuyển khoản; thao tác này không thu tiền thật.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Quay lại'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Xác nhận giả lập'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.order});
  final LandlordPlanOrder order;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (order.status) {
      'awaiting_payment' => ('Chờ thanh toán', const Color(0xFFB45309)),
      'submitted' => ('Chờ đối soát', const Color(0xFF2563EB)),
      'approved' =>
        order.isActive
            ? ('Đang hoạt động', const Color(0xFF15803D))
            : ('Đã duyệt', const Color(0xFF15803D)),
      'rejected' => ('Từ chối', const Color(0xFFB91C1C)),
      'cancelled' => ('Đã hủy', Colors.blueGrey),
      _ => ('Đã hết hạn', Colors.blueGrey),
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: .1),
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message, this.error = false});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => LandlordGlassCard(
    tint: error ? const Color(0xFFB45309) : const Color(0xFF168FC2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          error ? Icons.info_outline_rounded : Icons.science_outlined,
          color: error ? const Color(0xFFB45309) : const Color(0xFF168FC2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: LandlordPalette.of(context).muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
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
