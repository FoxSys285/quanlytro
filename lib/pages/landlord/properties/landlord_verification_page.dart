import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../../../data/app_persistence.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
import 'components/landlord_property_image.dart';
import 'components/verification_visuals.dart';
import 'models/landlord_property.dart';
import 'services/property_image_picker.dart';
import 'services/property_verification_picker.dart';

class LandlordVerificationPage extends StatefulWidget {
  const LandlordVerificationPage({super.key, this.store});

  final LandlordDemoStore? store;

  @override
  State<LandlordVerificationPage> createState() =>
      _LandlordVerificationPageState();
}

class _LandlordVerificationPageState extends State<LandlordVerificationPage> {
  LandlordDemoStore get _store =>
      widget.store ?? LandlordDemoStore.activeInstance;

  static const _sections = <({String id, String title, String description})>[
    (
      id: 'portrait',
      title: 'Ảnh chân dung chủ trọ',
      description: 'Ảnh rõ mặt, đủ sáng để đối chiếu với giấy tờ tùy thân.',
    ),
    (
      id: 'identity',
      title: 'CCCD / thẻ căn cước',
      description: 'Nên gửi cả mặt trước và mặt sau, thông tin không bị che.',
    ),
    (
      id: 'ownership',
      title: 'Sổ đỏ / sổ hồng',
      description: 'Chụp trang thể hiện chủ sở hữu và địa chỉ nhà cho thuê.',
    ),
    (
      id: 'authorization',
      title: 'Giấy ủy quyền cho thuê nhà',
      description: 'Cần gửi khi người đăng không phải chủ sở hữu.',
    ),
  ];

  late Map<String, List<PropertyVerificationFile>> _files;
  late bool _isOwner;
  bool _busy = false;
  String? _error;
  bool _dirty = false;
  bool _consent = false;

  @override
  void initState() {
    super.initState();
    final property = _store.property;
    _isOwner = property.verificationIsOwner;
    _files = {
      for (final section in _sections)
        section.id: List<PropertyVerificationFile>.of(
          property.verificationDocuments
                  .where((document) => document.id == section.id)
                  .firstOrNull
                  ?.files ??
              const <PropertyVerificationFile>[],
        ),
    };
  }

