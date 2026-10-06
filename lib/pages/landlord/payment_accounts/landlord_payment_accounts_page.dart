import 'package:flutter/material.dart';

import '../finance/landlord_finance_models.dart';
import '../landlord_demo_store.dart';
import '../landlord_ui.dart';

class LandlordPaymentAccountsPage extends StatelessWidget {
  const LandlordPaymentAccountsPage({super.key});

  static final _store = LandlordDemoStore.instance;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => LandlordPageFrame(
      children: [
        LandlordPageTitle(
          title: 'Tài khoản nhận tiền',
          subtitle:
              'Thông tin chuyển khoản hiển thị trên hướng dẫn thanh toán.',
          trailing: FilledButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm tài khoản'),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF5FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD6E4FA)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, color: landlordBlue, size: 19),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Chỉ lưu thông tin tài khoản để hiển thị cho người thuê. Ứng dụng không yêu cầu mật khẩu ngân hàng, mã PIN hoặc OTP.',
                  style: TextStyle(
                    color: landlordInk,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final account in _store.paymentAccounts)
          _accountCard(context, account),
        const SizedBox(height: 4),
        const Text(
          'Thay đổi tài khoản mặc định áp dụng cho hướng dẫn thanh toán mới.',
          style: TextStyle(color: landlordMuted, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _accountCard(BuildContext context, LandlordPaymentAccount account) {
    final defaultAccount = account.isDefault && account.isActive;
    return LandlordCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: landlordBlue.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: landlordBlue,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.bankName,
                      style: const TextStyle(
                        color: landlordInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      account.accountName,
                      style: const TextStyle(
                        color: landlordMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (defaultAccount)
                const LandlordStatusPill('Mặc định', color: landlordBlue),
            ],
          ),
          const Divider(height: 22),
          _line('Số tài khoản', account.maskedNumber),
          if (account.branch.isNotEmpty) ...[
            const SizedBox(height: 7),
            _line('Ghi chú', account.branch),
          ],
          const SizedBox(height: 11),
          Row(
            children: [
              LandlordStatusPill(
                account.isVerified ? 'Đã xác minh' : 'Chưa xác minh',
                color: account.isVerified
                    ? const Color(0xFF16836F)
                    : const Color(0xFFE08A1E),
              ),
              const SizedBox(width: 7),
              LandlordStatusPill(
                account.isActive ? 'Đang sử dụng' : 'Đã tạm ngưng',
                color: account.isActive
                    ? const Color(0xFF16836F)
                    : landlordMuted,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Chỉnh sửa',
                onPressed: () => _edit(context, account),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
            ],
          ),
          if (account.isActive && !defaultAccount) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  try {
                    _store.setDefaultPaymentAccount(account);
                    showLandlordMessage(
                      context,
                      'Đã chọn ${account.bankName} làm tài khoản mặc định.',
                    );
                  } on ArgumentError catch (error) {
                    showLandlordMessage(context, error.message.toString());
                  }
                },
                icon: const Icon(Icons.star_outline_rounded, size: 17),
                label: const Text('Đặt làm mặc định'),
              ),
            ),
          ],
          const Divider(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cho phép người thuê chuyển khoản vào tài khoản này',
                  style: TextStyle(color: landlordInk, fontSize: 11),
                ),
              ),
              Switch(
                value: account.isActive,
                onChanged: (value) {
                  try {
                    _store.setPaymentAccountActive(account, value);
                  } on ArgumentError catch (error) {
                    showLandlordMessage(context, error.message.toString());
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Row(
    children: [
      SizedBox(
        width: 100,
        child: Text(
          label,
          style: const TextStyle(color: landlordMuted, fontSize: 11),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: landlordInk,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );

  Future<void> _edit(
    BuildContext context, [
    LandlordPaymentAccount? account,
  ]) async {
    final result = await showDialog<_PaymentAccountDraft>(
      context: context,
      builder: (_) => _PaymentAccountEditor(account: account),
    );
    if (result == null || !context.mounted) return;
    try {
      _store.savePaymentAccount(
        existing: account,
        bankName: result.bankName,
        accountName: result.accountName,
        accountNumber: result.accountNumber,
        branch: result.branch,
        makeDefault: result.makeDefault,
      );
      showLandlordMessage(
        context,
        account == null
            ? 'Đã thêm tài khoản nhận tiền.'
            : 'Đã cập nhật thông tin tài khoản.',
      );
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }
}

class _PaymentAccountDraft {
  const _PaymentAccountDraft({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.branch,
    required this.makeDefault,
  });
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String branch;
  final bool makeDefault;
}

class _PaymentAccountEditor extends StatefulWidget {
  const _PaymentAccountEditor({this.account});
  final LandlordPaymentAccount? account;

  @override
  State<_PaymentAccountEditor> createState() => _PaymentAccountEditorState();
}

class _PaymentAccountEditorState extends State<_PaymentAccountEditor> {
  late final _bank = TextEditingController(
    text: widget.account?.bankName ?? '',
  );
  late final _owner = TextEditingController(
    text: widget.account?.accountName ?? '',
  );
  late final _number = TextEditingController(
    text: widget.account?.accountNumber ?? '',
  );
  late final _branch = TextEditingController(
    text: widget.account?.branch ?? '',
  );
  late bool _makeDefault =
      widget.account?.isDefault ??
      (LandlordDemoStore.instance.defaultPaymentAccount == null);

  @override
  void dispose() {
    _bank.dispose();
    _owner.dispose();
    _number.dispose();
    _branch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.account == null
          ? 'Thêm tài khoản nhận tiền'
          : 'Sửa tài khoản nhận tiền',
    ),
    content: SizedBox(
      width: 430,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _bank,
              decoration: const InputDecoration(
                labelText: 'Ngân hàng',
                hintText: 'Ví dụ: Vietcombank',
              ),
            ),
            TextField(
              controller: _owner,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Tên chủ tài khoản'),
            ),
            TextField(
              controller: _number,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tài khoản',
                helperText: 'Từ 6 đến 20 chữ số',
              ),
            ),
            TextField(
              controller: _branch,
              decoration: const InputDecoration(
                labelText: 'Chi nhánh hoặc ghi chú (không bắt buộc)',
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _makeDefault,
              onChanged: (value) =>
                  setState(() => _makeDefault = value ?? false),
              title: const Text(
                'Dùng làm tài khoản mặc định',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Hiển thị trong hướng dẫn chuyển khoản mới.',
                style: TextStyle(fontSize: 10),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Text(
              'Thông tin được che bớt khi hiển thị trong danh sách.',
              style: TextStyle(color: landlordMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: _save, child: const Text('Lưu tài khoản')),
    ],
  );

  void _save() {
    final number = _number.text.replaceAll(RegExp(r'\s+'), '');
    if (_bank.text.trim().isEmpty ||
        _owner.text.trim().isEmpty ||
        !RegExp(r'^\d{6,20}$').hasMatch(number)) {
      showLandlordMessage(
        context,
        'Kiểm tra tên ngân hàng, chủ tài khoản và số tài khoản.',
      );
      return;
    }
    Navigator.pop(
      context,
      _PaymentAccountDraft(
        bankName: _bank.text.trim(),
        accountName: _owner.text.trim(),
        accountNumber: number,
        branch: _branch.text.trim(),
        makeDefault: _makeDefault,
      ),
    );
  }
}
