import 'package:flutter/material.dart';

import '../../landlord/finance/landlord_finance_models.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../shared/rental/tenant_session.dart';
import '../../shared/payments/vietqr_service.dart';
import '../invoices/components/tenant_bank_qr.dart';
import '../tenant_detail_ui.dart';
import '../tenant_ui.dart';
import 'components/tenant_lease_overview.dart';

String _serviceQuantityLabel(LandlordLeaseService service) {
  final basis = service.basis.toLowerCase();
  if (basis.contains('người')) return ' × ${service.quantity} người';
  if (basis.contains('cái') || basis.contains('xe')) {
    return ' × ${service.quantity} ${service.unit}';
  }
  return '';
}

DateTime _endAfterMonths(DateTime endDate, int months) {
  final first = DateTime(endDate.year, endDate.month + months, 1);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(
    first.year,
    first.month,
    endDate.day > lastDay ? lastDay : endDate.day,
  );
}

Future<void> _requestRenewal(
  BuildContext context,
  LandlordDemoStore store,
  LandlordLease lease,
  String tenantId,
) async {
  final months = TextEditingController(text: '12');
  final reason = TextEditingController();
  final submitted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Đề nghị gia hạn hợp đồng'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: months,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số tháng muốn gia hạn',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reason,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Lời nhắn cho chủ trọ (không bắt buộc)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Gửi đề nghị'),
        ),
      ],
    ),
  );
  final count = int.tryParse(months.text.trim());
  months.dispose();
  if (submitted != true || !context.mounted) {
    reason.dispose();
    return;
  }
  if (count == null || count < 1 || count > 60) {
    reason.dispose();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thời hạn gia hạn phải từ 1 đến 60 tháng.')),
    );
    return;
  }
  try {
    store.requestLeaseRenewal(
      tenantId: tenantId,
      leaseId: lease.id,
      proposedEndDate: _endAfterMonths(lease.endDate, count),
      reason: reason.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi đề nghị gia hạn cho chủ trọ.')),
    );
  } on ArgumentError catch (error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message.toString())));
  } finally {
    reason.dispose();
  }
}

Future<void> _requestTermination(
  BuildContext context,
  LandlordDemoStore store,
  LandlordLease lease,
  String tenantId,
) async {
  final reason = TextEditingController();
  final submitted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Đề nghị kết thúc hợp đồng'),
      content: TextField(
        controller: reason,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        maxLength: 300,
        decoration: const InputDecoration(
          labelText: 'Lý do chuyển trọ / kết thúc hợp đồng',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Gửi đề nghị'),
        ),
      ],
    ),
  );
  if (submitted != true || !context.mounted) {
    reason.dispose();
    return;
  }
  try {
    store.requestLeaseTermination(
      tenantId: tenantId,
      leaseId: lease.id,
      reason: reason.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi đề nghị kết thúc hợp đồng cho chủ trọ.'),
      ),
    );
  } on ArgumentError catch (error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error.message.toString())));
  } finally {
    reason.dispose();
  }
}

Widget _leaseRequestPanel(
  BuildContext context,
  LandlordDemoStore store,
  LandlordLease lease,
  String tenantId,
) {
  final today = DateUtils.dateOnly(DateTime.now());
  final daysLeft = DateUtils.dateOnly(lease.endDate).difference(today).inDays;
  return TenantSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TenantSectionHeading('Gia hạn và kết thúc hợp đồng'),
        Text(
          lease.renewalStatus == 'pending'
              ? 'Đề nghị gia hạn đang chờ chủ trọ duyệt. Ngày đề xuất: ${lease.renewalProposedEndDate == null ? '—' : landlordDate(lease.renewalProposedEndDate!)}.'
              : lease.renewalStatus == 'rejected'
              ? 'Đề nghị gần nhất bị từ chối: ${lease.renewalRejectionReason}'
              : 'Hợp đồng còn $daysLeft ngày. Có thể gửi đề nghị gia hạn trong tháng cuối.',
          style: const TextStyle(color: tenantMuted, fontSize: 12, height: 1.5),
        ),
        if (lease.renewalStatus != 'pending' && daysLeft <= 31) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _requestRenewal(context, store, lease, tenantId),
            icon: const Icon(Icons.autorenew_rounded),
            label: const Text('Đề nghị gia hạn'),
          ),
        ],
        if (lease.tenantId == tenantId) ...[
          const Divider(height: 24),
          if (lease.terminationRequestStatus == 'pending')
            const Text(
              'Đề nghị kết thúc hợp đồng đang chờ chủ trọ xử lý.',
              style: TextStyle(color: tenantMuted, fontSize: 12),
            )
          else ...[
            if (lease.terminationRequestStatus == 'rejected')
              Text(
                'Đề nghị trước bị từ chối: ${lease.terminationRejectionReason}',
                style: const TextStyle(color: tenantMuted, fontSize: 12),
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  _requestTermination(context, store, lease, tenantId),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đề nghị chuyển trọ / kết thúc hợp đồng'),
            ),
          ],
        ],
      ],
    ),
  );
}

