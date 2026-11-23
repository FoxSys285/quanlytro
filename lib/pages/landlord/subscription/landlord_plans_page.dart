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
            return StreamBuilder<List<LandlordPlanOrder>>(
              stream: _orders,
              builder: (context, snapshot) {
                final orders = snapshot.data ?? const <LandlordPlanOrder>[];
                final current = LandlordSubscriptionService.activeOrder(orders);
                final openOrders = orders
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
                              : () => _startOrder(
                                  session!,
                                  plan,
                                  orders,
                                  context,
                                ),
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
                          ? () =>
                                _continueOrder(session, order, orders, context)
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
    List<LandlordPlanOrder> orders,
    BuildContext context,
  ) async {
    await _openPaymentFlow(
      session,
      plan: plan,
      orders: orders,
      context: context,
    );
  }

  Future<void> _continueOrder(
    FirebaseAccountSession session,
    LandlordPlanOrder order,
    List<LandlordPlanOrder> orders,
    BuildContext context,
  ) async {
    await _openPaymentFlow(
      session,
      order: order,
      orders: orders,
      context: context,
    );
  }

  Future<void> _openPaymentFlow(
    FirebaseAccountSession session, {
    LandlordPlan? plan,
    LandlordPlanOrder? order,
    required List<LandlordPlanOrder> orders,
    required BuildContext context,
  }) async {
    final period = _periodFor(orders, order: order);
    final planId = order?.planId ?? plan?.id;
    final isRenewal =
        LandlordSubscriptionService.activeOrder(orders)?.planId == planId;
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (_) => _SubscriptionPeriodDialog(
        title: isRenewal ? 'Gia hạn gói' : 'Đăng ký gói',
        planName: order?.planName ?? plan!.name,
        amount: order?.amount ?? plan!.monthlyPrice,
        startAt: period.startAt,
        endAt: period.endAt,
      ),
    );
    if (shouldContinue != true || !context.mounted) return;

    try {
      final prepared = await _subscriptions.prepareSimulatedPayment(
        session: session,
        plan: plan,
        orderId: order?.id,
      );
      if (!context.mounted) return;
      final completed = await showDialog<LandlordPlanOrder>(
        context: context,
        builder: (_) => _FakePaymentQrDialog(session: session, order: prepared),
      );
      if (completed != null && context.mounted) {
        _message(
          context,
          'Đã hoàn tất thanh toán giả lập gói ${completed.planName}.',
        );
      }
    } catch (error) {
      if (context.mounted) _message(context, _paymentError(error));
    }
  }

  _PlanPeriod _periodFor(
    Iterable<LandlordPlanOrder> orders, {
    LandlordPlanOrder? order,
  }) {
    if (order?.startsAt != null && order?.expiresAt != null) {
      return _PlanPeriod(order!.startsAt!, order.expiresAt!);
    }
    var startAt = DateTime.now();
    for (final existing in orders) {
      final expiry = existing.expiresAt;
      if (existing.status == 'approved' &&
          expiry != null &&
          expiry.isAfter(startAt)) {
        startAt = expiry.toLocal();
      }
    }
    return _PlanPeriod(startAt, startAt.add(const Duration(days: 30)));
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
          if (order.startsAt != null && order.expiresAt != null)
            Text(
              'Thời hạn: ${_dateTimeLabel(order.startsAt!)} → ${_dateTimeLabel(order.expiresAt!)}',
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

class _PlanPeriod {
  const _PlanPeriod(this.startAt, this.endAt);

  final DateTime startAt;
  final DateTime endAt;
}

class _SubscriptionPeriodDialog extends StatelessWidget {
  const _SubscriptionPeriodDialog({
    required this.title,
    required this.planName,
    required this.amount,
    required this.startAt,
    required this.endAt,
  });

  final String title;
  final String planName;
  final int amount;
  final DateTime startAt;
  final DateTime endAt;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('$title $planName'),
    content: SizedBox(
      width: (MediaQuery.sizeOf(context).width - 88)
          .clamp(280.0, 460.0)
          .toDouble(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Giá gói: ${_money(amount)} · Thời hạn: 30 ngày',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PeriodPoint(
                  label: 'Mốc bắt đầu',
                  value: _dateTimeLabel(startAt),
                  icon: Icons.play_arrow_rounded,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF7046D3),
                ),
              ),
              Expanded(
                child: _PeriodPoint(
                  label: 'Mốc kết thúc',
                  value: _dateTimeLabel(endAt),
                  icon: Icons.flag_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Bấm tiếp tục để xem mã QR giả lập. Gói hiện tại còn hạn thì gói mới sẽ bắt đầu sau ngày hết hạn.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Để sau'),
      ),
      FilledButton.icon(
        onPressed: () => Navigator.pop(context, true),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Tiếp tục'),
      ),
    ],
  );
}

class _PeriodPoint extends StatelessWidget {
  const _PeriodPoint({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF7046D3).withValues(alpha: .07),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: const Color(0xFF7046D3)),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _FakePaymentQrDialog extends StatefulWidget {
  const _FakePaymentQrDialog({required this.session, required this.order});

  final FirebaseAccountSession session;
  final LandlordPlanOrder order;

  @override
  State<_FakePaymentQrDialog> createState() => _FakePaymentQrDialogState();
}

class _FakePaymentQrDialogState extends State<_FakePaymentQrDialog> {
  bool _saving = false;
  String? _error;
  LandlordPlanOrder? _completed;

