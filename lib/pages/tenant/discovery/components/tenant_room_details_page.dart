import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../landlord/landlord_demo_store.dart';
import '../../../shared/media/room_photo_gallery.dart';
import '../../../shared/media/room_photo.dart';
import '../../conversations/tenant_danhsachtinnhan_page.dart';
import '../../tenant_ui.dart';
import '../models/tenant_room_listing.dart';

class TenantRoomDetailsPage extends StatefulWidget {
  const TenantRoomDetailsPage({
    super.key,
    required this.room,
    required this.onBook,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final TenantRoomListing room;
  final VoidCallback onBook;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  State<TenantRoomDetailsPage> createState() => _TenantRoomDetailsPageState();
}

class _TenantRoomDetailsPageState extends State<TenantRoomDetailsPage> {
  late bool _isFavorite = widget.isFavorite;
  final _galleryController = PageController();
  int _photoIndex = 0;
  bool _expandedDescription = false;
  bool _highlightsCollapsed = false;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final photos = room.gallery;
    final ownerStore = RentalPortfolio.instance.byId(room.propertyId);
    final owner = ownerStore?.property;
    final ownerName = owner?.ownerName ?? 'Chủ nhà';
    final ownerPhone = owner?.phone ?? '';
    final address = [
      room.address,
      room.ward,
      room.city,
    ].where((part) => part.trim().isNotEmpty).join(', ');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _photoHeader(context, photos),
                    _thumbnails(photos),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  room.name,
                                  style: const TextStyle(
                                    color: tenantInk,
                                    fontSize: 21,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.35,
                                  ),
                                ),
                              ),
                              if (room.price <= 3500000)
                                Container(
                                  margin: const EdgeInsets.only(
                                    left: 8,
                                    top: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEBF6DE),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    '🔥 Hot',
                                    style: TextStyle(
                                      color: Color(0xFF08783B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '${formatTenantMoney(room.price)}/tháng',
                            style: const TextStyle(
                              color: Color(0xFF08783B),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.45,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: tenantGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                    color: tenantInk,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 17),
                          _roomFacts(room),
                          const SizedBox(height: 22),
                          _highlights(room),
                          const SizedBox(height: 19),
                          const Divider(height: 1, color: tenantLine),
                          const SizedBox(height: 18),
                          _description(room),
                          const SizedBox(height: 18),
                          _ownerCard(
                            context,
                            ownerName: ownerName,
                            ownerPhone: ownerPhone,
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _photoHeader(BuildContext context, List<RoomPhoto> photos) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 292,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photos.isEmpty)
            const RoomPhotoPlaceholder()
          else
            PageView.builder(
              controller: _galleryController,
              itemCount: photos.length,
              onPageChanged: (index) => setState(() => _photoIndex = index),
              itemBuilder: (context, index) => RoomPhotoImage(
                photo: photos[index],
                label: 'Ảnh phòng ${widget.room.name}',
              ),
            ),
          Positioned(
            top: topInset + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _roundAction(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Quay lại',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                _roundAction(
                  icon: _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  tooltip: _isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                  color: _isFavorite ? const Color(0xFFD64559) : tenantInk,
                  onTap: () {
                    widget.onFavoriteToggle();
                    setState(() => _isFavorite = !_isFavorite);
                  },
                ),
                const SizedBox(width: 9),
                _roundAction(
                  icon: Icons.share_outlined,
                  tooltip: 'Chia sẻ',
                  onTap: _share,
                ),
              ],
            ),
          ),
          if (photos.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 13,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xB8000000),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_photoIndex + 1}/${photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roundAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = tenantInk,
  }) => Material(
    color: Colors.white.withValues(alpha: 0.95),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Tooltip(
          message: tooltip,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    ),
  );

  Widget _thumbnails(List<RoomPhoto> photos) {
    if (photos.length < 2) return const SizedBox(height: 14);
    return SizedBox(
      height: 70,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            _galleryController.animateToPage(
              index,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: index == _photoIndex
                    ? tenantGreen
                    : const Color(0xFFE4E7E8),
                width: index == _photoIndex ? 1.8 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: RoomPhotoImage(
              photo: photos[index],
              label: 'Ảnh thu nhỏ ${index + 1}',
            ),
          ),
        ),
      ),
    );
  }

  Widget _roomFacts(TenantRoomListing room) {
    final facts = [
      (Icons.home_work_rounded, room.size),
      (Icons.bed_rounded, room.roomType),
      (
        Icons.groups_rounded,
        room.capacity == null ? 'Chưa rõ' : '${room.capacity} người',
      ),
      (
        Icons.location_on_outlined,
        room.distance.isNotEmpty ? room.distance : room.ward,
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF7F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          for (var index = 0; index < facts.length; index++) ...[
            if (index > 0)
              Container(width: 1, height: 44, color: const Color(0xFFB9D9C4)),
            Expanded(
              child: Column(
                children: [
                  Icon(facts[index].$1, color: tenantGreenDark, size: 23),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      facts[index].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: tenantInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _highlights(TenantRoomListing room) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.star_rounded, color: tenantGreen, size: 24),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Điểm nổi bật',
              style: TextStyle(
                color: tenantInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Thu gọn điểm nổi bật',
            onPressed: () =>
                setState(() => _highlightsCollapsed = !_highlightsCollapsed),
            icon: Icon(
              _highlightsCollapsed
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: tenantInk,
            ),
          ),
        ],
      ),
      if (!_highlightsCollapsed)
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final tag in room.tags)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F5EC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF139653),
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tag,
                      style: const TextStyle(
                        color: Color(0xFF164A30),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
    ],
  );

  Widget _description(TenantRoomListing room) {
    final description = room.description.isEmpty
        ? 'Liên hệ chủ trọ để xem phòng trực tiếp và hỏi thêm về tiện ích.'
        : room.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.description_rounded, color: tenantGreenDark, size: 22),
            SizedBox(width: 8),
            Text(
              'Mô tả chi tiết',
              style: TextStyle(
                color: tenantInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          description,
          maxLines: _expandedDescription ? null : 3,
          overflow: _expandedDescription ? null : TextOverflow.ellipsis,
          style: const TextStyle(color: tenantInk, fontSize: 14, height: 1.55),
        ),
        if (description.length > 120)
          Center(
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _expandedDescription = !_expandedDescription),
              icon: Icon(
                _expandedDescription
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 20,
              ),
              label: Text(_expandedDescription ? 'Thu gọn' : 'Xem thêm'),
              style: TextButton.styleFrom(foregroundColor: tenantGreen),
            ),
          ),
      ],
    );
  }

  Widget _ownerCard(
    BuildContext context, {
    required String ownerName,
    required String ownerPhone,
  }) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10101824),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFE8F3ED),
          child: Text(
            ownerName.isEmpty ? 'C' : ownerName[0],
            style: const TextStyle(
              color: tenantGreenDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ownerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: tenantInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Chủ nhà',
                style: TextStyle(color: tenantMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: ownerPhone.isEmpty
              ? null
              : () => _callOwner(context, ownerPhone),
          icon: const Icon(Icons.call_rounded, size: 17),
          label: const Text('Gọi ngay'),
          style: OutlinedButton.styleFrom(
            foregroundColor: tenantGreenDark,
            side: const BorderSide(color: tenantGreen),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _bottomActions(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: tenantLine)),
    ),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const TenantDanhSachTinNhanPage(),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Nhắn tin'),
              style: OutlinedButton.styleFrom(
                foregroundColor: tenantGreenDark,
                backgroundColor: const Color(0xFFF1F8F3),
                side: BorderSide.none,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onBook();
              },
              icon: const Icon(Icons.calendar_month_rounded, size: 19),
              label: const Text('Đặt lịch xem phòng'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF079B4D),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _callOwner(BuildContext context, String phone) async {
    final number = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final opened = await launchUrl(Uri(scheme: 'tel', path: number));
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không mở được ứng dụng gọi điện.')),
    );
  }

  Future<void> _share() async {
    await Clipboard.setData(
      ClipboardData(text: '${widget.room.name}\n${widget.room.address}'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép thông tin phòng.')),
    );
  }
}
