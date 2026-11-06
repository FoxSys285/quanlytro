import 'package:flutter/material.dart';

import '../landlord_theme.dart';

import '../finance/landlord_finance_models.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_ui.dart';

class LandlordPaymentAccountsPage extends StatelessWidget {
  const LandlordPaymentAccountsPage({super.key});

  LandlordDemoStore get _store => LandlordDemoStore.activeInstance;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => LandlordFeaturePage(
      title: 'Tài khoản nhận tiền',
      subtitle: 'Quản lý thông tin chuyển khoản của nhà trọ.',
      icon: Icons.account_balance_outlined,
      children: [
        LandlordGlassSection(
          title: 'Danh sách tài khoản',
          subtitle: 'Tài khoản mặc định được dùng trong hướng dẫn thanh toán.',
          trailing: FilledButton.icon(
            onPressed: () => _edit(context),
            style: FilledButton.styleFrom(
              backgroundColor: landlordBlue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Thêm tài khoản'),
          ),
        ),
        LandlordGlassCard(
          tint: const Color(0xFF2E8BFF),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: landlordBlue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Chỉ lưu thông tin tài khoản để hiển thị cho người thuê. Ứng dụng không yêu cầu mật khẩu ngân hàng, mã PIN hoặc OTP.',
                  style: TextStyle(
                    color: LandlordPalette.of(context).ink,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_store.paymentAccounts.isEmpty)
          LandlordGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: landlordBlue,
                  size: 36,
                ),
                const SizedBox(height: 10),
                const Text('Chưa có tài khoản nhận tiền.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm tài khoản'),
                ),
              ],
            ),
          ),
        for (final account in _store.paymentAccounts)
          _accountCard(context, account),
        const SizedBox(height: 4),
        Text(
          'Thay đổi tài khoản mặc định áp dụng cho hướng dẫn thanh toán mới.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: LandlordPalette.of(context).muted,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );

  Widget _accountCard(BuildContext context, LandlordPaymentAccount account) {
    final defaultAccount = account.isDefault && account.isActive;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: LandlordGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: landlordBlue.withValues(alpha: 0.1),
                  child: Icon(
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
                        style: TextStyle(
                          color: LandlordPalette.of(context).ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        account.accountName,
                        style: TextStyle(
                          color: LandlordPalette.of(context).muted,
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
            Divider(height: 22),
            _line(context, 'Số tài khoản', account.maskedNumber),
            if (account.branch.isNotEmpty) ...[
              const SizedBox(height: 7),
              _line(context, 'Ghi chú', account.branch),
            ],
            const SizedBox(height: 11),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 7,
              runSpacing: 5,
              children: [
                LandlordStatusPill(
                  account.isVerified ? 'Đã xác minh' : 'Chưa xác minh',
                  color: account.isVerified
                      ? const Color(0xFF16836F)
                      : const Color(0xFFE08A1E),
                ),
                LandlordStatusPill(
                  account.isActive ? 'Đang sử dụng' : 'Đã tạm ngưng',
                  color: account.isActive
                      ? const Color(0xFF16836F)
                      : LandlordPalette.of(context).muted,
                ),
                IconButton(
                  tooltip: 'Chỉnh sửa',
                  onPressed: () => _edit(context, account),
                  icon: Icon(Icons.edit_outlined, size: 19),
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
                  icon: Icon(Icons.star_outline_rounded, size: 17),
                  label: Text('Đặt làm mặc định'),
                ),
              ),
            ],
            Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cho phép người thuê chuyển khoản vào tài khoản này',
                    style: TextStyle(
                      color: LandlordPalette.of(context).ink,
                      fontSize: 11,
                    ),
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
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) => Row(
    children: [
      SizedBox(
        width: 100,
        child: Text(
          label,
          style: TextStyle(
            color: LandlordPalette.of(context).muted,
            fontSize: 11,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            color: LandlordPalette.of(context).ink,
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
      (LandlordDemoStore.activeInstance.defaultPaymentAccount == null);

  @override
  void dispose() {
    _bank.dispose();
    _owner.dispose();
    _number.dispose();
    _branch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LandlordFormDialog(
    title: widget.account == null
        ? 'Thêm tài khoản nhận tiền'
        : 'Sửa tài khoản nhận tiền',
    subtitle: 'Nhập thông tin để người thuê chuyển khoản chính xác.',
    icon: Icons.account_balance_outlined,
    child: Column(
      children: [
        TextField(
          controller: _bank,
          decoration: landlordModernInputDecoration(
            'Ngân hàng',
            hintText: 'Ví dụ: Vietcombank',
            prefixIcon: const Icon(Icons.account_balance_outlined),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _owner,
          textCapitalization: TextCapitalization.characters,
          decoration: landlordModernInputDecoration('Tên chủ tài khoản'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _number,
          keyboardType: TextInputType.number,
          decoration: landlordModernInputDecoration(
            'Số tài khoản',
            helperText: 'Từ 6 đến 20 chữ số',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _branch,
          decoration: landlordModernInputDecoration(
            'Chi nhánh hoặc ghi chú',
            hintText: 'Không bắt buộc',
          ),
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          value: _makeDefault,
          activeColor: landlordBlue,
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Color(0xFFD4E3FF)),
          ),
          onChanged: (value) => setState(() => _makeDefault = value ?? false),
          title: const Text(
            'Dùng làm tài khoản mặc định',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Hiển thị trong hướng dẫn chuyển khoản mới.',
            style: TextStyle(fontSize: 10),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 9),
        Text(
          'Thông tin tài khoản sẽ được che bớt trong danh sách.',
          style: TextStyle(
            color: LandlordPalette.of(context).muted,
            fontSize: 10,
          ),
        ),
      ],
    ),
    footer: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: landlordBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          ),
          icon: const Icon(Icons.save_outlined, size: 17),
          label: const Text('Lưu tài khoản'),
        ),
      ],
    ),
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