  Future<void> _pick(String id) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picked = id == 'portrait'
          ? await pickPropertyImage().then(
              (image) => image == null ? <SelectedPropertyImage>[] : [image],
            )
          : await pickPropertyVerificationImages();
      if (!mounted || picked.isEmpty) return;
      setState(() {
        final additions = picked.map(
          (image) => PropertyVerificationFile(
            name: image.name,
            bytes: Uint8List.fromList(image.bytes),
          ),
        );
        _files[id] = id == 'portrait'
            ? additions.toList()
            : [..._files[id]!, ...additions];
        _dirty = true;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException
              ? error.message
              : 'Không chọn được ảnh. Hãy thử ảnh JPG, PNG hoặc WebP.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove(String id, int index) {
    setState(() {
      _files[id]!.removeAt(index);
      _dirty = true;
    });
  }

  Future<void> _submit() async {
    if (!_consent) {
      setState(
        () => _error = 'Vui lòng xác nhận đồng ý gửi giấy tờ để xác minh.',
      );
      return;
    }
    final requiredIds = ['portrait', 'identity', 'ownership'];
    if (!_isOwner) requiredIds.add('authorization');
    final missing = requiredIds.where((id) => _files[id]!.isEmpty).toList();
    if (missing.isNotEmpty) {
      setState(
        () => _error =
            'Vui lòng bổ sung: ${_sections.where((section) => missing.contains(section.id)).map((section) => section.title).join(', ')}.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final current = _store.property;
      final documents = [
        for (final section in _sections)
          if (_files[section.id]!.isNotEmpty)
            PropertyVerificationDocument(
              id: section.id,
              files: List.unmodifiable(_files[section.id]!),
            ),
      ];
      _store.updateProperty(
        LandlordProperty(
          id: current.id,
          name: current.name,
          address: current.address,
          ownerName: current.ownerName,
          phone: current.phone,
          phoneIsSynthetic: current.phoneIsSynthetic,
          description: current.description,
          amenities: current.amenities,
          imageUrl: current.imageUrl,
          imageBytes: current.imageBytes,
          imageName: current.imageName,
          city: current.city,
          ward: current.ward,
          latitude: current.latitude,
          longitude: current.longitude,
          verificationDocuments: documents,
          verificationSubmittedAt: DateTime.now(),
          verificationIsOwner: _isOwner,
        ),
      );
      await AppPersistence.current?.flush();
      if (!mounted) return;
      final saveError = AppPersistence.current?.error.value;
      setState(() => _dirty = false);
      showLandlordMessage(
        context,
        saveError ?? 'Đã gửi hồ sơ. Nhà trọ đang chờ quản trị viên kiểm tra.',
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'Chưa gửi được hồ sơ: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_store, AdminStore.instance]),
    builder: (context, _) {
      final palette = LandlordPalette.of(context);
      final property = _store.property;
      final verified = AdminStore.instance.isVerified(property.id);
      final note = AdminStore.instance.reviewNote(property.id);
      final submitted = property.verificationSubmittedAt != null;
      final sections = _sections
          .where((s) => s.id != 'authorization' || !_isOwner)
          .toList();
      final completed = sections.where((s) => _files[s.id]!.isNotEmpty).length;
      final status = verified
          ? 'Nhà trọ đã xác minh'
          : note.isNotEmpty
          ? 'Cần bổ sung hồ sơ'
          : submitted
          ? 'Hồ sơ đang chờ kiểm tra'
          : 'Nhà trọ chưa xác minh';
      return VerificationPageFrame(
        title: 'Hồ sơ xác minh',
        subtitle: 'Hoàn thiện giấy tờ để xác thực thông tin chủ trọ và quyền cho thuê.',
        children: [
          LandlordBluePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .17),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        verified
                            ? Icons.verified_rounded
                            : Icons.folder_shared_outlined,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.name,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.5,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            status,
                            style: const TextStyle(
                              color: Color(0xFFE0F3FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _VerificationStep(
                      number: 1,
                      label: 'Chuẩn bị hồ sơ',
                      complete: submitted || verified,
                      active: !submitted && !verified,
                    ),
                    _VerificationStep(
                      number: 2,
                      label: 'Gửi xét duyệt',
                      complete: verified,
                      active: submitted && !verified,
                    ),
                    _VerificationStep(
                      number: 3,
                      label: 'Đã xác minh',
                      complete: verified,
                      active: verified,
                      last: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (submitted || verified || note.isNotEmpty) ...[
            _AdminResponse(
              verified: verified,
              note: note,
              submittedAt: property.verificationSubmittedAt,
            ),
            const SizedBox(height: 20),
          ],
          const LandlordGlassSection(
            title: 'Thông tin nhà trọ',
            subtitle: 'Thông tin được đối chiếu khi xét duyệt hồ sơ.',
          ),
          LandlordGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 68,
                      child: LandlordPropertyImage(
                        url: property.imageUrl,
                        bytes: property.imageBytes,
                        height: 74,
                        borderRadius: 14,
                        showIllustrationLabel: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tên nhà trọ: ${property.name}',
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            property.address,
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Divider(height: 1, color: palette.line),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 24,
                  runSpacing: 14,
                  children: [
                    _PropertyInfo(
                      icon: Icons.person_outline_rounded,
                      label: 'Chủ trọ',
                      value: property.ownerName,
                    ),
                    _PropertyInfo(
                      icon: Icons.phone_outlined,
                      label: 'Số điện thoại',
                      value: property.phone,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!verified) ...[
            LandlordGlassSection(
              title: 'Giấy tờ xác minh',
              subtitle: 'Ảnh rõ nét, đầy đủ thông tin và còn hiệu lực.',
              trailing: VerificationBadge(
                label: '$completed/${sections.length} mục',
                color: completed == sections.length
                    ? verificationGreen
                    : palette.primary,
              ),
            ),
            LandlordGlassCard(
              padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isOwner,
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _isOwner = value;
                        _dirty = true;
                      }),
                title: Text(
                  'Tôi là chủ sở hữu nhà trọ',
                  style: TextStyle(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _isOwner
                        ? 'Tắt nếu bạn cho thuê thay chủ sở hữu.'
                        : 'Cần bổ sung giấy ủy quyền cho thuê.',
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
                activeTrackColor: palette.primary,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 680 ? 2 : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 14) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (var index = 0; index < sections.length; index++)
                      SizedBox(
                        width: width,
                        child: _DocumentSection(
                          id: sections[index].id,
                          number: index + 1,
                          title: sections[index].title,
                          description: sections[index].description,
                          files: _files[sections[index].id]!,
                          busy: _busy,
                          onPick: () => _pick(sections[index].id),
                          onRemove: (fileIndex) =>
                              _remove(sections[index].id, fileIndex),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            LandlordGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VerificationIcon(
                        icon: Icons.lock_outline_rounded,
                        color: palette.primary,
                        size: 38,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Giấy tờ của bạn được bảo mật',
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Chỉ chủ trọ và Admin được xem. Giấy tờ không hiển thị với người thuê.',
                              style: TextStyle(
                                color: palette.muted,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: palette.line),
                  CheckboxListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _consent,
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _consent = value == true),
                    title: Text(
                      'Tôi đồng ý gửi giấy tờ để xác minh nhà trọ',
                      style: TextStyle(
                        color: palette.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    activeColor: palette.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: propertyBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _busy || (!_dirty && submitted) ? null : _submit,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 20),
                    label: Text(
                      submitted ? 'Nộp lại hồ sơ' : 'Gửi hồ sơ xác minh',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kết quả xét duyệt sẽ hiển thị tại mục Phản hồi từ Admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({
    required this.number,
    required this.label,
    required this.complete,
    required this.active,
    this.last = false,
  });
  final int number;
  final String label;
  final bool complete;
  final bool active;
  final bool last;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 27,
              height: 27,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: complete
                    ? const Color(0xFFA5F0DB)
                    : active
                    ? Colors.white
                    : Colors.white.withValues(alpha: .15),
                border: Border.all(
                  color: Colors.white.withValues(alpha: active ? 1 : .3),
                ),
              ),
              child: complete
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Color(0xFF127258),
                    )
                  : Text(
                      '$number',
                      style: TextStyle(
                        color: active ? propertyBlue : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            if (!last)
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.white.withValues(alpha: .3),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: active || complete ? Colors.white : Colors.white70,
            fontSize: 10,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _AdminResponse extends StatelessWidget {
  const _AdminResponse({
    required this.verified,
    required this.note,
    this.submittedAt,
  });
  final bool verified;
  final String note;
  final DateTime? submittedAt;
  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final color = verified
        ? verificationGreen
        : note.isNotEmpty
        ? verificationAmber
        : palette.primary;
    return LandlordGlassCard(
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VerificationIcon(
                icon: verified
                    ? Icons.task_alt_rounded
                    : note.isNotEmpty
                    ? Icons.mark_chat_unread_outlined
                    : Icons.schedule_rounded,
                color: color,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phản hồi từ Admin',
                      style: TextStyle(
                        color: palette.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      verified
                          ? 'Hồ sơ đã được duyệt'
                          : note.isNotEmpty
                          ? 'Vui lòng bổ sung theo hướng dẫn'
                          : 'Hồ sơ đã được tiếp nhận',
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SelectableText(
            verified
                ? 'Admin đã duyệt hồ sơ. Nhà trọ đã được xác minh.'
                : note.isNotEmpty
                ? note
                : 'Đã tiếp nhận hồ sơ. Đang chờ Admin xét duyệt và phản hồi.',
            style: TextStyle(color: palette.ink, fontSize: 13, height: 1.55),
          ),
          if (submittedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Lần nộp gần nhất: ${submittedAt!.day}/${submittedAt!.month}/${submittedAt!.year}',
              style: TextStyle(color: palette.muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _PropertyInfo extends StatelessWidget {
  const _PropertyInfo({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: palette.muted, size: 19),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: palette.muted, fontSize: 10)),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.files,
    required this.busy,
    required this.onPick,
    required this.onRemove,
  });
  final String id;
  final int number;
  final String title;
  final String description;
  final List<PropertyVerificationFile> files;
  final bool busy;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final complete = files.isNotEmpty;
    final color = complete ? verificationGreen : palette.primary;
    return LandlordGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VerificationIcon(icon: _icon, color: color, size: 42),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GIẤY TỜ 0$number',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                complete ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: complete ? verificationGreen : palette.line,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(color: palette.muted, fontSize: 12, height: 1.5),
          ),
          if (complete) ...[
            const SizedBox(height: 12),
            for (var index = 0; index < files.length; index++)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.only(left: 10, right: 2),
                decoration: BoxDecoration(
                  color: verificationGreen.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      color: verificationGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        files[index].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.ink, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Xóa ảnh',
                      onPressed: busy ? null : () => onRemove(index),
                      icon: Icon(
                        Icons.close_rounded,
                        color: palette.muted,
                        size: 17,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          Material(
            color: palette.primary.withValues(alpha: .045),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: busy ? null : onPick,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: .2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: palette.primary,
                      size: 25,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      complete ? 'Thêm ảnh' : 'Chọn ảnh giấy tờ',
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complete
                          ? '${files.length} ảnh đã chọn'
                          : 'Bắt buộc · JPG, PNG hoặc WebP',
                      style: TextStyle(color: palette.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon => switch (id) {
    'portrait' => Icons.account_circle_outlined,
    'identity' => Icons.badge_outlined,
    'ownership' => Icons.home_work_outlined,
    _ => Icons.assignment_turned_in_outlined,
  };
}