  Future<void> _simulatePayment() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final completed = await LandlordSubscriptionService.instance
          .simulatePayment(session: widget.session, orderId: widget.order.id);
      if (mounted) setState(() => _completed = completed);
    } catch (error) {
      if (mounted) setState(() => _error = _paymentError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completed;
    final contentWidth = (MediaQuery.sizeOf(context).width - 88)
        .clamp(280.0, 460.0)
        .toDouble();
    return AlertDialog(
      title: Text(
        completed == null
            ? 'Thanh toán gói ${widget.order.planName}'
            : 'Thanh toán hoàn tất',
      ),
      content: SizedBox(
        width: contentWidth,
        child: completed == null
            ? _paymentContent()
            : _completionContent(completed),
      ),
      actions: completed == null
          ? [
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Để sau'),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _simulatePayment,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline_rounded),
                label: Text(_saving ? 'Đang xử lý...' : 'Giả lập thanh toán'),
              ),
            ]
          : [
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, completed),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Hoàn tất'),
              ),
            ],
    );
  }

  Widget _paymentContent() => SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _FakePaymentQr(seed: widget.order.paymentReference)),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'QR GIẢ LẬP · KHÔNG DÙNG ĐỂ CHUYỂN TIỀN',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB45309),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Gói ${widget.order.planName} · ${_money(widget.order.amount)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text('Mã mô phỏng: ${widget.order.paymentReference}'),
        if (widget.order.startsAt != null &&
            widget.order.expiresAt != null) ...[
          const SizedBox(height: 5),
          Text(
            'Thời hạn: ${_dateTimeLabel(widget.order.startsAt!)} → ${_dateTimeLabel(widget.order.expiresAt!)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
        const SizedBox(height: 9),
        const Text(
          'Nhấn “Giả lập thanh toán” để hoàn tất đăng ký. Không cần quét QR; không phát sinh giao dịch thật.',
          style: TextStyle(fontSize: 12, height: 1.45),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ],
    ),
  );

  Widget _completionContent(LandlordPlanOrder order) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(
        Icons.check_circle_rounded,
        size: 64,
        color: Color(0xFF15803D),
      ),
      const SizedBox(height: 10),
      const Text(
        'Gói dịch vụ đã được kích hoạt.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 12),
      Text('Gói ${order.planName} · ${_money(order.amount)}'),
      if (order.startsAt != null && order.expiresAt != null) ...[
        const SizedBox(height: 5),
        Text(
          'Thời hạn: ${_dateTimeLabel(order.startsAt!)} → ${_dateTimeLabel(order.expiresAt!)}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
      const SizedBox(height: 10),
      const Text(
        'Đây là kết quả thanh toán giả lập cho đồ án. Không có khoản tiền nào được thu.',
        style: TextStyle(fontSize: 12, height: 1.45),
      ),
    ],
  );
}

class _FakePaymentQr extends StatelessWidget {
  const _FakePaymentQr({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFD9DEE7)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: CustomPaint(
      size: const Size.square(190),
      painter: _FakeQrPainter(seed),
    ),
  );
}

class _FakeQrPainter extends CustomPainter {
  _FakeQrPainter(this.seed);

  static const _size = 29;
  final String seed;

  bool _finderDark(int x, int y, int left, int top) {
    final localX = x - left;
    final localY = y - top;
    if (localX < 0 || localX >= 7 || localY < 0 || localY >= 7) return false;
    return localX == 0 ||
        localX == 6 ||
        localY == 0 ||
        localY == 6 ||
        (localX >= 2 && localX <= 4 && localY >= 2 && localY <= 4);
  }

  bool _darkAt(int x, int y, int seedHash) {
    final finders = <(int, int)>[(0, 0), (_size - 7, 0), (0, _size - 7)];
    for (final (left, top) in finders) {
      final inReserved =
          x >= left - (left == 0 ? 0 : 1) &&
          x <= left + 7 &&
          y >= top - (top == 0 ? 0 : 1) &&
          y <= top + 7;
      if (inReserved) return _finderDark(x, y, left, top);
    }

    var value = seedHash ^ ((x + 1) * 0x45d9f3b) ^ ((y + 1) * 0x119de1f3);
    value = (value ^ (value >> 16)) * 0x45d9f3b;
    value = (value ^ (value >> 16)) * 0x45d9f3b;
    value ^= value >> 16;
    return value.isOdd;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final side = size.width < size.height ? size.width : size.height;
    final left = (size.width - side) / 2;
    final top = (size.height - side) / 2;
    final cell = side / _size;
    var seedHash = 0;
    for (final codeUnit in seed.codeUnits) {
      seedHash = (seedHash * 31 + codeUnit) & 0x7fffffff;
    }
    final paint = Paint()..color = const Color(0xFF101827);
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        if (!_darkAt(x, y, seedHash)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            left + x * cell,
            top + y * cell,
            cell + .15,
            cell + .15,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FakeQrPainter oldDelegate) =>
      oldDelegate.seed != seed;
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

String _paymentError(Object error) {
  final message = '$error';
  if (message.contains('Thao tác đăng ký gói không hợp lệ') ||
      message.contains('Không chuẩn bị được thanh toán giả lập') ||
      message.contains('Không hoàn tất được thanh toán giả lập')) {
    return 'Backend thanh toán chưa được cập nhật. Cần áp dụng migration Supabase mới và triển khai lại subscription-api.';
  }
  return message;
}

String _dateLabel(DateTime value) =>
    '${value.toLocal().day.toString().padLeft(2, '0')}/'
    '${value.toLocal().month.toString().padLeft(2, '0')}/${value.toLocal().year}';

String _dateTimeLabel(DateTime value) {
  final local = value.toLocal();
  return '${_dateLabel(local)} ${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
