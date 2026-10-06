import 'package:flutter/material.dart';

import '../../tenant_ui.dart';
import '../../../landlord/landlord_demo_store.dart';

void showTenantPaymentInstructions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => TenantPaymentInstructionsSheet(),
  );
}

class TenantPaymentInstructionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final account = LandlordDemoStore.instance.defaultPaymentAccount;
    return TenantBottomSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TenantSheetHandle(),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Thanh toán hóa đơn',
              style: TextStyle(
                color: tenantInk,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tháng 10, 2026 · HD-2026-10-0148',
              style: TextStyle(color: tenantMuted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 17),
          TenantSurface(
            child: Column(
              children: [
                Container(
                  width: 122,
                  height: 122,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: tenantLine),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    size: 82,
                    color: tenantInk,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  '4.670.000 đ',
                  style: TextStyle(
                    color: tenantGreenDark,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 15),
                TenantDataRow(
                  label: 'Ngân hàng',
                  value: account?.bankName ?? 'Chưa thiết lập',
                ),
                const TenantThinDivider(),
                TenantDataRow(
                  label: 'Chủ tài khoản',
                  value: account?.accountName ?? 'Chưa thiết lập',
                ),
                const TenantThinDivider(),
                TenantDataRow(
                  label: 'Số tài khoản',
                  value: account?.accountNumber ?? 'Chưa thiết lập',
                ),
                const TenantThinDivider(),
                const TenantDataRow(
                  label: 'Nội dung',
                  value: 'HD2026100148 MA',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Thông tin minh họa cho bản xem trước. Chưa phát sinh giao dịch thật.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tenantMuted, fontSize: 10, height: 1.45),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showTenantPreviewNotice(context),
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Gửi minh chứng thanh toán'),
              style: OutlinedButton.styleFrom(
                foregroundColor: tenantGreenDark,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
