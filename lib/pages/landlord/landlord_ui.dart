import 'package:flutter/material.dart';

import 'landlord_theme.dart';

const landlordBlue = Color(0xFF1679BC);
const landlordInk = Color(0xFF1B2935);
const landlordMuted = Color(0xFF74818C);
const landlordLine = Color(0xFFE7ECEF);
const landlordCanvas = Color(0xFFF5F7FA);

/// Compact profile header used by the four landlord home destinations.
class LandlordWorkspaceHeader extends StatelessWidget {
  const LandlordWorkspaceHeader({
    super.key,
    required this.profileName,
    required this.onOpenDrawer,
    required this.onProperties,
    required this.onSettings,
  });

  final String profileName;
  final VoidCallback onOpenDrawer;
  final VoidCallback onProperties;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final words = profileName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? 'CT'
        : words.length == 1
        ? words.first[0].toUpperCase()
        : '${words.first[0]}${words.last[0]}'.toUpperCase();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 5, 15, 8),
        child: Row(
          children: [
            Tooltip(
              message: 'Mở danh mục chức năng',
              child: Material(
                color: palette.surface,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onOpenDrawer,
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Center(
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: palette.primarySoft,
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: palette.accent,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                profileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _LandlordHeaderAction(
              tooltip: 'Nhà trọ đang quản lý',
              icon: Icons.favorite_rounded,
              color: const Color(0xFFE64975),
              onTap: onProperties,
            ),
            const SizedBox(width: 8),
            _LandlordHeaderAction(
              tooltip: 'Cài đặt',
              icon: Icons.settings_rounded,
              color: palette.ink,
              onTap: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _LandlordHeaderAction extends StatelessWidget {
  const _LandlordHeaderAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: LandlordPalette.of(context).surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    ),
  );
}

/// Full-bleed dashboard hero that keeps the profile actions over the property photo.
class LandlordDashboardHero extends StatelessWidget {
  const LandlordDashboardHero({
    super.key,
    required this.profileName,
    required this.title,
    required this.subtitle,
    required this.onOpenDrawer,
    required this.onProperties,
    required this.onSettings,
  });

  final String profileName;
  final String title;
  final String subtitle;
  final VoidCallback onOpenDrawer;
  final VoidCallback onProperties;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 286,
    clipBehavior: Clip.antiAlias,
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/landlord_home_hero.png',
          cacheWidth: 960,
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          excludeFromSemantics: true,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xF2F4FAFD),
                Color(0xE6F4FAFD),
                Color(0x8AF4FAFD),
                Color(0x08F4FAFD),
              ],
              stops: [0, 0.48, 0.72, 1],
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LandlordWorkspaceHeader(
              profileName: profileName,
              onOpenDrawer: onOpenDrawer,
              onProperties: onProperties,
              onSettings: onSettings,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 20, 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            color: LandlordPalette.of(context).primary,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'KHÔNG GIAN CHỦ TRỌ',
                            style: TextStyle(
                              color: LandlordPalette.of(context).accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF173A52),
                        fontSize: 26,
                        height: 1.1,
                        letterSpacing: -0.65,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4D687B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Compact page heading that scrolls with its destination content.
class LandlordWorkspaceIntroCard extends StatelessWidget {
  const LandlordWorkspaceIntroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.kicker,
    required this.imageAsset,
    required this.onOpenDrawer,
  });

  final String title;
  final String subtitle;
  final String kicker;
  final String imageAsset;
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.surface, palette.primarySoft],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.line),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imageAsset,
                cacheWidth: 192,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kicker,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 10,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: palette.surface.withValues(alpha: 0.88),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Mở danh mục chức năng',
                onPressed: onOpenDrawer,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.arrow_forward_rounded, color: palette.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Photo-led welcome banner shared by the landlord dashboard and setup flow.
class LandlordHeroBanner extends StatelessWidget {
  const LandlordHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.kicker = 'KHÔNG GIAN CHỦ TRỌ',
    this.icon = Icons.apartment_rounded,
  });

  final String title;
  final String subtitle;
  final String kicker;
  final IconData icon;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      return Container(
        width: double.infinity,
        height: compact ? 202 : 216,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2877A8).withValues(alpha: 0.11),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/landlord_home_hero.png',
              cacheWidth: 960,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              excludeFromSemantics: true,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF4F2F9FD),
                    Color(0xEAF2F9FD),
                    Color(0x88F2F9FD),
                    Color(0x00F2F9FD),
                  ],
                  stops: [0, 0.5, 0.72, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(compact ? 17 : 24, 17, 14, 17),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: compact
                      ? constraints.maxWidth * 0.67
                      : constraints.maxWidth * 0.56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              color: LandlordPalette.of(context).primary,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                kicker,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: LandlordPalette.of(context).accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 11),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF173A52),
                          fontSize: 23,
                          height: 1.12,
                          letterSpacing: -0.55,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4D687B),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

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
              constraints.maxWidth < 600 ? 16 : 30,
              18,
              constraints.maxWidth < 600 ? 16 : 30,
              36,
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
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.primarySoft, palette.surfaceAlt],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: palette.surface,
              child: Icon(
                Icons.apartment_rounded,
                color: palette.primary,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUẢN LÝ NHÀ TRỌ',
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 19,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
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
        borderRadius: BorderRadius.circular(22),
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
          borderRadius: BorderRadius.circular(22),
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
