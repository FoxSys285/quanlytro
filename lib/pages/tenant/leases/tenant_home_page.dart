import 'package:flutter/material.dart';

import '../../landlord/finance/landlord_finance_models.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../shared/rental/tenant_session.dart';
import '../conversations/tenant_conversation_page.dart';
import '../incidents/tenant_incidents_page.dart';
import '../invoices/tenant_invoices_page.dart';
import '../tenant_ui.dart';
import 'components/tenant_lease_member_row.dart';
import 'components/tenant_lease_overview_card.dart';
import 'components/tenant_lease_metric.dart';

class TenantHomePage extends StatelessWidget {
  const TenantHomePage({
    super.key,
    this.store,
    this.tenantId = TenantSession.tenantId,
  });
  final LandlordDemoStore? store;
  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final data = store ?? LandlordDemoStore.instance;
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final lease = data.currentLeaseForTenant(tenantId);
        if (lease == null) {
          return const TenantPageFrame(
            children: [
              TenantPageTitle(
                title: 'Chỗ ở của tôi',
                subtitle: 'Thông tin thuê nhà và sinh hoạt.',
              ),
              TenantEmptyState(
                icon: Icons.home_outlined,
                title: 'Chưa có hợp đồng đang hiệu lực',
                subtitle:
                    'Hợp đồng mới sẽ xuất hiện khi chủ trọ kích hoạt cho bạn.',
              ),
            ],
          );
        }
        final room = data.roomByCode(lease.room);
        final members = data.membersForLease(lease.id);
        final payable =
            data
                .invoicesForTenant(tenantId)
                .where((invoice) => !invoice.cancelled && invoice.remaining > 0)
                .toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        return TenantPageFrame(
          children: [
            const TenantPageTitle(
              title: 'Chỗ ở của tôi',
              subtitle: 'Thông tin thuê nhà và sinh hoạt trong một nơi.',
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [tenantGreenDark, tenantGreen],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHỖ Ở HIỆN TẠI · Đang thuê',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data.property.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Phòng ${lease.room} · Tầng ${room?.floor ?? '—'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.property.address,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Divider(height: 30, color: Colors.white24),
                  Row(
                    children: [
                      Expanded(
                        child: TenantLeaseMetric(
                          label: 'Ngày bắt đầu',
                          value: landlordDate(lease.startDate),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TenantLeaseMetric(
                          label: 'Hết hạn hợp đồng',
                          value: landlordDate(lease.endDate),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (payable.isNotEmpty) ...[
              const SizedBox(height: 15),
              TenantSurface(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFFAB7623),
                  ),
                  title: Text(landlordMonth(payable.first.period)),
                  subtitle: Text(
                    '${formatTenantMoney(payable.first.remaining)} · hạn ${landlordDate(payable.first.dueDate)}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () => _openPage(
                    context,
                    'Hóa đơn',
                    TenantInvoicesPage(store: data, tenantId: tenantId),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const TenantSectionHeading('Tổng quan'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 250,
                  child: TenantLeaseOverviewCard(
                    icon: Icons.payments_outlined,
                    title: 'Tiền thuê',
                    value: formatTenantMoney(lease.monthlyRent),
                    caption: 'Mỗi tháng',
                    color: tenantGreen,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: TenantLeaseOverviewCard(
                    icon: Icons.event_available_outlined,
                    title: 'Ngày thanh toán',
                    value: 'Ngày ${lease.dueDay}',
                    caption: 'Hằng tháng',
                    color: const Color(0xFF4784C7),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: TenantLeaseOverviewCard(
                    icon: Icons.people_outline_rounded,
                    title: 'Thành viên',
                    value: '${members.length} người',
                    caption: 'Trong phòng',
                    color: const Color(0xFFB17939),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const TenantSectionHeading(
              'Hợp đồng thuê',
              trailing: TenantStatusPill('Còn hiệu lực', color: tenantGreen),
            ),
            TenantSurface(
              child: Column(
                children: [
                  TenantDataRow(label: 'Mã hợp đồng', value: lease.id),
                  const TenantThinDivider(),
                  TenantDataRow(
                    label: 'Tiền đặt cọc',
                    value: formatTenantMoney(lease.deposit),
                  ),
                  TenantDataRow(
                    label: 'Chu kỳ thanh toán',
                    value: 'Hàng tháng · ngày ${lease.dueDay}',
                  ),
                  TenantDataRow(
                    label: 'Giá điện',
                    value: '${formatTenantMoney(lease.electricityPrice)}/kWh',
                  ),
                  TenantDataRow(
                    label: 'Giá nước',
                    value:
                        '${formatTenantMoney(lease.waterPrice)}/${lease.waterType == 'Theo tháng' ? 'tháng' : 'm³'}',
                  ),
                  TenantDataRow(
                    label: 'Tiền xe',
                    value: '${formatTenantMoney(lease.vehicleFee)}/tháng',
                  ),
                  TenantDataRow(
                    label: 'Tiền dịch vụ',
                    value: '${formatTenantMoney(lease.serviceFee)}/tháng',
                  ),
                  const TenantThinDivider(),
                  TenantDataRow(
                    label: 'Bản hợp đồng',
                    value: 'Mở hợp đồng ›',
                    valueColor: tenantGreenDark,
                    onTap: () => _showContractDetails(context, data, lease),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TenantSectionHeading(
              'Người ở cùng',
              trailing: Text(
                '${members.length} / ${room?.capacity ?? '—'} người',
              ),
            ),
            TenantSurface(
              child: Column(
                children: [
                  for (final member in members)
                    TenantLeaseMemberRow(
                      initials: member.name
                          .trim()
                          .split(RegExp(r'\s+'))
                          .last[0],
                      name: member.name,
                      detail:
                          '${member.tenantId == tenantId ? 'Bạn · ' : ''}${member.isRepresentative ? 'Người đại diện' : 'Thành viên'}',
                      color: member.isRepresentative
                          ? tenantGreen
                          : const Color(0xFF7181C1),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            Wrap(
              spacing: 10,
              children: [
                TenantOutlineAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Nhắn tin',
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const TenantLandlordConversationPage(),
                    ),
                  ),
                ),
                TenantOutlineAction(
                  icon: Icons.build_outlined,
                  label: 'Báo sự cố',
                  onPressed: () => _openPage(
                    context,
                    'Báo sự cố',
                    TenantIncidentsPage(store: data, tenantId: tenantId),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _openPage(BuildContext context, String title, Widget page) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: page,
          ),
        ),
      );

  void _showContractDetails(
    BuildContext context,
    LandlordDemoStore data,
    LandlordLease lease,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ListenableBuilder(
        listenable: data,
        builder: (context, _) => TenantBottomSheetSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TenantSheetHandle(),
              Text(
                '${lease.id} · Phòng ${lease.room}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              TenantSurface(
                child: Column(
                  children: [
                    TenantDataRow(label: 'Chủ trọ', value: lease.landlordName),
                    TenantDataRow(
                      label: 'Địa chỉ bên A',
                      value: lease.landlordPermanentAddress,
                    ),
                    TenantDataRow(
                      label: 'CCCD bên A',
                      value: lease.landlordCitizenId,
                    ),
                    TenantDataRow(
                      label: 'Điện thoại/Zalo',
                      value: lease.landlordContact,
                    ),
                    const TenantThinDivider(),
                    TenantDataRow(
                      label: 'Người đại diện thuê',
                      value: lease.tenantName,
                    ),
                    TenantDataRow(
                      label: 'Năm sinh',
                      value: lease.tenantBirthYear,
                    ),
                    TenantDataRow(
                      label: 'CCCD bên B',
                      value: lease.tenantCitizenId,
                    ),
                    TenantDataRow(
                      label: 'Ngày cấp',
                      value: lease.tenantCitizenIssueDate == null
                          ? '—'
                          : landlordDate(lease.tenantCitizenIssueDate!),
                    ),
                    TenantDataRow(
                      label: 'Thường trú bên B',
                      value: lease.tenantPermanentAddress,
                    ),
                    TenantDataRow(
                      label: 'Điện thoại bên B',
                      value: lease.phone,
                    ),
                    const TenantThinDivider(),
                    TenantDataRow(
                      label: 'Thời hạn',
                      value:
                          '${landlordDate(lease.startDate)} – ${landlordDate(lease.endDate)}',
                    ),
                    TenantDataRow(
                      label: 'Số tháng thuê',
                      value: '${lease.termMonths} tháng',
                    ),
                    TenantDataRow(
                      label: 'Tiền thuê',
                      value: '${formatTenantMoney(lease.monthlyRent)}/tháng',
                    ),
                    TenantDataRow(
                      label: 'Tiền đặt cọc',
                      value: formatTenantMoney(lease.deposit),
                    ),
                    TenantDataRow(
                      label: 'Ngày thanh toán',
                      value: 'Ngày ${lease.dueDay} hằng tháng',
                    ),
                    TenantDataRow(
                      label: 'Giá điện',
                      value: '${formatTenantMoney(lease.electricityPrice)}/kWh',
                    ),
                    TenantDataRow(
                      label: 'Giá nước',
                      value:
                          '${formatTenantMoney(lease.waterPrice)}/${lease.waterType == 'Theo tháng' ? 'tháng' : 'm³'}',
                    ),
                    TenantDataRow(
                      label: 'Tiền xe',
                      value: formatTenantMoney(lease.vehicleFee),
                    ),
                    TenantDataRow(
                      label: 'Tiền dịch vụ',
                      value: formatTenantMoney(lease.serviceFee),
                    ),
                    TenantDataRow(
                      label: 'Số người ở',
                      value:
                          '${data.membersForLease(lease.id).length} / ${data.roomByCode(lease.room)?.capacity ?? '—'} người',
                    ),
                    if (lease.cashPaymentEnabled)
                      TenantDataRow(
                        label: 'Tiền mặt',
                        value: lease.cashPaymentLocation,
                      ),
                    if (lease.bankTransferEnabled) ...[
                      TenantDataRow(
                        label: 'Ngân hàng trong hợp đồng',
                        value: lease.bankName,
                      ),
                      TenantDataRow(
                        label: 'Tài khoản trong hợp đồng',
                        value: lease.bankAccountNumber,
                      ),
                    ],
                    TenantDataRow(
                      label: 'Ghi chú',
                      value: lease.note.isEmpty ? '—' : lease.note,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
