import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
      await FirebaseStorage.instance
          .ref(path)
          .putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      widget.store.updateMemberIdentityDocuments(
        widget.member.tenantId,
        identityFrontPath: slot == 'identity-front' ? path : null,
        identityBackPath: slot == 'identity-back' ? path : null,
        portraitPath: slot == 'portrait' ? path : null,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busySlot = null);
    }
  }

  Future<void> _requestLeave() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => TenantDetailTheme(
        child: AlertDialog(
          title: const Text('Yêu cầu rời phòng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vui lòng báo trước ít nhất 30 ngày để chủ trọ sắp xếp. '
                'Bạn sẽ tiếp tục là thành viên trong thời gian báo trước.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                decoration: const InputDecoration(labelText: 'Lý do rời phòng'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Gửi yêu cầu'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    try {
      widget.store.requestMemberLeave(
        tenantId: widget.member.tenantId,
        reason: reason,
      );
    } on ArgumentError catch (error) {
      setState(() => _error = error.message.toString());
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
