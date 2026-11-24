import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../data/app_persistence.dart';
import '../../data/firebase_media_store.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../landlord/properties/models/landlord_property.dart';
import '../landlord/finance/landlord_finance_models.dart';
import 'admin_ui.dart';
import '../shared/widgets/list_pagination.dart';

class AdminWorkspacePage extends StatefulWidget {
  const AdminWorkspacePage({super.key, required this.destination});
  final RoleDestination destination;
  @override
  State<AdminWorkspacePage> createState() => _AdminWorkspacePageState();
}

class _AdminWorkspacePageState extends State<AdminWorkspacePage> {
  AdminStore get _admin => AdminStore.instance;
  String _query = '';
  String _filter = 'pending';
  int _page = 0;
  final Set<String> _savingVerificationIds = {};

  Future<void> _commitVerificationChange({
    required String propertyId,
    required String successMessage,
    required VoidCallback apply,
  }) async {
    if (!_savingVerificationIds.add(propertyId)) return;
    setState(() {});
    var didApply = false;
    Map<String, dynamic>? beforeChange;
    try {
      final persistence = AppPersistence.current;
      if (persistence == null) {
        throw StateError('Phiên lưu dữ liệu chưa được khởi tạo.');
      }
      await persistence.waitForInitialSync();
      if (!mounted) return;
      beforeChange = _copyAdminReviewState();
      apply();
      didApply = true;
      await persistence.saveAdminChanges();
      if (mounted) adminMessage(context, successMessage);
    } catch (failure) {
      if (didApply && beforeChange != null) {
        _admin.restore(beforeChange);
        try {
          await AppPersistence.current?.saveAdminChanges();
        } catch (_) {
          // Keep the original save failure visible; the sync bar also exposes
          // the outstanding persistence error for a later retry.
        }
      }
      if (mounted) {
        adminMessage(
          context,
          'Chưa lưu được kết quả xét duyệt: ${AppPersistence.saveFailureMessage(failure)}',
        );
      }
    } finally {
      _savingVerificationIds.remove(propertyId);
      if (mounted) setState(() {});
    }
  }

