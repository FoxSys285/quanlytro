import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../landlord/finance/landlord_finance_models.dart';
import 'admin_ui.dart';
import 'admin_dashboard.dart';
import 'admin_users_page.dart';

class AdminWorkspacePage extends StatefulWidget {
  const AdminWorkspacePage({super.key, required this.destination});
  final RoleDestination destination;
  @override
  State<AdminWorkspacePage> createState() => _AdminWorkspacePageState();
}

class _AdminWorkspacePageState extends State<AdminWorkspacePage> {
  AdminStore get _admin => AdminStore.instance;
  late final Future<List<AdminAccount>>? _cloudAccounts =
      LocalAuth.instance.isCloudMode && LocalAuth.instance.role == AppRole.admin
      ? loadAdminAccounts()
      : null;
  String _query = '';
  String _filter = 'all';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      RentalPortfolio.instance,
      AdminStore.instance,
      LocalAuth.instance,
    ]),
    builder: (context, _) {
      final stores = RentalPortfolio.instance.stores;
      final admin = _admin;
      final id = widget.destination.id;
      final children = <Widget>[const AdminSyncBar()];
      if (id == 'dashboard') {
        if (_cloudAccounts != null) {
          return FutureBuilder<List<AdminAccount>>(
            future: _cloudAccounts,
            builder: (context, snapshot) => _dashboard(
              context,
              stores,
              admin,
              userCount: snapshot.data?.length,
            ),
          );
        }
        return _dashboard(context, stores, admin, userCount: null);
      }
      if (id == 'property_verification' || id == 'moderation') {
        final verification = id == 'property_verification';
        children.add(
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tìm nhà trọ, chủ trọ, địa chỉ',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        );
        children.add(const SizedBox(height: 16));
        children.add(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in [
                (id: 'all', label: 'Tất cả'),
                (
                  id: 'pending',
                  label: verification ? 'Chờ xác minh' : 'Đang ẩn',
                ),
                (
                  id: 'ready',
                  label: verification ? 'Đã xác minh' : 'Đang hiển thị',
                ),
              ])
                ChoiceChip(
                  label: Text(item.label),
                  selected: _filter == item.id,
                  onSelected: (_) => setState(() => _filter = item.id),
                ),
            ],
          ),
        );
        children.add(const SizedBox(height: 20));
        final matched = stores.where((s) {
          final p = s.property;
          final ready = verification
              ? admin.isVerified(p.id)
              : !admin.isHidden(p.id);
          return '${p.name} ${p.ownerName} ${p.address}'.toLowerCase().contains(
                _query,
              ) &&
              (_filter == 'all' || (_filter == 'ready' ? ready : !ready));
        }).toList();
        children.add(
          Text(
            '${matched.length} nhà trọ',
            style: const TextStyle(color: adminMuted),
          ),
        );
        children.add(const SizedBox(height: 12));
        for (final store in matched) {
          children.add(_property(context, store, verification));
        }
        if (matched.isEmpty) {
          children.add(
            const AdminPanel(
              child: Text('Không có nhà trọ phù hợp với bộ lọc.'),
            ),
          );
        }
      } else if (id == 'audit_logs') {
        if (admin.logs.isEmpty) {
          children.add(
            const AdminPanel(child: Text('Chưa có hoạt động được ghi nhận.')),
          );
        }
        for (final log in admin.logs) {
          final at = DateTime.tryParse(log['at'] ?? '');
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: adminMuted,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['action'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${log['actor']} · ${at == null ? '—' : '${landlordDate(at)} ${TimeOfDay.fromDateTime(at).format(context)}'}',
                          style: const TextStyle(
                            color: adminMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
      return AdminFrame(
        title: widget.destination.label,
        subtitle: id == 'property_verification'
            ? 'Kiểm tra thông tin và hình ảnh trước khi duyệt. Thay đổi thông tin sẽ cần xác minh lại.'
            : id == 'moderation'
            ? 'Kiểm soát khả năng hiển thị tin đăng trên mục Khám phá.'
            : 'Lịch sử thao tác quản trị, xác minh và đối soát hoa hồng.',
        children: children,
      );
    },
  );

  Widget _dashboard(
    BuildContext context,
    List<LandlordDemoStore> stores,
    AdminStore admin, {
    int? userCount,
  }) => AdminDashboard(stores: stores, admin: admin, userCount: userCount);

  Widget _property(
    BuildContext context,
    LandlordDemoStore store,
    bool verification,
  ) {
    final admin = _admin;
    final p = store.property;
    final verified = admin.isVerified(p.id);
    final issues = AdminStore.verificationIssues(store);
    final authorized = LocalAuth.instance.role == AppRole.admin;
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (verification &&
              (p.imageBytes?.isNotEmpty == true || p.imageUrl.isNotEmpty)) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AdminPropertyPhoto(property: p, height: 160),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: adminInk,
                ),
              ),
              AdminStatus(
                verified
                    ? 'Đã xác minh'
                    : issues.isEmpty
                    ? 'Sẵn sàng kiểm tra'
                    : 'Cần bổ sung',
                color: verified ? adminGreen : adminGold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(p.address),
          const SizedBox(height: 6),
          Text(
            '${p.ownerName} · ${p.phone}',
            style: const TextStyle(color: adminMuted),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Giới thiệu nhà trọ',
              style: TextStyle(fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(p.description),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (verification) ...[
            Text(
              '${store.catalog.length} phòng · ${store.roomTypes.length} loại phòng',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (issues.isNotEmpty) ...[
              const Text(
                'THÔNG TIN CÒN THIẾU',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: adminGold,
                ),
              ),
              const SizedBox(height: 8),
              for (final issue in issues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $issue'),
                ),
            ] else
              const Text(
                'Đủ các thông tin cơ bản. Kiểm tra ảnh và liên hệ chủ trọ trước khi xác minh.',
                style: TextStyle(color: adminGreen),
              ),
            if (admin.reviewNote(p.id).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Yêu cầu bổ sung: ${admin.reviewNote(p.id)}',
                  style: const TextStyle(color: adminGold),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: !authorized || (!verified && issues.isNotEmpty)
                      ? null
                      : () async {
                          if (!await adminConfirm(
                            context,
                            verified
                                ? 'Thu hồi xác minh?'
                                : 'Xác minh thông tin nhà trọ?',
                            '${p.name}\n${verified ? 'Nhà trọ sẽ trở về trạng thái cần kiểm tra.' : 'Xác nhận đã kiểm tra thông tin cơ bản và ảnh. Đây không phải xác minh giấy tờ pháp lý.'}',
                          )) {
                            return;
                          }
                          if (!context.mounted) return;
                          try {
                            admin.verify(p.id, !verified);
                          } on ArgumentError catch (e) {
                            adminMessage(context, '${e.message}');
                          }
                        },
                  icon: Icon(
                    verified ? Icons.undo_rounded : Icons.verified_outlined,
                    size: 18,
                  ),
                  label: Text(
                    verified ? 'Thu hồi xác minh' : 'Xác minh thông tin',
                  ),
                ),
                OutlinedButton(
                  onPressed: !authorized
                      ? null
                      : () async {
                          final reason = await adminInput(
                            context,
                            title: 'Yêu cầu bổ sung hồ sơ',
                            label: 'Nội dung cần bổ sung (ít nhất 10 ký tự)',
                            initial: issues.isEmpty
                                ? ''
                                : 'Vui lòng bổ sung: ${issues.join(', ')}.',
                          );
                          if (reason == null || !context.mounted) return;
                          try {
                            admin.requestSupplement(p.id, reason);
                          } on ArgumentError catch (e) {
                            adminMessage(context, '${e.message}');
                          }
                        },
                  child: const Text('Yêu cầu bổ sung'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Xác minh mức độ đầy đủ thông tin. Dự án chưa có hồ sơ giấy tờ sở hữu để xác minh pháp lý.',
              style: TextStyle(fontSize: 12, color: adminMuted),
            ),
          ] else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hiển thị tin trong Khám phá'),
              subtitle: Text(
                admin.isHidden(p.id)
                    ? 'Đang ẩn tin đăng'
                    : 'Người thuê có thể tìm thấy tin đăng',
              ),
              value: !admin.isHidden(p.id),
              onChanged: !authorized
                  ? null
                  : (v) async {
                      if (!await adminConfirm(
                        context,
                        v ? 'Hiện lại tin đăng?' : 'Ẩn tin đăng?',
                        p.name,
                      )) {
                        return;
                      }
                      if (!context.mounted) return;
                      try {
                        admin.setHidden(p.id, !v);
                      } on ArgumentError catch (e) {
                        adminMessage(context, '${e.message}');
                      }
                    },
            ),
        ],
      ),
    );
  }
}
