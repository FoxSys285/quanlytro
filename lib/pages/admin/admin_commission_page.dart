import 'package:flutter/material.dart';

import '../../data/admin_commission.dart';
import '../../data/admin_store.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../landlord/finance/landlord_finance_models.dart';
import 'admin_ui.dart';
import 'admin_demo_data.dart';
import '../landlord/landlord_ui.dart' show formatLandlordMoney;

class AdminCommissionPage extends StatefulWidget {
  const AdminCommissionPage({super.key});
  @override
  State<AdminCommissionPage> createState() => _AdminCommissionPageState();
}

class _AdminCommissionPageState extends State<AdminCommissionPage> {
  AdminDemoData get demo => AdminDemoData.instance;
  AdminStore get _admin => demo.enabled ? demo.admin : AdminStore.instance;
  RentalPortfolio get _portfolio =>
      demo.enabled ? demo.portfolio : RentalPortfolio.instance;
  late DateTime _month = demo.enabled
      ? demo.month
      : DateTime(DateTime.now().year, DateTime.now().month - 1);
  String _filter = 'all', _query = '';
  late bool _wasDemo = demo.enabled;
  late DateTime _demoMonth = demo.month;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      AdminStore.instance,
      RentalPortfolio.instance,
      LocalAuth.instance,
      demo,
    ]),
    builder: (context, _) {
      if (_wasDemo != demo.enabled ||
          (demo.enabled && _demoMonth != demo.month)) {
        _wasDemo = demo.enabled;
        _demoMonth = demo.month;
        _month = demo.enabled
            ? demo.month
            : DateTime(DateTime.now().year, DateTime.now().month - 1);
      }
      final admin = _admin;
      final authorized = LocalAuth.instance.role == AppRole.admin;
      final statements = admin.statements
          .where((s) => s.month == _month)
          .toList();
      final now = DateTime.now();
      final closedMonth = _month.isBefore(DateTime(now.year, now.month));
      return AdminFrame(
        title: 'Đối soát hoa hồng',
        subtitle: 'Chốt hoa hồng từng tháng, theo dõi công nợ và chứng từ.',
        children: [
          const AdminDemoBar(),
          Row(
            children: [
              IconButton(
                tooltip: 'Tháng trước',
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  landlordMonth(_month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tháng sau',
                onPressed: _month.isBefore(DateTime(now.year, now.month))
                    ? () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1),
                      )
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _summary(statements),
          const AdminPanel(
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in [
                  (id: 'all', label: 'Tất cả'),
                  (id: 'draft', label: 'Chưa chốt'),
                  (id: 'waiting', label: 'Chờ thu'),
                  (id: 'partial', label: 'Thu một phần'),
                  (id: 'paid', label: 'Thu đủ'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item.label),
                      selected: _filter == item.id,
                      onSelected: (_) => setState(() => _filter = item.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final store in _portfolio.stores.where(
            (s) => '${s.property.name} ${s.property.ownerName}'
                .toLowerCase()
                .contains(_query),
          ))
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
                if (_filter != 'all' && _filter != state) {
                  return const SizedBox.shrink();
                }
                final statusColor = state == 'paid'
                    ? adminGreen
                    : state == 'draft'
                    ? adminBlue
                    : state == 'partial'
                    ? adminOrange
                    : adminGold;
                return AdminPanel(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: state == 'paid'
                      ? const Color(0xFFEDF7F2)
                      : state == 'draft'
                      ? const Color(0xFFF0F0FC)
                      : Colors.white,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 12),
                    leading: SizedBox(
                      width: 62,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AdminPropertyPhoto(
                          property: store.property,
                          height: 66,
                        ),
                      ),
                    ),
                    title: Text(
                      store.property.name,
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
                          Text(
                            state == 'draft'
                                ? 'Chưa chốt'
                                : state == 'paid'
                                ? 'Thu đủ'
                                : state == 'partial'
                                ? 'Thu một phần'
                                : 'Chờ thu',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
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
                              color: statusColor,
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
                                statement == null
                                    ? 'Chưa chốt'
                                    : statement.remaining == 0
                                    ? 'Đã thu đủ'
                                    : statement.received > 0
                                    ? 'Đã thu một phần'
                                    : 'Chờ thu',
                                color: statement?.remaining == 0
                                    ? adminGreen
                                    : adminGold,
                              ),
                              AdminStatus(
                                appliedRate == null
                                    ? 'Chưa đặt tỷ lệ'
                                    : '${appliedRate / 100}% hoa hồng',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tiền phòng đã thu: ${formatLandlordMoney(base)}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hoa hồng${statement == null ? ' dự kiến' : ' phải thu'}: ${due == null ? 'Chưa thiết lập' : formatLandlordMoney(due)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (statement != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Đã nhận: ${formatLandlordMoney(statement.received)} · Còn lại: ${formatLandlordMoney(statement.remaining)}',
                            ),
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
          if (!_portfolio.stores.any((store) {
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
          }))
            const AdminPanel(
              child: Text(
                'Không có nhà trọ phù hợp. Thử từ khóa hoặc trạng thái khác.',
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

  Widget _summary(List<CommissionStatement> statements) {
    final total = statements.fold<int>(0, (n, s) => n + s.due);
    final received = statements.fold<int>(0, (n, s) => n + s.received);
    return AdminPanel(
      backgroundColor: const Color(0xFF1D2E50),
      child: Stack(
        children: [
          const Positioned(
            right: -12,
            top: -8,
            child: ExcludeSemantics(
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 110,
                color: Color(0x18FFFFFF),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF9AE3CD),
                    size: 21,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Còn phải thu',
                      style: TextStyle(color: Color(0xFFD1DCF2), fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                formatLandlordMoney(total - received),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFF52607D)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đã chốt',
                          style: TextStyle(
                            color: Color(0xFFD1DCF2),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatLandlordMoney(total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
                          style: TextStyle(
                            color: Color(0xFFD1DCF2),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatLandlordMoney(received),
                          style: const TextStyle(
                            color: Color(0xFF9AE3CD),
                            fontWeight: FontWeight.w700,
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
                  minHeight: 5,
                  color: const Color(0xFF9AE3CD),
                  backgroundColor: const Color(0xFF405476),
                  semanticsLabel: 'Tỷ lệ hoa hồng đã nhận',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${statements.length} nhà trọ đã chốt · ${total == 0 ? 0 : (received * 100 / total).round()}% đã thu',
                style: const TextStyle(color: Color(0xFFD1DCF2), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