  Map<String, dynamic> _copyAdminReviewState() {
    final snapshot = _admin.toMap();
    return {
      ...snapshot,
      'verificationProofs': Map<String, String>.from(
        snapshot['verificationProofs'] as Map,
      ),
      'reviewNotes': Map<String, String>.from(snapshot['reviewNotes'] as Map),
      'reviewRequestedAt': Map<String, String>.from(
        snapshot['reviewRequestedAt'] as Map,
      ),
      'reviewSubmissionAt': Map<String, String>.from(
        snapshot['reviewSubmissionAt'] as Map,
      ),
      'verified': Map<String, bool>.from(snapshot['verified'] as Map),
      'commissionRates': Map<String, int>.from(
        snapshot['commissionRates'] as Map,
      ),
      'logs': (snapshot['logs'] as List)
          .map((entry) => Map<String, String>.from(entry as Map))
          .toList(),
    };
  }

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
      if (id == 'property_verification' || id == 'moderation') {
        final verification = id == 'property_verification';
        children.add(
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tìm nhà trọ, chủ trọ, địa chỉ',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() {
              _query = v.trim().toLowerCase();
              _page = 0;
            }),
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
                if (verification)
                  (id: 'resubmitted', label: 'Đã gửi lại hồ sơ'),
                if (verification) (id: 'supplement', label: 'Chờ bổ sung'),
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
                  onSelected: (_) => setState(() {
                    _filter = item.id;
                    _page = 0;
                  }),
                ),
            ],
          ),
        );
        children.add(const SizedBox(height: 20));
        final matched = stores.where((s) {
          final p = s.property;
          final isVerified = admin.isVerified(p.id);
          final ready = verification ? isVerified : !admin.isHidden(p.id);
          final awaitingReview =
              verification && !isVerified && p.verificationSubmittedAt != null;
          return '${p.name} ${p.ownerName} ${p.address}'.toLowerCase().contains(
                _query,
              ) &&
              (_filter == 'all' ||
                  (_filter == 'resubmitted' &&
                      admin.verificationResubmitted(p.id)) ||
                  (_filter == 'supplement' &&
                      admin.pendingReviewNote(p.id).isNotEmpty) ||
                  (['pending', 'ready'].contains(_filter) &&
                      (_filter == 'ready'
                          ? ready
                          : verification
                          ? awaitingReview &&
                                admin.pendingReviewNote(p.id).isEmpty
                          : !ready)));
        }).toList();
        if (verification) {
          matched.sort((a, b) {
            final priority =
                (admin.verificationResubmitted(b.property.id) ? 1 : 0)
                    .compareTo(
                      admin.verificationResubmitted(a.property.id) ? 1 : 0,
                    );
            if (priority != 0) return priority;
            return (b.property.verificationSubmittedAt ?? DateTime(1970))
                .compareTo(
                  a.property.verificationSubmittedAt ?? DateTime(1970),
                );
          });
        }
        children.add(
          Text(
            '${matched.length} nhà trọ',
            style: const TextStyle(color: adminMuted),
          ),
        );
        children.add(const SizedBox(height: 12));
        for (final store in matched.skip(_page * 10).take(10)) {
          children.add(_property(context, store, verification));
        }
        if (matched.isEmpty) {
          children.add(
            const AdminPanel(
              child: Text('Không có nhà trọ phù hợp với bộ lọc.'),
            ),
          );
        }
        children.add(
          ListPagination(
            total: matched.length,
            page: _page,
            pageSize: 10,
            onChanged: (page) => setState(() => _page = page),
          ),
        );
      } else if (id == 'audit_logs') {
        if (admin.logs.isEmpty) {
          children.add(
            const AdminPanel(child: Text('Chưa có hoạt động được ghi nhận.')),
          );
        }
        for (final log in admin.logs.skip(_page * 10).take(10)) {
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
        children.add(
          ListPagination(
            total: admin.logs.length,
            page: _page,
            pageSize: 10,
            onChanged: (page) => setState(() => _page = page),
          ),
        );
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

  Widget _property(
    BuildContext context,
    LandlordDemoStore store,
    bool verification,
  ) {
    final admin = _admin;
    final p = store.property;
    final verified = admin.isVerified(p.id);
    final saving = _savingVerificationIds.contains(p.id);
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
                saving
                    ? 'Đang lưu kết quả'
                    : verified
                    ? 'Đã xác minh'
                    : admin.verificationResubmitted(p.id)
                    ? 'Đã gửi lại hồ sơ'
                    : admin.pendingReviewNote(p.id).isNotEmpty
                    ? 'Chờ chủ trọ bổ sung'
                    : issues.isEmpty
                    ? 'Sẵn sàng kiểm tra'
                    : 'Cần bổ sung',
                color: saving
                    ? adminBlue
                    : verified
                    ? adminGreen
                    : adminGold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(p.address),
          if (verification && admin.verificationResubmitted(p.id))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Chủ trọ đã gửi lại hồ sơ ngày ${landlordDate(p.verificationSubmittedAt!)} '
                '${TimeOfDay.fromDateTime(p.verificationSubmittedAt!).format(context)}. Cần kiểm tra lại.',
                style: const TextStyle(
                  color: adminBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
          if (verification && p.verificationDocuments.isNotEmpty) ...[
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text(
                'Giấy tờ xác minh',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                'Đã nhận ${p.verificationDocuments.fold<int>(0, (sum, document) => sum + document.files.length)} ảnh minh chứng',
              ),
              children: [
                for (final document in p.verificationDocuments)
                  for (final file in document.files)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 8, right: 4),
                      leading: const Icon(
                        Icons.image_outlined,
                        color: adminBlue,
                      ),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_verificationDocumentName(document.id)),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _previewVerificationFile(context, file),
                    ),
              ],
            ),
          ],
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
                'Đủ thông tin và giấy tờ. Mở từng ảnh minh chứng để đối chiếu trước khi duyệt.',
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
                  onPressed:
                      !authorized || saving || (!verified && issues.isNotEmpty)
                      ? null
                      : () async {
                          if (!await adminConfirm(
                            context,
                            verified
                                ? 'Thu hồi xác minh?'
                                : 'Xác minh thông tin nhà trọ?',
                            '${p.name}\n${verified ? 'Nhà trọ sẽ trở về trạng thái cần kiểm tra.' : 'Xác nhận đã đối chiếu thông tin chủ trọ, giấy tờ tùy thân và giấy tờ về quyền cho thuê.'}',
                          )) {
                            return;
                          }
                          if (!context.mounted) return;
                          final nextValue = !verified;
                          await _commitVerificationChange(
                            propertyId: p.id,
                            successMessage: nextValue
                                ? 'Đã duyệt và lưu trạng thái xác minh nhà trọ.'
                                : 'Đã thu hồi và lưu trạng thái xác minh nhà trọ.',
                            apply: () => admin.verify(p.id, nextValue),
                          );
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          verified
                              ? Icons.undo_rounded
                              : Icons.verified_outlined,
                          size: 18,
                        ),
                  label: Text(
                    saving
                        ? 'Đang lưu…'
                        : verified
                        ? 'Thu hồi xác minh'
                        : 'Xác minh thông tin',
                  ),
                ),
                OutlinedButton(
                  onPressed: !authorized || saving
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
                          await _commitVerificationChange(
                            propertyId: p.id,
                            successMessage: 'Đã gửi yêu cầu bổ sung hồ sơ.',
                            apply: () => admin.requestSupplement(p.id, reason),
                          );
                        },
                  child: const Text('Yêu cầu bổ sung'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Dấu xác minh thể hiện kết quả đối chiếu trong ứng dụng, không thay thế xác nhận của cơ quan nhà nước.',
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

  Future<void> _previewVerificationFile(
    BuildContext context,
    PropertyVerificationFile file,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _VerificationPreviewDialog(file: file),
    );
  }

  String _verificationDocumentName(String id) => switch (id) {
    'portrait' => 'Ảnh chân dung chủ trọ',
    'identity' => 'CCCD / thẻ căn cước',
    'ownership' => 'Sổ đỏ / sổ hồng',
    'authorization' => 'Giấy ủy quyền cho thuê nhà',
    _ => 'Giấy tờ xác minh',
  };
}

