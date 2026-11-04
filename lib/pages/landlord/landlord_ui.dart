import 'package:flutter/material.dart';

import 'landlord_theme.dart';

const landlordBlue = Color(0xFF3769D6);
const landlordInk = Color(0xFF1B2935);
const landlordMuted = Color(0xFF74818C);
const landlordLine = Color(0xFFE7ECEF);
const landlordCanvas = Color(0xFFF5F7FA);

class LandlordPageFrame extends StatelessWidget {
  const LandlordPageFrame({super.key, required this.children});

  final List<Widget> children; // <-- Tham số bắt buộc: children

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LandlordPalette.of(context).canvas,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              constraints.maxWidth < 600 ? 18 : 32,
              22,
              constraints.maxWidth < 600 ? 18 : 32,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LandlordPageTitle extends StatelessWidget {
  const LandlordPageTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class LandlordCard extends StatelessWidget {
  const LandlordCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.14
                  : 0.035,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class LandlordStatusPill extends StatelessWidget {
  const LandlordStatusPill(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class LandlordEmptyState extends StatelessWidget {
  const LandlordEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return LandlordCard(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.muted),
        ),
      ),
    );
  }
}

// Hàm hiển thị thanh thông báo (SnackBar) nổi ở cuối màn hình
void showLandlordMessage(BuildContext context, String message) {
  // Lấy bộ quản lý thông báo của màn hình hiện tại
  final quanLyThongBao = ScaffoldMessenger.of(context);

  // Nếu đang có thông báo cũ thì ẩn đi trước
  quanLyThongBao.hideCurrentSnackBar();

  // Tạo và hiển thị thông báo mới
  quanLyThongBao.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating, // Hiển thị dạng nổi
    ),
  );
}

// Hàm định dạng số tiền sang kiểu Việt Nam (ví dụ: 3500000 -> "3.500.000 đ")
String formatLandlordMoney(int amount) {
  // Chuyển số nguyên thành chuỗi ký tự (ví dụ: 3500 -> "3500")
  final chuoiSo = amount.toString();
  String ketQua = ''; // Chuỗi kết quả ban đầu rỗng

  // Dùng vòng lặp for duyệt từng chữ số từ trái qua phải
  for (int i = 0; i < chuoiSo.length; i++) {
    ketQua = '$ketQua${chuoiSo[i]}'; // Ghép chữ số hiện tại vào kết quả ketQua += chuoiSo[i];

    // Tính số chữ số còn lại phía sau
    final soChuSoConLai = chuoiSo.length - i - 1;

    // Cứ cách mỗi 3 chữ số (tính từ đuôi về) thì chèn thêm 1 dấu chấm "."
    if (soChuSoConLai > 0 && soChuSoConLai % 3 == 0) {
      ketQua = '$ketQua.';
    }
  }

  // Thêm đơn vị tiền tệ " đ" ở cuối
  return '$ketQua đ';
}

// Ví dụ truyền vào: 3500000
// → Kết quả trả về: '3.500.000 đ'.
// Truyền vào: 50000
// → Kết quả: '50.000 đ'.
// Cách hoạt động: Dùng vòng lặp duyệt từng số, cứ cách 3 chữ số (tính từ đuôi về) thì chèn thêm dấu . và gắn đuôi đ.

/// Tiện ích mở rộng tính tổng (sum) giống cú pháp LINQ trong C#
extension LandlordIterableNumX on Iterable<int> {
  int get sum => fold(0, (a, b) => a + b);
}