class TenantLeaseContractPage extends StatelessWidget {
  const TenantLeaseContractPage({
    super.key,
    this.store,
    String? tenantId,
    this.qrService,
  }) : _tenantId = tenantId ?? '';

  final LandlordDemoStore? store;
  final String _tenantId;
  String get tenantId =>
      _tenantId.isEmpty ? TenantSession.currentTenantId : _tenantId;
  final VietQrService? qrService;

  @override
  Widget build(BuildContext context) {
    final data = store ?? LandlordDemoStore.instance;
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final lease = data.currentLeaseForTenant(tenantId);
        final previousLease = data
            .leasesForTenant(tenantId)
            .where((item) => item.status == LandlordLeaseStatus.terminated)
            .lastOrNull;
        final account = data.defaultPaymentAccount;
        final contractBankDiffers =
            account != null &&
            (account.bankName != lease?.bankName ||
                account.accountNumber != lease?.bankAccountNumber);
        return _frame(
          hasLease: lease != null,
          children: [
            if (lease == null) ...[
              const TenantEmptyState(
                icon: Icons.description_outlined,
                title: 'Chưa có hợp đồng đang hiệu lực',
                subtitle:
                    'Hợp đồng sẽ xuất hiện tại đây khi chủ trọ kích hoạt.',
              ),
              if (previousLease != null)
                TenantSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TenantSectionHeading('Hợp đồng đã kết thúc'),
                      Text('Lý do: ${previousLease.terminationReason}'),
                      if (previousLease.terminatedAt != null)
                        Text(
                          'Ngày kết thúc: ${landlordDate(previousLease.terminatedAt!)}',
                        ),
                    ],
                  ),
                ),
            ] else ...[
              TenantLeaseOverview(data: data, lease: lease),
              const SizedBox(height: 26),
              _leaseRequestPanel(context, data, lease, tenantId),
              const SizedBox(height: 24),
              const TenantSectionHeading('Thông tin hợp đồng'),
              TenantSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TenantDetailRow(label: 'Mã hợp đồng', value: lease.id),
                    TenantDetailRow(
                      label: 'Tiền thuê mỗi tháng',
                      value: formatTenantMoney(lease.monthlyRent),
                      emphasized: true,
                    ),
                    TenantDetailRow(
                      label: 'Tiền đặt cọc',
                      value: formatTenantMoney(lease.deposit),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const TenantSectionHeading('Thời hạn & thanh toán'),
              TenantSurface(
                child: Column(
                  children: [
                    TenantDetailRow(
                      label: 'Ngày bắt đầu',
                      value: landlordDate(lease.startDate),
                    ),
                    TenantDetailRow(
                      label: 'Ngày kết thúc',
                      value: landlordDate(lease.endDate),
                    ),
                    TenantDetailRow(
                      label: 'Thời hạn thuê',
                      value: '${lease.termMonths} tháng',
                    ),
                    TenantDetailRow(
                      label: 'Hạn thanh toán',
                      value: 'Ngày ${lease.dueDay} hằng tháng',
                    ),
                    TenantDetailRow(
                      label: 'Số người ở',
                      value:
                          '${data.membersForLease(lease.id).length} / ${data.roomByCode(lease.room)?.capacity ?? '—'} người',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const TenantSectionHeading('Thông tin các bên'),
              TenantSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BÊN CHO THUÊ',
                      style: TextStyle(
                        color: tenantGreenDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TenantDetailRow(
                      label: 'Chủ trọ',
                      value: lease.landlordName,
                    ),
                    TenantDetailRow(
                      label: 'CCCD',
                      value: lease.landlordCitizenId,
                    ),
                    TenantDetailRow(
                      label: 'Địa chỉ thường trú',
                      value: lease.landlordPermanentAddress,
                    ),
                    TenantDetailRow(
                      label: 'Điện thoại / Zalo',
                      value: lease.landlordContact,
                    ),
                    const TenantThinDivider(),
                    const Text(
                      'BÊN THUÊ',
                      style: TextStyle(
                        color: tenantGreenDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TenantDetailRow(
                      label: 'Người đại diện',
                      value: lease.tenantName,
                    ),
                    TenantDetailRow(
                      label: 'Năm sinh',
                      value: lease.tenantBirthYear,
                    ),
                    TenantDetailRow(
                      label: 'CCCD',
                      value: lease.tenantCitizenId,
                    ),
                    TenantDetailRow(
                      label: 'Ngày cấp',
                      value: lease.tenantCitizenIssueDate == null
                          ? 'Chưa cập nhật'
                          : landlordDate(lease.tenantCitizenIssueDate!),
                    ),
                    TenantDetailRow(
                      label: 'Địa chỉ thường trú',
                      value: lease.tenantPermanentAddress,
                    ),
                    TenantDetailRow(label: 'Điện thoại', value: lease.phone),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const TenantSectionHeading('Dịch vụ & chi phí'),
              TenantSurface(
                child: Column(
                  children: [
                    TenantDetailRow(
                      label: 'Giá điện',
                      value: '${formatTenantMoney(lease.electricityPrice)}/kWh',
                    ),
                    TenantDetailRow(
                      label: 'Giá nước',
                      value:
                          '${formatTenantMoney(lease.waterPrice)}/${lease.waterType == 'Theo tháng'
                              ? 'tháng'
                              : lease.waterType == 'Theo người'
                              ? 'người'
                              : 'm³'}',
                    ),
                    if (lease.services.isNotEmpty) ...[
                      for (final service in lease.services)
                        TenantDetailRow(
                          label: service.name,
                          value:
                              '${formatTenantMoney(service.price)}/${service.unit}${_serviceQuantityLabel(service)} · ${service.basis} · ${formatTenantMoney(service.amount)}/tháng',
                        ),
                    ] else ...[
                      TenantDetailRow(
                        label: 'Phí gửi xe',
                        value: '${formatTenantMoney(lease.vehicleFee)}/tháng',
                      ),
                      TenantDetailRow(
                        label: lease.serviceName.isEmpty
                            ? 'Phí dịch vụ'
                            : 'Phí ${lease.serviceName}',
                        value:
                            '${formatTenantMoney(lease.serviceFee)}/${lease.serviceUnit.isEmpty ? 'tháng' : lease.serviceUnit}',
                      ),
                    ],
                    const TenantThinDivider(),
                    const TenantDetailNote(
                      'Tiền điện, nước được tính theo đơn giá và mức sử dụng thực tế. Tổng cần thanh toán được thể hiện trên từng hóa đơn.',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const TenantSectionHeading('Phương thức thanh toán'),
              TenantSurface(
                child: Column(
                  children: [
                    TenantDetailRow(
                      label: 'Hạn thanh toán',
                      value: 'Ngày ${lease.dueDay} hằng tháng',
                    ),
                    if (lease.cashPaymentEnabled)
                      TenantDetailRow(
                        label: 'Tiền mặt',
                        value: lease.cashPaymentLocation.isEmpty
                            ? 'Liên hệ chủ trọ để hẹn địa điểm'
                            : lease.cashPaymentLocation,
                      ),
                    if (lease.bankTransferEnabled) ...[
                      const TenantThinDivider(),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CHUYỂN KHOẢN NGÂN HÀNG',
                          style: TextStyle(
                            color: tenantGreenDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (account != null)
                        TenantBankQr(
                          bankName: account.bankName,
                          accountNumber: account.accountNumber,
                          accountName: account.accountName,
                          reference:
                              'Thanh toan ${lease.id.replaceAll('-', ' ')}',
                          service: qrService,
                        )
                      else
                        const TenantDetailNote(
                          'Chủ trọ chưa thiết lập tài khoản nhận tiền hiện tại. Vui lòng liên hệ chủ trọ trước khi chuyển khoản.',
                          icon: Icons.account_balance_outlined,
                        ),
                      if (contractBankDiffers || account == null) ...[
                        const TenantThinDivider(),
                        const TenantDetailNote(
                          'Thông tin tài khoản ghi trong hợp đồng được giữ bên dưới. Khi thanh toán, sử dụng tài khoản nhận tiền hiện tại do chủ trọ thiết lập ở trên.',
                        ),
                        TenantDetailRow(
                          label: 'Ngân hàng trong hợp đồng',
                          value: lease.bankName,
                        ),
                        TenantDetailRow(
                          label: 'Số tài khoản trong hợp đồng',
                          value: lease.bankAccountNumber,
                        ),
                      ],
                    ],
                    if (!lease.cashPaymentEnabled && !lease.bankTransferEnabled)
                      const TenantDetailNote(
                        'Chủ trọ chưa thiết lập phương thức thanh toán.',
                      ),
                  ],
                ),
              ),
              if (lease.note.isNotEmpty) ...[
                const SizedBox(height: 16),
                TenantDetailNote(
                  lease.note,
                  icon: Icons.sticky_note_2_outlined,
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _frame({required bool hasLease, required List<Widget> children}) =>
      TenantDetailTheme(
        child: TenantPageFrame(
          padding: EdgeInsets.zero,
          children: [
            TenantLeaseHero(hasLease: hasLease),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      );
}
