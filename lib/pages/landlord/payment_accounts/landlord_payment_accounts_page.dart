import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/app_persistence.dart';
import '../../shared/payments/vietqr_service.dart';
import '../finance/landlord_finance_models.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
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
      await AppPersistence.current?.flush();
      if (!context.mounted) return;
      showLandlordMessage(
        context,
        account == null
            ? 'Đã thêm tài khoản nhận tiền.'
            : 'Đã cập nhật thông tin tài khoản.',
      );
    } catch (failure) {
      if (!context.mounted) return;
      final message = failure is ArgumentError
          ? failure.message.toString()
          : AppPersistence.saveFailureMessage(failure);
      showLandlordMessage(context, message);
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
  final _form = GlobalKey<FormState>();
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
  late final Future<List<Map<String, dynamic>>> _banks = VietQrService.instance
      .loadBanks();
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
    footer: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 50),
              foregroundColor: const Color(0xFF526991),
              side: const BorderSide(color: Color(0xFFC9D8EB)),
              backgroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              backgroundColor: landlordBlue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Lưu tài khoản'),
          ),
        ),
      ],
    ),
    child: Form(
      key: _form,
      child: Column(
        children: [
          _bankField(),
          const SizedBox(height: 12),
          TextFormField(
            controller: _owner,
            maxLength: 100,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            decoration: landlordModernInputDecoration(
              'Tên chủ tài khoản',
              hintText: 'Ví dụ: NGUYEN VAN A',
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (value) {
              final name = (value ?? '').trim();
              if (name.isEmpty) return 'Nhập tên chủ tài khoản.';
              if (name.length > 100) return 'Tên tối đa 100 ký tự.';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _number,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: landlordModernInputDecoration(
              'Số tài khoản',
              hintText: 'Nhập số tài khoản ngân hàng',
              helperText: 'Từ 6 đến 20 chữ số',
              prefixIcon: const Icon(Icons.credit_card_rounded),
            ),
            validator: (value) => RegExp(r'^\d{6,20}$').hasMatch(
              (value ?? '').replaceAll(RegExp(r'\s+'), ''),
            )
                ? null
                : 'Số tài khoản cần có từ 6 đến 20 chữ số.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _branch,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: landlordModernInputDecoration(
              'Chi nhánh hoặc ghi chú',
              hintText: 'Không bắt buộc',
              prefixIcon: const Icon(Icons.notes_rounded),
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
            onChanged: (value) =>
                setState(() => _makeDefault = value ?? false),
            secondary: const Icon(Icons.star_outline_rounded),
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
    ),
  );

  Widget _bankField() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _banks,
    builder: (context, snapshot) {
      final banks = snapshot.data ?? const <Map<String, dynamic>>[];
      if (banks.isNotEmpty) return _bankPicker(banks);
      if (snapshot.connectionState == ConnectionState.waiting) {
        return InputDecorator(
          decoration: landlordModernInputDecoration(
            'Ngân hàng thụ hưởng',
            prefixIcon: const Icon(Icons.account_balance_rounded),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Đang tải danh sách ngân hàng...'),
            ],
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5DD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8C46C)),
            ),
            child: const Text(
              'Chưa tải được danh sách ngân hàng. Nhập tên ngân hàng thủ công.',
              style: TextStyle(color: Color(0xFF775512), fontSize: 12),
            ),
          ),
          TextFormField(
            controller: _bank,
            textInputAction: TextInputAction.next,
            decoration: landlordModernInputDecoration(
              'Ngân hàng',
              hintText: 'Ví dụ: Vietcombank',
              prefixIcon: const Icon(Icons.account_balance_rounded),
            ),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Nhập tên ngân hàng.'
                : null,
          ),
        ],
      );
    },
  );

  Widget _bankPicker(List<Map<String, dynamic>> banks) {
    final selectedBank = _matchingBank(banks, _bank.text);
    return DropdownButtonFormField<String>(
      initialValue: selectedBank == null ? null : '${selectedBank['bin']}',
      isExpanded: true,
      menuMaxHeight: 420,
      decoration: landlordModernInputDecoration(
        'Ngân hàng thụ hưởng',
        prefixIcon: const Icon(Icons.account_balance_rounded),
      ),
      items: [
        for (final bank in banks)
          DropdownMenuItem(
            value: '${bank['bin']}',
            child: Row(
              children: [
                _bankLogo(bank),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_bankShortName(bank)} - ${bank['name'] ?? _bankShortName(bank)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.25),
                  ),
                ),
              ],
            ),
          ),
      ],
      validator: (value) => value == null ? 'Chọn ngân hàng thụ hưởng.' : null,
      onChanged: (bin) {
        if (bin == null) return;
        final bank = banks.firstWhere((item) => '${item['bin']}' == bin);
        setState(() => _bank.text = _bankShortName(bank));
      },
    );
  }

  Widget _bankLogo(Map<String, dynamic> bank) {
    final logo = bank['logo'] as String?;
    final shortName = _bankShortName(bank);
    return Container(
      width: 36,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4E3FF)),
      ),
      clipBehavior: Clip.antiAlias,
      child: logo != null && logo.startsWith('http')
          ? Image.network(
              logo,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _bankInitial(shortName),
            )
          : _bankInitial(shortName),
    );
  }

  Widget _bankInitial(String shortName) => Text(
    shortName.length > 4 ? shortName.substring(0, 4) : shortName,
    maxLines: 1,
    overflow: TextOverflow.clip,
    style: const TextStyle(
      color: landlordBlue,
      fontSize: 9,
      fontWeight: FontWeight.w900,
    ),
  );

  String _bankShortName(Map<String, dynamic> bank) =>
      '${bank['shortName'] ?? bank['short_name'] ?? bank['code'] ?? bank['name'] ?? bank['bin']}';

  Map<String, dynamic>? _matchingBank(
    List<Map<String, dynamic>> banks,
    String bankName,
  ) {
    final normalized = _normalizeBankName(bankName);
    final exactName = bankName.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final bank in banks) {
      final names = [
        bank['shortName'],
        bank['short_name'],
        bank['code'],
        bank['name'],
        bank['bin'],
      ];
      if (names.any(
        (name) =>
            name is String &&
            (name.trim().toLowerCase() == exactName ||
                _normalizeBankName(name) == normalized),
      )) {
        return bank;
      }
    }
    return null;
  }

  String _normalizeBankName(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  void _save() {
    if (_form.currentState?.validate() != true) return;
    if (_bank.text.trim().isEmpty) {
      showLandlordMessage(context, 'Chọn ngân hàng thụ hưởng.');
      return;
    }
    final number = _number.text.replaceAll(RegExp(r'\s+'), '');
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
