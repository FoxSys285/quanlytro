import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/app_persistence.dart';
import '../../../../data/local_auth.dart';
import '../../tenant_ui.dart';
import '../../tenant_detail_ui.dart';
import '../../../landlord/landlord_demo_store.dart';
import '../../../landlord/finance/landlord_finance_models.dart';
import '../../../shared/rental/tenant_session.dart';
import '../../../shared/media/media_permission_service.dart';
import 'tenant_bank_qr.dart';

void showTenantPaymentInstructions(
  BuildContext context, {
  required String invoiceId,
  required String method,
  LandlordDemoStore? store,
  String? tenantId,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => TenantPaymentInstructionsSheet(
      invoiceId: invoiceId,
      method: method,
      store: store,
      tenantId: tenantId,
    ),
  );
}

class TenantPaymentInstructionsSheet extends StatefulWidget {
  const TenantPaymentInstructionsSheet({
    super.key,
    required this.invoiceId,
    required this.method,
    this.store,
    String? tenantId,
  }) : _tenantId = tenantId ?? '';
  final String invoiceId;
  final String method;
  final LandlordDemoStore? store;
  final String _tenantId;
  String get tenantId =>
      _tenantId.isEmpty ? TenantSession.currentTenantId : _tenantId;
  @override
  State<TenantPaymentInstructionsSheet> createState() =>
      _TenantPaymentInstructionsSheetState();
}

class _TenantPaymentInstructionsSheetState
    extends State<TenantPaymentInstructionsSheet> {
  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _form = GlobalKey<FormState>();
  Uint8List? _proof;
  String? _proofName;
  String? _error;
  LandlordPayment? _submittedPayment;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _amount.text = (_store.invoiceById(widget.invoiceId)?.remaining ?? 0)
        .toString();
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    try {
      if (!await MediaPermissionService.checkBeforePicker(
        RentalMediaKind.image,
      )) {
        if (mounted) {
          setState(
            () => _error = 'Cần quyền truy cập ảnh để chọn ảnh minh chứng.',
          );
        }
        return;
      }
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 10 * 1024 * 1024) {
        setState(() => _error = 'Ảnh minh chứng tối đa 10 MB.');
        return;
      }
      setState(() {
        _proof = bytes;
        _proofName = image.name;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không mở được ảnh. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_submittedPayment == null && !_form.currentState!.validate()) return;
    setState(() => _submitting = true);
    var closed = false;
    try {
      _submittedPayment ??= _store.submitPayment(
        tenantId: widget.tenantId,
        invoiceId: widget.invoiceId,
        amount: int.parse(_amount.text.trim()),
        reference: widget.method == 'Chuyển khoản' ? _reference.text : '',
        method: widget.method,
        proofBytes: widget.method == 'Chuyển khoản' ? _proof : null,
        proofName: widget.method == 'Chuyển khoản' ? _proofName : null,
      );
      final persistence = AppPersistence.current;
      if (persistence == null && LocalAuth.instance.isCloudMode) {
        throw StateError('Chưa kết nối phiên lưu Firebase.');
      }
      await persistence?.flush();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      closed = true;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.method == 'Tiền mặt'
                ? 'Đã gửi yêu cầu tiền mặt. Chờ chủ trọ xác nhận khi nhận tiền.'
                : 'Đã gửi thông tin chuyển khoản. Chờ chủ trọ đối chiếu.',
          ),
        ),
      );
    } catch (failure) {
      if (!mounted) return;
      final message = failure is ArgumentError
          ? failure.message.toString()
          : AppPersistence.saveFailureMessage(failure);
      setState(() => _error = message);
    } finally {
      if (mounted && !closed) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final invoice = _store.invoiceById(widget.invoiceId);
      if (invoice == null ||
          !_store.invoicesForTenant(widget.tenantId).contains(invoice)) {
        return const TenantBottomSheetSurface(
          child: Text('Không tìm thấy hóa đơn của bạn.'),
        );
      }
      final lease = _store.leaseById(invoice.leaseId)!;
      final account = _store.defaultPaymentAccount;
      final pending = _store.payments.any(
        (payment) =>
            payment.invoiceId == invoice.id &&
            payment.status == LandlordPaymentStatus.pending,
      );
      return TenantDetailTheme(
        child: TenantBottomSheetSurface(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TenantSheetHandle(),
                Text(
                  'Thanh toán hóa đơn · ${widget.method}',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '${landlordMonth(invoice.period)} · ${invoice.id}',
                  style: const TextStyle(color: tenantMuted, fontSize: 12),
                ),
                const SizedBox(height: 15),
                TenantSurface(
                  child: Column(
                    children: [
                      TenantDetailRow(
                        label: 'Còn phải trả',
                        value: formatTenantMoney(invoice.remaining),
                        emphasized: true,
                      ),
                      if (widget.method == 'Chuyển khoản' && account != null)
                        TenantBankQr(
                          bankName: account.bankName,
                          accountName: account.accountName,
                          accountNumber: account.accountNumber,
                          reference: invoice.id,
                          amount:
                              int.tryParse(_amount.text.trim()) ??
                              invoice.remaining,
                        ),
                      if (widget.method == 'Tiền mặt')
                        TenantDetailRow(
                          label: 'Địa điểm',
                          value: lease.cashPaymentLocation,
                        ),
                    ],
                  ),
                ),
                if (widget.method == 'Tiền mặt') ...[
                  const SizedBox(height: 10),
                  const TenantDetailNote(
                    'Yêu cầu tiền mặt chỉ chờ chủ trọ xác nhận. Hóa đơn chưa được ghi nhận đã thanh toán.',
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amount,
                  enabled: _submittedPayment == null && !_submitting,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Số tiền đã trả (đ)',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (value) {
                    final amount = int.tryParse(value?.trim() ?? '');
                    return amount == null ||
                            amount <= 0 ||
                            amount > invoice.remaining
                        ? 'Số tiền phải lớn hơn 0 và không vượt khoản còn phải trả.'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                if (widget.method == 'Chuyển khoản') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reference,
                    enabled: _submittedPayment == null && !_submitting,
                    decoration: const InputDecoration(
                      labelText: 'Mã giao dịch chuyển khoản',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nhập mã giao dịch để chủ trọ đối chiếu.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _submittedPayment == null && !_submitting
                        ? _pickProof
                        : null,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(_proofName ?? 'Chọn ảnh minh chứng (tùy chọn)'),
                  ),
                  if (_proof != null)
                    Image.memory(
                      _proof!,
                      height: 130,
                      errorBuilder: (_, _, _) =>
                          const Text('Không đọc được ảnh.'),
                    ),
                ],
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _submitting ||
                            (pending && _submittedPayment == null) ||
                            invoice.cancelled ||
                            invoice.remaining == 0
                        ? null
                        : _submit,
                    child: Text(
                      _submitting
                          ? 'Đang lưu…'
                          : _submittedPayment != null
                          ? 'Thử lưu lại'
                          : pending
                          ? 'Đang chờ chủ trọ xử lý'
                          : widget.method == 'Tiền mặt'
                          ? 'Gửi yêu cầu tiền mặt'
                          : 'Gửi thông tin chuyển khoản',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
