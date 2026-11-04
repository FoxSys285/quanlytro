import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../landlord/properties/models/landlord_property.dart';
import '../../data/app_persistence.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import 'admin_demo_data.dart';

const adminInk = Color(0xFF1D2940);
const adminBlue = Color(0xFF535BC6);
const adminPurple = Color(0xFF7660B4);
const adminTeal = Color(0xFF167D72);
const adminOrange = Color(0xFFB34D39);
const adminMuted = Color(0xFF606C80);
const adminGold = Color(0xFF8D601E);
const adminLine = Color(0xFFE3E7E8);
const adminCanvas = Color(0xFFF5F6FB);
const adminGreen = Color(0xFF216B53);

class AdminDemoBar extends StatelessWidget {
  const AdminDemoBar({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AdminDemoData.instance,
    builder: (context, _) {
      final demo = AdminDemoData.instance;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: demo.enabled
              ? const Color(0xFFFFF1D9)
              : const Color(0xFFEEEFFC),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      demo.enabled
                          ? Icons.science_outlined
                          : Icons.play_circle_outline,
                      color: demo.enabled ? adminGold : adminBlue,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            demo.enabled
                                ? 'Đang dùng dữ liệu demo'
                                : 'Khám phá dữ liệu mẫu',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: adminInk,
                            ),
                          ),
                          if (demo.enabled)
                            const Text(
                              'Tự lưu trên máy · Bộ mẫu riêng',
                              style: TextStyle(fontSize: 11, color: adminMuted),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: demo.syncing
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              demo.toggle();
                            },
                      child: Text(demo.enabled ? 'Tắt demo' : 'Dùng demo'),
                    ),
                    if (demo.enabled)
                      PopupMenuButton<bool>(
                        tooltip: 'Lưu và tải dữ liệu mẫu',
                        enabled:
                            !demo.syncing &&
                            LocalAuth.instance.role == AppRole.admin,
                        icon: const Icon(
                          Icons.cloud_sync_outlined,
                          color: adminGold,
                        ),
                        onSelected: (download) => _sync(context, download),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: false,
                            child: ListTile(
                              leading: Icon(Icons.cloud_upload_outlined),
                              title: Text('Lưu Firebase'),
                            ),
                          ),
                          PopupMenuItem(
                            value: true,
                            child: ListTile(
                              leading: Icon(Icons.cloud_download_outlined),
                              title: Text('Tải Firebase'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (demo.enabled) ...[
                  if (demo.syncing) const LinearProgressIndicator(minHeight: 2),
                  if (demo.syncMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        demo.syncMessage,
                        style: const TextStyle(fontSize: 12, color: adminInk),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  Future<void> _sync(BuildContext context, bool download) async {
    final persistence = AppPersistence.current;
    if (persistence == null) {
      adminMessage(context, 'Mở ứng dụng và đăng nhập admin để đồng bộ.');
      return;
    }
    if (download &&
        !await adminConfirm(
          context,
          'Tải bộ demo từ Firebase?',
          'Bộ demo trên máy sẽ được thay bằng bản đã lưu trên Firebase.',
        )) {
      return;
    }
    try {
      await persistence.syncAdminDemo(download: download);
    } on ArgumentError catch (e) {
      if (context.mounted) adminMessage(context, '${e.message}');
    }
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
      return SingleChildScrollView(
        padding: EdgeInsets.all(constraints.maxWidth < 600 ? 20 : 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.15,
                    letterSpacing: -0.4,
                    fontWeight: FontWeight.w700,
                    color: adminInk,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(color: adminMuted, height: 1.5),
                ),
                const SizedBox(height: 20),
                ...children,
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: padding,
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: backgroundColor == Colors.white ? adminLine : backgroundColor,
      ),
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class AdminSection extends StatelessWidget {
  const AdminSection(this.title, {super.key, this.caption});
  final String title;
  final String? caption;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: adminInk,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            style: const TextStyle(color: adminMuted, height: 1.5),
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
                      style: const TextStyle(color: adminMuted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      item.value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: adminInk,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
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
              if (i > 0) const SizedBox(width: 24),
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
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback(),
          )
        : url.isNotEmpty
        ? Image.network(
            url,
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
                    color: Color(0xD91D2940),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    child: Text(
                      'Ảnh minh họa',
                      style: TextStyle(color: Colors.white, fontSize: 11),
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
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.multiline,
          maxLines: numeric ? 1 : 3,
          decoration: InputDecoration(labelText: label),
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
    ),
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
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, true);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ??
    false;
