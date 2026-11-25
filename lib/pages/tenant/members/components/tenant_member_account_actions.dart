import 'package:flutter/material.dart';

import '../../../../data/app_persistence.dart';
import '../../../../data/local_auth.dart';

import 'package:image_picker/image_picker.dart';

import '../../../../data/firebase_media_store.dart';
import '../../../landlord/landlord_demo_store.dart';
import '../../../landlord/finance/landlord_finance_models.dart';
import '../../../shared/media/media_permission_service.dart';
import '../../../shared/rental/lease_member.dart';
import '../../tenant_detail_ui.dart';
import '../../tenant_ui.dart';

class TenantMemberAccountActions extends StatefulWidget {
  const TenantMemberAccountActions({
    super.key,
    required this.store,
    required this.member,
  });

  final LandlordDemoStore store;
  final LeaseMember member;

  @override
  State<TenantMemberAccountActions> createState() =>
      _TenantMemberAccountActionsState();
}

class _TenantMemberAccountActionsState
    extends State<TenantMemberAccountActions> {
  String? _busySlot;
  String? _error;

  Future<void> _upload(String slot) async {
    setState(() {
      _busySlot = slot;
      _error = null;
    });
    try {
      if (!await MediaPermissionService.checkBeforePicker(
        RentalMediaKind.image,
      )) {
        throw const FormatException('Không có quyền chọn ảnh.');
      }
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1440,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image == null) return;
      if (await image.length() > 10 * 1024 * 1024) {
        throw const FormatException('Mỗi ảnh tối đa 10 MB.');
      }
      final path =
          'lease-member-identity/${Uri.encodeComponent(widget.store.property.id)}/${Uri.encodeComponent(widget.member.tenantId)}/${Uri.encodeComponent(widget.member.id)}/$slot.jpg';
      final bytes = await image.readAsBytes();
      final uploadedPath = await FirebaseMediaStore().uploadPrivateImage(
        bytes,
        storagePath: path,
        fileName: '$slot.jpg',
        overwrite: true,
      );
      widget.store.updateMemberIdentityDocuments(
        widget.member.tenantId,
        identityFrontPath: slot == 'identity-front' ? uploadedPath : null,
        identityBackPath: slot == 'identity-back' ? uploadedPath : null,
        portraitPath: slot == 'portrait' ? uploadedPath : null,
      );
      await AppPersistence.current?.flush();
    } catch (error) {
      if (mounted) {
        final message = error is FormatException
            ? error.message
            : AppPersistence.saveFailureMessage(error);
        setState(() => _error = message);
      }
    } finally {
      if (mounted) setState(() => _busySlot = null);
    }
  }

  Future<void> _requestLeave() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _MemberLeaveDialog(),
    );
    if (reason == null || !mounted) return;
    final member = widget.member;
    final previous = (
      member.leaveReason,
      member.leaveRequestedAt,
      member.leaveEffectiveAt,
      member.leaveAcknowledgedAt,
    );
    try {
      widget.store.requestMemberLeave(
        tenantId: member.tenantId,
        reason: reason,
      );
      final persistence = AppPersistence.current;
      if (persistence == null && LocalAuth.instance.isCloudMode) {
        throw StateError('Chưa kết nối phiên lưu Firebase.');
      }
      await persistence?.flush();
    } catch (failure) {
      member
        ..leaveReason = previous.$1
        ..leaveRequestedAt = previous.$2
        ..leaveEffectiveAt = previous.$3
        ..leaveAcknowledgedAt = previous.$4;
      widget.store.notifyStateRestored();
      if (!mounted) return;
      final message = failure is ArgumentError
          ? failure.message.toString()
          : AppPersistence.saveFailureMessage(failure);
      setState(() => _error = message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    if (member.isRepresentative || member.status != LeaseMemberStatus.active) {
      return const SizedBox.shrink();
    }
    return TenantSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TenantSectionHeading('Hồ sơ thành viên'),
          const Text(
            'Để hoàn tất hồ sơ, tải ảnh rõ nét của hai mặt CCCD và ảnh chân dung. '
            'Chỉ bạn và chủ trọ của nhà này xem được.',
            style: TextStyle(color: tenantMuted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 10),
          _documentRow(
            'Mặt trước CCCD',
            'identity-front',
            member.identityFrontPath,
          ),
          _documentRow(
            'Mặt sau CCCD',
            'identity-back',
            member.identityBackPath,
          ),
          _documentRow('Ảnh chân dung', 'portrait', member.portraitPath),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const Divider(height: 24),
          if (member.leaveRequestedAt == null)
            OutlinedButton.icon(
              onPressed: _requestLeave,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Yêu cầu rời phòng'),
            )
          else
            Text(
              'Đã báo rời phòng ngày ${landlordDate(member.leaveRequestedAt!)}. '
              'Ngày rời dự kiến: ${landlordDate(member.leaveEffectiveAt!)}. '
              'Lý do: ${member.leaveReason ?? ''}',
              style: const TextStyle(
                color: tenantInk,
                fontSize: 12,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _documentRow(String title, String slot, String? path) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      path == null ? Icons.add_a_photo_outlined : Icons.verified_user_outlined,
      color: path == null ? tenantMuted : tenantGreen,
    ),
    title: Text(title, style: const TextStyle(fontSize: 13)),
    subtitle: Text(path == null ? 'Chưa tải lên' : 'Đã tải lên'),
    trailing: TextButton(
      onPressed: _busySlot == null ? () => _upload(slot) : null,
      child: _busySlot == slot
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(path == null ? 'Chọn ảnh' : 'Thay ảnh'),
    ),
  );
}

class _MemberLeaveDialog extends StatefulWidget {
  const _MemberLeaveDialog();

  @override
  State<_MemberLeaveDialog> createState() => _MemberLeaveDialogState();
}

class _MemberLeaveDialogState extends State<_MemberLeaveDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TenantDetailTheme(
    child: AlertDialog(
      scrollable: true,
      title: const Text('Yêu cầu rời phòng'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vui lòng báo trước ít nhất 30 ngày để chủ trọ sắp xếp. '
              'Bạn sẽ tiếp tục là thành viên trong thời gian báo trước.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _reason,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Lý do rời phòng'),
              validator: (value) => (value ?? '').trim().length < 5
                  ? 'Nhập lý do (ít nhất 5 ký tự).'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(context, _reason.text.trim());
          },
          child: const Text('Gửi yêu cầu'),
        ),
      ],
    ),
  );
}
