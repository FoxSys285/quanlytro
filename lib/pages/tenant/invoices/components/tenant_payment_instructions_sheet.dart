import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../tenant_ui.dart';
import '../../../landlord/landlord_demo_store.dart';
import '../../../landlord/finance/landlord_finance_models.dart';
import '../../../shared/rental/tenant_session.dart';

void showTenantPaymentInstructions(
  BuildContext context, {
  required String invoiceId,
  LandlordDemoStore? store,
  String tenantId = TenantSession.tenantId,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => TenantPaymentInstructionsSheet(
      invoiceId: invoiceId,
      store: store,
      tenantId: tenantId,
    ),
  );
}

class TenantPaymentInstructionsSheet extends StatefulWidget {
  const TenantPaymentInstructionsSheet({
    super.key,
    required this.invoiceId,
    this.store,
    this.tenantId = TenantSession.tenantId,
  });
  final String invoiceId;
  final LandlordDemoStore? store;
  final String tenantId;
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
  String? _method;
  Uint8List? _proof;
  String? _proofName;
  String? _error;

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

  void _submit() {
    if (!_form.currentState!.validate()) return;
    try {
      _store.submitPayment(
        tenantId: widget.tenantId,
        invoiceId: widget.invoiceId,
        amount: int.parse(_amount.text.trim()),
        reference: _reference.text,
        method: _method!,
        proofBytes: _proof,
        proofName: _proofName,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã gửi thanh toán. Chờ chủ trọ đối chiếu và xác nhận.',
          ),
        ),
      );
    } on ArgumentError catch (error) {
      setState(() => _error = error.message.toString());
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
      final methods = [
        if (lease.bankTransferEnabled && account != null) 'Chuyển khoản',
        if (lease.cashPaymentEnabled) 'Tiền mặt',
      ];
      if (!methods.contains(_method)) {
        _method = methods.isEmpty ? null : methods.first;
      }
      final pending = _store.payments.any(
        (payment) =>
            payment.invoiceId == invoice.id &&
            payment.status == LandlordPaymentStatus.pending,
      );
      return TenantBottomSheetSurface(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TenantSheetHandle(),
              const Text(
                'Thanh toán hóa đơn',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              Text('${landlordMonth(invoice.period)} · ${invoice.id}'),
              const SizedBox(height: 15),
              TenantSurface(
                child: Column(
                  children: [
                    TenantDataRow(
                      label: 'Còn phải trả',
                      value: formatTenantMoney(invoice.remaining),
                      emphasized: true,
                    ),
                    if (_method == 'Chuyển khoản') ...[
                      TenantDataRow(
                        label: 'Ngân hàng nhận tiền hiện tại',
                        value: account!.bankName,
                      ),
                      TenantDataRow(
                        label: 'Chủ tài khoản',
                        value: account.accountName,
                      ),
                      TenantDataRow(
                        label: 'Số tài khoản',
                        value: account.accountNumber,
                      ),
                      TenantDataRow(label: 'Nội dung', value: invoice.id),
                    ],
                    if (_method == 'Tiền mặt')
                      TenantDataRow(
                        label: 'Địa điểm',
                        value: lease.cashPaymentLocation,
                      ),
                  ],
                ),
              ),
              if (methods.isEmpty)
                const Text(
                  'Chủ trọ chưa thiết lập phương thức nhận tiền khả dụng.',
                ),
              if (methods.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: ValueKey(_method),
                  initialValue: _method,
                  decoration: const InputDecoration(labelText: 'Phương thức'),
                  items: [
                    for (final method in methods)
                      DropdownMenuItem(value: method, child: Text(method)),
                  ],
                  onChanged: (value) => setState(() => _method = value),
                ),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền đã trả (đ)',
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
              TextFormField(
                controller: _reference,
                decoration: const InputDecoration(
                  labelText: 'Mã giao dịch / ghi chú trả tiền',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tham chiếu để chủ trọ đối chiếu.'
                    : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickProof,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(_proofName ?? 'Chọn ảnh minh chứng'),
              ),
              if (_proof != null)
                Image.memory(
                  _proof!,
                  height: 130,
                  errorBuilder: (_, _, _) => const Text('Không đọc được ảnh.'),
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed:
                    methods.isEmpty ||
                        pending ||
                        invoice.cancelled ||
                        invoice.remaining == 0
                    ? null
                    : _submit,
                child: Text(
                  pending ? 'Đang chờ chủ trọ duyệt' : 'Gửi thanh toán',
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
