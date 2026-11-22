import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/cloudinary_media_gateway.dart';
import '../landlord/properties/models/landlord_property.dart';
import '../../data/app_persistence.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';

const adminInk = Color(0xFF0B1220);
const adminBlue = Color(0xFF087FC1);
const adminPurple = Color(0xFF7046D3);
const adminTeal = Color(0xFF168FC2);
const adminOrange = Color(0xFFE11D48);
const adminMuted = Color(0xFF5D6B7E);
const adminGold = Color(0xFFD97706);
const adminLine = Color(0xFFE1E7F0);
const adminCanvas = Color(0xFFF4F7FB);
const adminGreen = Color(0xFF0D9488);
const adminHeaderBg = Color(0xFF0F172A);
const adminSurfaceTint = Color(0xFFF6F5FF);

class AdminBanner extends StatelessWidget {
  const AdminBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title, subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Container(
      constraints: const BoxConstraints(minHeight: 154),
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10253B), Color(0xFF0A4A6C), Color(0xFF087FC1)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -35,
            child: Icon(
              icon,
              size: 150,
              color: Colors.white.withValues(alpha: .07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .16),
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 23),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFE2F2FC),
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class AdminSyncBar extends StatelessWidget {
  const AdminSyncBar({super.key});
  @override
  Widget build(BuildContext context) {
    final persistence = AppPersistence.current;
    if (persistence == null) return const SizedBox.shrink();
    return ValueListenableBuilder<String>(
      valueListenable: persistence.saveStatus,
      builder: (context, status, _) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: adminLine),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    (persistence.error.value != null
                            ? adminOrange
                            : persistence.cloudConfirmed
                            ? adminGreen
                            : adminBlue)
                        .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                persistence.error.value != null
                    ? Icons.cloud_off_rounded
                    : persistence.cloudConfirmed
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_sync_rounded,
                size: 16,
                color: persistence.error.value != null
                    ? adminOrange
                    : persistence.cloudConfirmed
                    ? adminGreen
                    : adminBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 12,
                  color: adminMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: LocalAuth.instance.role != AppRole.admin
                  ? null
                  : () async {
                      try {
                        await persistence.saveAdminChanges();
                      } catch (e) {
                        if (context.mounted) {
                          adminMessage(
                            context,
                            e is StateError
                                ? e.message
                                : 'Chưa lưu được dữ liệu. Vui lòng thử lại.',
                          );
                        }
                      }
                    },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: adminBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: Text(
                persistence.error.value == null ? 'Đồng bộ' : 'Thử lại',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminFrame extends StatelessWidget {
  const AdminFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 28,
          compact ? 18 : 26,
          compact ? 16 : 28,
          compact ? 24 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _pageHeader(compact),
                SizedBox(height: compact ? 18 : 24),
                ...children,
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _pageHeader(bool compact) {
    final normalizedTitle = title.toLowerCase();
    final icon = switch (normalizedTitle) {
      final value when value.contains('tổng quan') =>
        Icons.space_dashboard_rounded,
      final value when value.contains('chủ trọ') => Icons.apartment_rounded,
      final value when value.contains('tài khoản') =>
        Icons.manage_accounts_rounded,
      final value
          when value.contains('thống kê') || value.contains('thanh toán') =>
        Icons.query_stats_rounded,
      final value when value.contains('xác minh') =>
        Icons.verified_user_rounded,
      final value when value.contains('hỗ trợ') => Icons.support_agent_rounded,
      final value when value.contains('nhật ký') => Icons.history_rounded,
      final value when value.contains('cấu hình') => Icons.tune_rounded,
      _ => Icons.admin_panel_settings_rounded,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 44 : 52,
          height: compact ? 44 : 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [adminBlue.withValues(alpha: .16), Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: adminBlue.withValues(alpha: .15)),
          ),
          child: Icon(icon, color: adminBlue, size: compact ? 22 : 25),
        ),
        SizedBox(width: compact ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QUẢN TRỊ HỆ THỐNG',
                style: TextStyle(
                  color: adminBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 22 : 27,
                  height: 1.2,
                  letterSpacing: -.5,
                  fontWeight: FontWeight.w800,
                  color: adminInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: adminMuted,
                  fontSize: compact ? 12 : 13,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
  });
  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: padding,
    decoration: BoxDecoration(
      color: gradient == null ? backgroundColor : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(
        color: gradient != null
            ? Colors.white.withValues(alpha: .14)
            : Color.lerp(adminLine, backgroundColor, .18)!,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0711233A),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class AdminStatus extends StatelessWidget {
  const AdminStatus(this.text, {super.key, this.color = adminMuted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Color.lerp(color, adminInk, 0.3),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class AdminSection extends StatelessWidget {
  const AdminSection(this.title, {super.key, this.caption});
  final String title;
  final String? caption;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 4,
              height: 21,
              decoration: BoxDecoration(
                color: adminBlue,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: adminInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                ),
              ),
            ),
          ],
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              caption!,
              style: const TextStyle(
                color: adminMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class AdminMetrics extends StatelessWidget {
  const AdminMetrics({super.key, required this.items});
  final List<({String label, String value, String detail})> items;
  @override
  Widget build(BuildContext context) => AdminPanel(
    child: LayoutBuilder(
      builder: (context, c) {
        Widget metric(int index) {
          final item = items[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: adminMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      item.value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: adminInk,
                        fontSize: 22,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.detail,
                style: const TextStyle(
                  color: adminMuted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          );
        }

        if (c.maxWidth < 620) {
          return Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 28, color: adminLine),
                metric(i),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 48,
                  color: adminLine,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
              Expanded(child: metric(i)),
            ],
          ],
        );
      },
    ),
  );
}

class AdminPropertyPhoto extends StatelessWidget {
  const AdminPropertyPhoto({
    super.key,
    required this.property,
    this.height = 140,
  });
  final LandlordProperty property;
  final double height;
  @override
  Widget build(BuildContext context) {
    final bytes = property.imageBytes;
    final url = property.imageUrl;
    Widget fallback() => const ColoredBox(
      color: Color(0xFFE9ECF5),
      child: Center(
        child: Icon(Icons.apartment_outlined, size: 36, color: adminMuted),
      ),
    );
    final image = bytes?.isNotEmpty == true
        ? Image.memory(
            bytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback(),
          )
        : url.startsWith('assets/')
        ? Image.asset(
            url,
            cacheWidth: 600,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback(),
          )
        : url.isNotEmpty
        ? Image.network(
            CloudinaryMediaGateway.optimizedImageUrl(url, width: 560),
            cacheWidth: 560,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback(),
          )
        : fallback();
    final sample =
        property.imageName?.contains('minh h') == true ||
        url.startsWith('assets/');
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Semantics(
        image: true,
        label: sample ? '${property.name} · Ảnh minh họa' : property.name,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.startsWith('assets/images/rental_api/'))
              ClipRect(child: Transform.scale(scale: 1.16, child: image))
            else
              image,
            if (sample && height >= 100)
              const Positioned(
                right: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xD90F172A),
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    child: Text(
                      'Ảnh minh họa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void adminMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

Future<String?> adminInput(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  bool numeric = false,
  String action = 'Lưu',
}) async {
  final controller = TextEditingController(text: initial);
  final route = DialogRoute<String>(
    context: context,
    builder: (context) {
      final dialogWidth = (MediaQuery.sizeOf(context).width - 88)
          .clamp(280.0, 440.0)
          .toDouble();
      return AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: adminBlue.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.edit_note_rounded, color: adminBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CẬP NHẬT THÔNG TIN',
                    style: TextStyle(
                      color: adminBlue,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: adminInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: dialogWidth,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.multiline,
            maxLines: numeric ? 1 : 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: label,
              alignLabelWithHint: !numeric,
              prefixIcon: Icon(
                numeric ? Icons.numbers_rounded : Icons.edit_rounded,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(action),
          ),
        ],
      );
    },
  );
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  controller.dispose();
  return result;
}

Future<bool> adminConfirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) {
        final caution = RegExp(
          r'khóa|thu hồi|ẩn tin|từ chối',
          caseSensitive: false,
        ).hasMatch(title);
        final actionColor = caution ? adminOrange : adminBlue;
        return AlertDialog(
          icon: Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              caution
                  ? Icons.warning_amber_rounded
                  : Icons.help_outline_rounded,
              color: actionColor,
              size: 27,
            ),
          ),
          title: Text(title, textAlign: TextAlign.center),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: adminMuted, height: 1.55),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: actionColor),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context, true);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    ) ??
    false;
