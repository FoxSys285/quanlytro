import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../../../data/app_persistence.dart';
import '../landlord_demo_store.dart';
import '../landlord_theme.dart';
import '../landlord_ui.dart';
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
      final verified = AdminStore.instance.isVerified(_store.property.id);
      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Xác minh nhà trọ',
            subtitle: _store.property.name,
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: verified ? const Color(0xFFE8F6EF) : palette.primarySoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: verified ? const Color(0xFFB9E4CB) : palette.line,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  verified ? Icons.verified_rounded : Icons.shield_outlined,
                  color: verified ? const Color(0xFF168456) : palette.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verified
                            ? 'Nhà trọ đã xác minh'
                            : _store.property.verificationSubmittedAt == null
                            ? 'Nhà trọ chưa xác minh'
                            : AdminStore.instance
                                  .reviewNote(_store.property.id)
                                  .isNotEmpty
                            ? 'Cần bổ sung hồ sơ'
                            : 'Hồ sơ đang chờ kiểm tra',
                        style: TextStyle(
                          color: verified
                              ? const Color(0xFF168456)
                              : palette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        verified ? 'Thông tin xác minh đã được duyệt.' : 'Gửi giấy tờ để quản trị viên đối chiếu thông tin chủ trọ và quyền cho thuê.',
                        style: TextStyle(color: palette.muted, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (AdminStore.instance.reviewNote(_store.property.id).isNotEmpty)
            LandlordCard(
              backgroundColor: const Color(0xFFFFF8E8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFB77716),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Quản trị viên yêu cầu bổ sung: ${AdminStore.instance.reviewNote(_store.property.id)}',
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          if (!verified) ...[
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              value: _isOwner,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                      _isOwner = value;
                      _dirty = true;
                    }),
              title: const Text('Tôi là chủ sở hữu nhà trọ'),
              subtitle: Text(
                _isOwner
                    ? 'Nếu bạn là người đăng thay chủ nhà, hãy tắt mục này và gửi giấy ủy quyền.'
                    : 'Cần có giấy ủy quyền hoặc văn bản cho phép cho thuê.',
                style: TextStyle(color: palette.muted, height: 1.4),
              ),
              activeTrackColor: palette.primary,
            ),
            const SizedBox(height: 6),
            for (final section in _sections)
              if (section.id != 'authorization' || !_isOwner)
                _DocumentSection(
                  id: section.id,
                  title: section.title,
                  description: section.description,
                  files: _files[section.id]!,
                  isRequired: section.id != 'authorization' || !_isOwner,
                  busy: _busy,
                  onPick: () => _pick(section.id),
                  onRemove: (index) => _remove(section.id, index),
                ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ),
            LandlordCard(
              backgroundColor: const Color(0xFFF4F7FC),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, color: palette.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: const Text(
                      'Ảnh giấy tờ được lưu trong khu vực riêng và chỉ tài khoản chủ trọ cùng quản trị viên có quyền xem.',
                      style: TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            CheckboxListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              value: _consent,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _consent = value == true),
              title: const Text(
                'Tôi đồng ý gửi giấy tờ để xác minh nhà trọ',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              subtitle: Text(
                'Ảnh chỉ phục vụ việc xét duyệt; người thuê không xem được giấy tờ này.',
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              activeColor: palette.primary,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _busy ||
                        (!_dirty &&
                            _store.property.verificationSubmittedAt != null)
                    ? null
                    : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _store.property.verificationSubmittedAt == null
                      ? 'Gửi hồ sơ xác minh'
                      : 'Cập nhật hồ sơ',
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({
    required this.id,
    required this.title,
    required this.description,
    required this.files,
    required this.isRequired,
    required this.busy,
    required this.onPick,
    required this.onRemove,
  });

  final String id;
  final String title;
  final String description;
  final List<PropertyVerificationFile> files;
  final bool isRequired;
  final bool busy;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return LandlordCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_icon, color: palette.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: palette.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          isRequired ? 'BẮT BUỘC' : 'NẾU CÓ',
                          style: TextStyle(
                            color: isRequired ? palette.primary : palette.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var index = 0; index < files.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 17,
                      color: palette.primary,
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
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Xóa ảnh',
                      onPressed: busy ? null : () => onRemove(index),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onPick,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 19),
            label: Text(files.isEmpty ? 'Chọn ảnh' : 'Thêm ảnh'),
          ),
        ],
      ),
    );
  }

  IconData get _icon => switch (id) {
    'portrait' => Icons.account_circle_outlined,
    'identity' => Icons.badge_outlined,
    'ownership' => Icons.real_estate_agent_outlined,
    _ => Icons.assignment_turned_in_outlined,
  };
}
