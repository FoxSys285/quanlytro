import 'package:flutter/material.dart';

import '../../data/admin_commission.dart';
import '../../data/admin_store.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../landlord/finance/landlord_finance_models.dart';
import 'admin_ui.dart';
import '../landlord/landlord_ui.dart' show formatLandlordMoney;

class AdminCommissionPage extends StatefulWidget {
  const AdminCommissionPage({super.key});
  @override
  State<AdminCommissionPage> createState() => _AdminCommissionPageState();
}

class _AdminCommissionPageState extends State<AdminCommissionPage> {
  AdminStore get _admin => AdminStore.instance;
  RentalPortfolio get _portfolio => RentalPortfolio.instance;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _filter = 'all', _query = '';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      AdminStore.instance,
      RentalPortfolio.instance,
      LocalAuth.instance,
    ]),
    builder: (context, _) {
      final admin = _admin;
      final authorized = LocalAuth.instance.role == AppRole.admin;
      final statements = admin.statements
          .where((s) => s.month == _month)
          .toList();
      final forecast = _portfolio.stores.fold<int>(0, (sum, store) {
        if (statements.any((s) => s.propertyId == store.property.id)) {
          return sum;
        }
        final rate = admin.commissionRate(store.property.id);
        return sum +
            (rate == null
                ? 0
                : (commissionRentCollected(store, _month) * rate + 5000) ~/
                      10000);
      });
      final now = DateTime.now();
      final closedMonth = _month.isBefore(DateTime(now.year, now.month));
      final filteredStores = _portfolio.stores.where((store) {
        if (!'${store.property.name} ${store.property.ownerName}'
            .toLowerCase()
            .contains(_query)) {
          return false;
        }
        final statement = statements
            .where((s) => s.propertyId == store.property.id)
            .firstOrNull;
        final state = statement == null
            ? 'draft'
            : statement.remaining == 0
            ? 'paid'
            : statement.received > 0
            ? 'partial'
            : 'waiting';
        return _filter == 'all' || _filter == state;
      }).toList();
      return AdminFrame(
        title: 'Đối soát hoa hồng',
        subtitle: 'Chốt hoa hồng từng tháng, theo dõi công nợ và chứng từ.',
        children: [
          const AdminSyncBar(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: adminLine),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Tháng trước',
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left, color: adminBlue),
                ),
                Expanded(
                  child: Text(
                    landlordMonth(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: adminInk,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tháng sau',
                  onPressed: _month.isBefore(DateTime(now.year, now.month))
                      ? () => setState(
                          () => _month = DateTime(
                            _month.year,
                            _month.month + 1,
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _summary(statements, forecast),
          const AdminPanel(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.only(top: 8),
              leading: Icon(Icons.info_outline_rounded, color: adminBlue),
              title: Text('Cơ sở tính:'),
              subtitle: Text(
                'Tiền phòng đã duyệt · Không gồm điện nước',
                style: TextStyle(fontSize: 12, color: adminMuted),
              ),
              children: [
                Text(
                  '1. Mở nhà trọ và đặt tỷ lệ hoa hồng.\n2. Chốt kỳ khi tháng đã kết thúc.\n3. Ghi nhận số tiền nhận thực tế và mã chứng từ.\n\nChỉ tính tiền phòng đã duyệt thu theo tháng duyệt (thiếu ngày duyệt thì dùng ngày báo trả). Thanh toán một phần phân bổ theo tỷ trọng tiền phòng; không tính điện, nước và dịch vụ.',
                ),
              ],
            ),
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tìm nhà trọ hoặc chủ trọ',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in [
                (id: 'all', label: 'Tất cả'),
                (id: 'draft', label: 'Chưa chốt'),
                (id: 'waiting', label: 'Chờ thu'),
                (id: 'partial', label: 'Thu một phần'),
                (id: 'paid', label: 'Thu đủ'),
              ])
                ChoiceChip(
                  label: Text(item.label),
                  selected: _filter == item.id,
                  onSelected: (_) => setState(() => _filter = item.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final store in filteredStores)
            Builder(
              builder: (context) {
                final matches = statements.where(
                  (s) => s.propertyId == store.property.id,
                );
                final statement = matches.isEmpty ? null : matches.first;
                final rate = admin.commissionRate(store.property.id);
                final base =
                    statement?.rentCollected ??
                    commissionRentCollected(store, _month);
                final appliedRate = statement?.rateBasisPoints ?? rate;
                final due =
                    statement?.due ??
                    (rate == null ? null : (base * rate + 5000) ~/ 10000);
                final state = statement == null
                    ? 'draft'
                    : statement.remaining == 0
                    ? 'paid'
                    : statement.received > 0
                    ? 'partial'
                    : 'waiting';
                final statusColor = state == 'paid'
                    ? adminGreen
                    : state == 'draft'
                    ? adminBlue
                    : adminGold;
                return AdminPanel(
                  padding: const EdgeInsets.all(16),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 12),
                    leading: SizedBox(
                      width: 48,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AdminPropertyPhoto(
                          property: store.property,
                          height: 56,
                        ),
                      ),
                    ),
                    title: Text(
                      store.property.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: adminInk,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminStatus(
                            state == 'draft'
                                ? 'Chưa chốt'
                                : state == 'paid'
                                ? 'Thu đủ'
                                : state == 'partial'
                                ? 'Thu một phần'
                                : 'Chờ thu',
                            color: statusColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statement == null
                                ? due == null
                                      ? 'Chưa đặt tỷ lệ'
                                      : formatLandlordMoney(due)
                                : 'Còn ${formatLandlordMoney(statement.remaining)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: adminInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${store.property.ownerName} · ${store.property.phone}',
                            style: const TextStyle(color: adminMuted),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AdminStatus(
                                appliedRate == null
                                    ? 'Chưa đặt tỷ lệ'
                                    : '${appliedRate / 100}% hoa hồng',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(1.25),
                              1: FlexColumnWidth(),
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              for (final line in [
                                (
                                  label: 'Tiền phòng đã thu',
                                  value: formatLandlordMoney(base),
                                ),
                                (
                                  label:
                                      'Hoa hồng${statement == null ? ' dự kiến' : ' phải thu'}',
                                  value: due == null
                                      ? 'Chưa thiết lập'
                                      : formatLandlordMoney(due),
                                ),
                                if (statement != null) ...[
                                  (
                                    label: 'Đã nhận',
                                    value: formatLandlordMoney(
                                      statement.received,
                                    ),
                                  ),
                                  (
                                    label: 'Còn lại',
                                    value: formatLandlordMoney(
                                      statement.remaining,
                                    ),
                                  ),
                                ],
                              ])
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        7,
                                        12,
                                        7,
                                      ),
                                      child: Text(
                                        line.label,
                                        style: const TextStyle(
                                          color: adminMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 7,
                                      ),
                                      child: Text(
                                        line.value,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: adminInk,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (statement != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Chốt ngày ${landlordDate(statement.createdAt)}. Cơ sở và tỷ lệ của kỳ này đã được giữ nguyên.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: adminMuted,
                              ),
                            ),
                            for (final receipt in statement.receipts)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: const Icon(
                                  Icons.receipt_long_outlined,
                                  color: adminGreen,
                                ),
                                title: Text(
                                  '${receipt['reference']} · ${formatLandlordMoney(receipt['amount'] as int)}',
                                ),
                                subtitle: Text(
                                  landlordDate(
                                    DateTime.parse(receipt['at'] as String),
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: !authorized
                                    ? null
                                    : () async {
                                        final input = await adminInput(
                                          context,
                                          title: 'Tỷ lệ hoa hồng',
                                          label: 'Phần trăm (0–100)',
                                          numeric: true,
                                          initial: rate == null
                                              ? ''
                                              : '${rate / 100}',
                                        );
                                        if (input == null || !context.mounted) {
                                          return;
                                        }
                                        final percent = double.tryParse(
                                          input.replaceAll(',', '.').trim(),
                                        );
                                        if (percent == null ||
                                            !percent.isFinite ||
                                            percent < 0 ||
                                            percent > 100) {
                                          adminMessage(
                                            context,
                                            'Nhập tỷ lệ hợp lệ từ 0 đến 100%.',
                                          );
                                          return;
                                        }
                                        try {
                                          admin.setCommissionRate(
                                            store.property.id,
                                            (percent * 100).round(),
                                          );
                                        } on ArgumentError catch (e) {
                                          adminMessage(context, '${e.message}');
                                        }
                                      },
                                child: Text(
                                  statement == null
                                      ? 'Đặt tỷ lệ'
                                      : 'Tỷ lệ cho kỳ sau',
                                ),
                              ),
                              if (statement == null)
                                FilledButton(
                                  onPressed:
                                      !authorized ||
                                          !closedMonth ||
                                          rate == null
                                      ? null
                                      : () async {
                                          if (!await adminConfirm(
                                            context,
                                            'Chốt kỳ đối soát?',
                                            '${store.property.name} · ${landlordMonth(_month)}\nTiền phòng: ${formatLandlordMoney(base)}\nTỷ lệ: ${rate / 100}%\nHoa hồng: ${formatLandlordMoney(due!)}\nKỳ đã chốt sẽ không tính lại khi dữ liệu thay đổi.',
                                          )) {
                                            return;
                                          }
                                          if (!context.mounted) return;
                                          try {
                                            admin.closeCommission(
                                              store.property.id,
                                              _month,
                                            );
                                          } on ArgumentError catch (e) {
                                            adminMessage(
                                              context,
                                              '${e.message}',
                                            );
                                          }
                                        },
                                  child: const Text('Chốt đối soát'),
                                ),
                              if (statement != null && statement.remaining > 0)
                                FilledButton.icon(
                                  onPressed: !authorized
                                      ? null
                                      : () => _receive(context, statement),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Ghi nhận tiền đã nhận'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          if (filteredStores.isEmpty)
            const AdminPanel(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 32, color: adminMuted),
                  SizedBox(height: 12),
                  Text(
                    'Không có nhà trọ phù hợp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: adminInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Thử từ khóa hoặc trạng thái khác.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: adminMuted),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );

  Future<void> _receive(
    BuildContext context,
    CommissionStatement statement,
  ) async {
    final amountText = await adminInput(
      context,
      title: 'Ghi nhận tiền đã nhận',
      label: 'Số tiền thực nhận (đ)',
      initial: '${statement.remaining}',
      numeric: true,
      action: 'Tiếp tục',
    );
    if (amountText == null || !context.mounted) return;
    final amount = int.tryParse(amountText.trim());
    if (amount == null || amount <= 0 || amount > statement.remaining) {
      adminMessage(
        context,
        'Số tiền phải lớn hơn 0 và không vượt quá số còn phải thu.',
      );
      return;
    }
    final reference = await adminInput(
      context,
      title: 'Chứng từ nhận tiền',
      label: 'Mã giao dịch hoặc số phiếu thu',
      action: 'Tiếp tục',
    );
    if (reference == null || !context.mounted) return;
    if (!await adminConfirm(
      context,
      'Xác nhận đã nhận tiền?',
      '${statement.propertyName}\n${formatLandlordMoney(amount)} · ${reference.trim()}\nChỉ ghi nhận sau khi kiểm tra tiền thực tế. Thao tác này không chuyển tiền qua ngân hàng.',
    )) {
      return;
    }
    if (!context.mounted) return;
    try {
      _admin.receiveCommission(statement, amount, reference);
    } on ArgumentError catch (e) {
      adminMessage(context, '${e.message}');
    }
  }

  Widget _summary(List<CommissionStatement> statements, int forecast) {
    final total = statements.fold<int>(0, (n, s) => n + s.due);
    final received = statements.fold<int>(0, (n, s) => n + s.received);
    const secondary = Color(0xFFBAE6FD);
    const receivedColor = Color(0xFF2DD4BF);
    return AdminPanel(
      backgroundColor: adminInk,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0B192C),
          Color(0xFF0F2942),
          Color(0xFF0369A1),
        ],
        stops: [0.0, 0.55, 1.0],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0x2638BDF8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFF7DD3FC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statements.isEmpty ? 'Hoa hồng dự kiến' : 'Còn phải thu',
                  style: const TextStyle(
                    color: secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatLandlordMoney(
              statements.isEmpty ? forecast : total - received,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          if (statements.isNotEmpty && forecast > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x2238BDF8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x407DD3FC)),
                ),
                child: Text(
                  'Dự kiến chưa chốt: ${formatLandlordMoney(forecast)}',
                  style: const TextStyle(
                    color: Color(0xFFE0F2FE),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.16)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đã chốt',
                      style: TextStyle(color: secondary, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatLandlordMoney(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đã nhận',
                      style: TextStyle(color: secondary, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      formatLandlordMoney(received),
                      style: const TextStyle(
                        color: receivedColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : received / total,
              minHeight: 6,
              color: receivedColor,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              semanticsLabel: 'Tỷ lệ hoa hồng đã nhận',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${statements.length} nhà trọ đã chốt · ${total == 0 ? 0 : (received * 100 / total).round()}% đã thu',
            style: const TextStyle(color: secondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
