import 'package:flutter/material.dart';

import '../../../landlord/finance/landlord_finance_models.dart';
import '../../../landlord/landlord_demo_store.dart';
import '../../../shared/announcements/announcement_store.dart';
import '../../../shared/media/room_photo.dart';
import '../../../shared/media/room_photo_gallery.dart';
import '../../../shared/rental/tenant_session.dart';
import '../../announcements/tenant_announcements_page.dart';
import '../../tenant_detail_ui.dart';
import '../../tenant_ui.dart';

const invoiceMint = Color(0xFFF0FAF5);

class TenantInvoiceNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  const TenantInvoiceNavigationBar({
    super.key,
    required this.onBack,
    this.onNotifications,
    this.store,
    this.tenantId = TenantSession.tenantId,
  });
  final VoidCallback onBack;
  final VoidCallback? onNotifications;
  final LandlordDemoStore? store;
  final String tenantId;
  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final notices = AnnouncementStore.forRental(
      store ?? LandlordDemoStore.instance,
    );
    return AppBar(
      backgroundColor: invoiceMint,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 60,
      titleSpacing: 0,
      leadingWidth: 54,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
        child: IconButton.filledTonal(
          onPressed: onBack,
          tooltip: 'Quay lại',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: tenantInk,
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        ),
      ),
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Hóa đơn và Thanh toán',
          style: TextStyle(
            color: tenantInk,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 9, 12, 9),
          child: ListenableBuilder(
            listenable: notices,
            builder: (context, _) {
              final unread = notices
                  .forTenant(tenantId)
                  .any((item) => !notices.isRead(item.id, tenantId));
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Thông báo thanh toán',
                    onPressed:
                        onNotifications ??
                        () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => TenantSubpageScaffold(
                              title: 'Thông báo',
                              showNotifications: false,
                              child: TenantAnnouncementsPage(
                                store: notices,
                                tenantId: tenantId,
                              ),
                            ),
                          ),
                        ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: tenantInk,
                    ),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 25,
                    ),
                  ),
                  if (unread)
                    Positioned(
                      right: 3,
                      top: 2,
                      child: Container(
                        key: const ValueKey('invoice-notification-dot'),
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6373E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class TenantInvoiceHero extends StatelessWidget {
  const TenantInvoiceHero({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: constraints.maxWidth < 360 ? 148 : 132,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/tenant_invoices_hero.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF4FBF7),
                  Color(0xE6F4FBF7),
                  Color(0x00F4FBF7),
                ],
                stops: [0, 0.40, 0.83],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 14, 19),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: constraints.maxWidth < 600
                    ? constraints.maxWidth * 0.59
                    : 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Thanh toán dễ dàng\nQuản lý minh bạch',
                        style: TextStyle(
                          color: Color(0xFF073C25),
                          fontSize: 20,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Hóa đơn rõ ràng, thanh toán nhanh chóng và an toàn',
                      style: TextStyle(
                        color: Color(0xFF454D64),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class TenantCurrentInvoiceCard extends StatelessWidget {
  const TenantCurrentInvoiceCard({
    super.key,
    required this.invoice,
    required this.store,
    required this.pending,
    required this.onPay,
  });
  final LandlordInvoice invoice;
  final LandlordDemoStore store;
  final bool pending;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final room = store.roomByCode(invoice.room);
    final types = store.roomTypes.where((type) => type.id == room?.roomTypeId);
    final photos = types.isEmpty ? const <RoomPhoto>[] : types.first.photos;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D233D30),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 9),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 9,
              runSpacing: 10,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_rounded,
                      color: Color(0xFF00A44B),
                      size: 26,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Hóa đơn hiện tại',
                        style: TextStyle(
                          color: tenantInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F6E9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: tenantGreenDark,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Hạn thanh toán: ${landlordDate(invoice.dueDate)}',
                          style: const TextStyle(
                            color: tenantGreenDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDF0F2)),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 8, 13, 8),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth * 0.32).clamp(85.0, 190.0),
                        height: 64,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: photos.isEmpty
                              ? const RoomPhotoPlaceholder()
                              : RoomPhotoImage(
                                  photo: photos.first,
                                  label: 'Ảnh phòng ${invoice.room}',
                                ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phòng ${invoice.room}, ${store.property.name}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: tenantInk,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFF078C71),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    store.property.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: tenantMuted,
                                      fontSize: 10.5,
                                      height: 1.4,
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(height: 1, color: Color(0xFFEDF0F2)),
                ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _metric(
                          Icons.payments_rounded,
                          'Số tiền thanh toán',
                          formatTenantMoney(invoice.remaining)
                              .replaceAll(' đ', 'đ'),
                          true,
                        ),
                      ),
                      const VerticalDivider(
                        width: 22,
                        color: Color(0xFFE2E7EA),
                      ),
                      Expanded(
                        child: _metric(
                          Icons.calendar_month_rounded,
                          'Kỳ thanh toán',
                          landlordMonth(invoice.period),
                          false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: FilledButton(
                    key: const ValueKey('invoice-pay-now'),
                    onPressed: pending ? null : onPay,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF009D42),
                      disabledBackgroundColor: const Color(0xFFE2F2E8),
                      disabledForegroundColor: tenantGreenDark,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          pending
                              ? Icons.hourglass_top_rounded
                              : Icons.credit_card_rounded,
                          size: 23,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            pending ? 'Đang chờ xác nhận' : 'Thanh toán ngay',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!pending) ...[
                          const SizedBox(width: 9),
                          const Icon(Icons.arrow_forward_rounded, size: 21),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value, bool money) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFF008C49), size: 23),
      const SizedBox(width: 7),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: tenantMuted,
                fontSize: 10,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: money ? const Color(0xFF008B3F) : tenantInk,
                  fontSize: money ? 19 : 15,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class TenantInvoiceQuickActions extends StatelessWidget {
  const TenantInvoiceQuickActions({
    super.key,
    this.onDetails,
    required this.onMethods,
    required this.onHistory,
    required this.onSupport,
  });
  final VoidCallback? onDetails;
  final VoidCallback onMethods;
  final VoidCallback onHistory;
  final VoidCallback onSupport;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _tile('Xem chi tiết\nhóa đơn', Icons.description_rounded, onDetails),
      const SizedBox(width: 9),
      _tile('Phương thức\nthanh toán', Icons.payments_rounded, onMethods),
      const SizedBox(width: 9),
      _tile('Lịch sử\nthanh toán', Icons.work_history_rounded, onHistory),
      const SizedBox(width: 9),
      _tile('Hỗ trợ\nthanh toán', Icons.headset_mic_rounded, onSupport),
    ],
  );

  Widget _tile(String label, IconData icon, VoidCallback? onTap) => Expanded(
    child: Semantics(
      button: true,
      enabled: onTap != null,
      child: Material(
        color: invoiceMint,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: onTap == null
                        ? tenantMuted
                        : const Color(0xFF008D67),
                    size: 25,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: tenantInk,
                            fontSize: 10.5,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class TenantInvoiceTransaction {
  const TenantInvoiceTransaction({
    required this.invoiceId,
    required this.amount,
    required this.date,
    required this.dateLabel,
    required this.status,
    required this.color,
    required this.icon,
    this.approved = false,
  });
  final String invoiceId;
  final int amount;
  final DateTime date;
  final String dateLabel;
  final String status;
  final Color color;
  final IconData icon;
  final bool approved;
}

List<TenantInvoiceTransaction> tenantInvoiceTransactions(
  List<LandlordInvoice> invoices,
  List<LandlordPayment> payments,
) {
  final items = payments.map((payment) {
    final (label, color, icon) = switch (payment.status) {
      LandlordPaymentStatus.approved => (
        'Thành công',
        const Color(0xFF009C44),
        Icons.check_circle_rounded,
      ),
      LandlordPaymentStatus.pending => (
        'Chờ xác nhận',
        const Color(0xFFAA791D),
        Icons.schedule_rounded,
      ),
      LandlordPaymentStatus.rejected => (
        'Bị từ chối',
        const Color(0xFFCF4A4A),
        Icons.cancel_rounded,
      ),
    };
    final at = payment.paidAt;
    return TenantInvoiceTransaction(
      invoiceId: payment.invoiceId,
      amount: payment.status == LandlordPaymentStatus.approved
          ? payment.approvedAmount ?? payment.reportedAmount
          : payment.reportedAmount,
      date: at,
      dateLabel:
          '${landlordDate(at)} • ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
      status: label,
      color: color,
      icon: icon,
      approved: payment.status == LandlordPaymentStatus.approved,
    );
  }).toList();
  // Older imported invoices may have a confirmed balance without transaction rows.
  // Show their confirmed amount with the billing period, without inventing a date.
  for (final invoice in invoices.where(
    (invoice) =>
        !invoice.cancelled &&
        invoice.paidAmount > 0 &&
        !payments.any((payment) => payment.invoiceId == invoice.id),
  )) {
    items.add(
      TenantInvoiceTransaction(
        invoiceId: invoice.id,
        amount: invoice.paidAmount,
        date: invoice.period,
        dateLabel: 'Kỳ ${landlordMonth(invoice.period).toLowerCase()}',
        status: 'Đã xác nhận',
        color: const Color(0xFF009C44),
        icon: Icons.check_circle_rounded,
        approved: true,
      ),
    );
  }
  return items..sort((a, b) => b.date.compareTo(a.date));
}

class TenantInvoiceTransactionTile extends StatelessWidget {
  const TenantInvoiceTransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
  });
  final TenantInvoiceTransaction transaction;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08253930),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: transaction.color.withValues(alpha: 0.07),
                  child: Icon(
                    transaction.icon,
                    color: transaction.color,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thanh toán tiền thuê phòng',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tenantInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.dateLabel,
                        style: const TextStyle(
                          color: tenantMuted,
                          fontSize: 10.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: constraints.maxWidth * 0.30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${transaction.approved ? '+ ' : ''}${formatTenantMoney(transaction.amount).replaceAll(' đ', 'đ')}',
                          style: TextStyle(
                            color: transaction.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: transaction.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          transaction.status,
                          maxLines: 1,
                          style: TextStyle(
                            color: transaction.color,
                            fontSize: 9,
                          ),
                        ),
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
  );
}

class TenantInvoiceSecurityBanner extends StatelessWidget {
  const TenantInvoiceSecurityBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFE2F5EA), Color(0xFFCBF0DC)],
      ),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.verified_user_rounded,
          color: Color(0xFF00A349),
          size: 36,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thanh toán an toàn, bảo mật',
                style: TextStyle(
                  color: Color(0xFF084D2D),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Thông tin rõ ràng, dễ dàng đối chiếu',
                style: TextStyle(color: Color(0xFF50625C), fontSize: 10),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.verified_user_outlined,
          color: Color(0x5066CB9B),
          size: 39,
        ),
      ],
    ),
  );
}