class _VerificationPreviewDialog extends StatefulWidget {
  const _VerificationPreviewDialog({required this.file});

  final PropertyVerificationFile file;

  @override
  State<_VerificationPreviewDialog> createState() =>
      _VerificationPreviewDialogState();
}

class _VerificationPreviewDialogState
    extends State<_VerificationPreviewDialog> {
  late Future<Uint8List?> _image = _loadImage();

  Future<Uint8List?> _loadImage() async {
    final bytes = widget.file.bytes;
    if (bytes != null) return bytes;
    final path = widget.file.storagePath;
    if (path == null || path.isEmpty) return null;
    return FirebaseMediaStore().downloadPrivateAsset(
      path,
      maxBytes: 10 * 1024 * 1024,
    );
  }

  void _retry() => setState(() => _image = _loadImage());

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
      child: FutureBuilder<Uint8List?>(
        future: _image,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bytes = snapshot.data;
          if (snapshot.hasError || bytes == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image_outlined, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c \u1ea3nh minh ch\u1ee9ng.',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Th\u1eed l\u1ea1i'),
                  ),
                ],
              ),
            );
          }
          return InteractiveViewer(
            child: Image.memory(bytes, fit: BoxFit.contain, cacheWidth: 1200),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('\u0110\u00f3ng'),
      ),
    ],
  );
}
