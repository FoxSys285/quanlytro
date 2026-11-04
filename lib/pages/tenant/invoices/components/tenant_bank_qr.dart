import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/payments/vietqr_service.dart';
import '../../tenant_detail_ui.dart';
import '../../tenant_ui.dart';

class TenantBankQr extends StatefulWidget {
  const TenantBankQr({
    super.key,
    required this.bankName,
    required this.accountNumber,
    this.accountName = '',
    this.reference = '',
    this.amount,
    this.service,
  });
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String reference;
  final int? amount;
  final VietQrService? service;

  @override
  State<TenantBankQr> createState() => _TenantBankQrState();
}

class _TenantBankQrState extends State<TenantBankQr> {
  late Future<VietQrImage> _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TenantBankQr oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bankName != widget.bankName ||
        oldWidget.accountNumber != widget.accountNumber ||
        oldWidget.reference != widget.reference ||
        oldWidget.amount != widget.amount ||
        oldWidget.service != widget.service) {
      _load();
    }
  }

  void _load() {
    _image = (widget.service ?? VietQrService.instance).load(
      bankName: widget.bankName,
      accountNumber: widget.accountNumber,
      reference: widget.reference,
      amount: widget.amount,
    );
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đã sao chép $label.')));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TenantDetailRow(label: 'Ngân hàng nhận tiền', value: widget.bankName),
      if (widget.accountName.isNotEmpty)
        TenantDetailRow(label: 'Chủ tài khoản', value: widget.accountName),
      TenantDetailRow(label: 'Số tài khoản', value: widget.accountNumber),
      if (widget.reference.isNotEmpty)
        TenantDetailRow(
          label: 'Nội dung chuyển khoản',
          value: widget.reference,
        ),
      const SizedBox(height: 12),
      Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 252),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: tenantLine),
            borderRadius: BorderRadius.circular(18),
          ),
          child: FutureBuilder<VietQrImage>(
            future: _image,
            builder: (context, snapshot) {
              // Never display the previous account's QR while the new one loads.
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(height: 14),
                        Text(
                          'Đang tạo mã QR…',
                          style: TextStyle(color: tenantMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _failed(
                  snapshot.error is VietQrException
                      ? (snapshot.error as VietQrException).message
                      : 'Chưa tải được mã QR thanh toán.',
                );
              }
              return SvgPicture.string(
                snapshot.data!.svg,
                width: 224,
                height: 224,
                fit: BoxFit.contain,
                semanticsLabel:
                    'Mã VietQR chuyển khoản ${widget.bankName}, tài khoản ${widget.accountNumber}',
                errorBuilder: (_, _, _) =>
                    _failed('Không đọc được mã QR. Vui lòng thử lại.'),
              );
            },
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        widget.amount == null
            ? 'Quét bằng ứng dụng ngân hàng và nhập số tiền theo hóa đơn.'
            : 'Quét bằng ứng dụng ngân hàng để điền thông tin chuyển khoản.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: tenantMuted, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 5),
      const Text(
        'Kiểm tra tên người nhận trong ứng dụng ngân hàng trước khi chuyển tiền.',
        textAlign: TextAlign.center,
        style: TextStyle(color: tenantMuted, fontSize: 11, height: 1.5),
      ),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _copy(
              widget.accountNumber.replaceAll(RegExp(r'\s+'), ''),
              'số tài khoản',
            ),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Sao chép STK'),
          ),
          if (widget.reference.isNotEmpty)
            TextButton.icon(
              onPressed: () => _copy(widget.reference, 'nội dung chuyển khoản'),
              icon: const Icon(Icons.notes_rounded, size: 17),
              label: const Text('Sao chép nội dung'),
            ),
        ],
      ),
    ],
  );

  Widget _failed(String message) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.qr_code_2_rounded, size: 42, color: tenantMuted),
      const SizedBox(height: 10),
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: tenantMuted, fontSize: 12, height: 1.5),
      ),
      TextButton.icon(
        onPressed: () => setState(_load),
        icon: const Icon(Icons.refresh_rounded, size: 17),
        label: const Text('Thử lại'),
      ),
    ],
  );
}
