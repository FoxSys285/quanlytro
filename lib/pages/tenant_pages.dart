import 'package:flutter/material.dart';

import '../layouts/role_layout.dart';

const _green = Color(0xFF16836F);
const _greenDark = Color(0xFF106B5A);
const _ink = Color(0xFF1B2935);
const _muted = Color(0xFF74818C);
const _line = Color(0xFFE7ECEF);
const _canvas = Color(0xFFF5F7F8);

Widget buildTenantPage(BuildContext context, RoleDestination destination) {
  return switch (destination.id) {
    'discovery' => const TenantDiscoveryPage(),
    'my_lease' => const TenantHomePage(),
    'invoices' => const TenantInvoicesPage(),
    'payments' => const TenantPaymentHistoryPage(),
    _ => _TenantSecondaryPage(destination: destination),
  };
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          constraints.maxWidth < 600 ? 18 : 32,
          22,
          constraints.maxWidth < 600 ? 18 : 32,
          32,
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
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.45,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: _muted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x071B2935),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label, {required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () => _showPreviewNotice(context),
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _greenDark,
        side: const BorderSide(color: Color(0xFFD5E7E2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      ),
    );
  }
}

void _showPreviewNotice(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(
        content: Text(
          'Bản xem trước giao diện · Chức năng chưa kết nối hệ thống',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

String _money(int amount) {
  final digits = amount.toString();
  final result = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    result.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) result.write('.');
  }
  return '${result.toString()} đ';
}

class TenantDiscoveryPage extends StatefulWidget {
  const TenantDiscoveryPage({super.key});

  @override
  State<TenantDiscoveryPage> createState() => _TenantDiscoveryPageState();
}

class _TenantDiscoveryPageState extends State<TenantDiscoveryPage> {
  String _query = '';
  String _category = 'Tất cả';
  int _maxPrice = 10000000;

  static const _listings = [
    _RoomListing(
      name: 'Mây House · Studio đầy đủ nội thất',
      address: '25 Nguyễn Gia Trí, Bình Thạnh',
      price: 3800000,
      size: '25 m²',
      distance: '1,2 km',
      category: 'Studio',
      variant: 0,
      rating: '4.9',
      tags: ['Có máy lạnh', 'Ban công', 'Giờ tự do'],
    ),
    _RoomListing(
      name: 'Phòng gác lửng Nhà Nâu',
      address: '18 Phan Xích Long, Phú Nhuận',
      price: 3400000,
      size: '22 m²',
      distance: '2,4 km',
      category: 'Có gác',
      variant: 1,
      rating: '4.8',
      tags: ['Gác lửng', 'Cửa sổ lớn', 'Có chỗ xe'],
    ),
    _RoomListing(
      name: 'Studio Ban Mai',
      address: '45/2 D2, Bình Thạnh',
      price: 4200000,
      size: '28 m²',
      distance: '900 m',
      category: 'Studio',
      variant: 2,
      rating: '5.0',
      tags: ['Thang máy', 'Máy giặt riêng', 'Bếp riêng'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final rooms = _listings.where((room) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          '${room.name} ${room.address}'.toLowerCase().contains(
            normalizedQuery,
          );
      return matchesQuery &&
          room.price <= _maxPrice &&
          (_category == 'Tất cả' || room.category == _category);
    }).toList();

    return _PageFrame(
      children: [
        const Text(
          'Chào Minh Anh 👋',
          style: TextStyle(
            color: _greenDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Tìm một nơi gọi là nhà',
          style: TextStyle(
            color: _ink,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Khu vực, tên nhà trọ...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF98A3AC),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _green,
                    size: 21,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _green, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Material(
              color: _green,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => _showFilterSheet(context),
                child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: Icon(Icons.tune_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final category in ['Tất cả', 'Studio', 'Có gác'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                    selectedColor: _green,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: _category == category ? _green : _line,
                    ),
                    labelStyle: TextStyle(
                      color: _category == category ? Colors.white : _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SectionHeading(
          'Chỗ ở phù hợp với bạn',
          trailing: Text(
            '${rooms.length} phòng',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        if (rooms.isEmpty)
          const _EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Chưa tìm thấy phòng phù hợp',
            subtitle: 'Thử đổi từ khóa hoặc bộ lọc nhé.',
          )
        else
          for (final room in rooms) ...[
            _RoomCard(room: room, onTap: () => _showRoomDetails(context, room)),
            const SizedBox(height: 14),
          ],
        const SizedBox(height: 4),
        const Text(
          'Thông tin phòng trong bản xem trước',
          style: TextStyle(color: Color(0xFFA2ACB4), fontSize: 10),
        ),
      ],
    );
  }

  Future<void> _showFilterSheet(BuildContext context) async {
    final maxPrice = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DiscoveryFilterSheet(initialMaxPrice: _maxPrice),
    );
    if (!mounted || maxPrice == null) return;
    setState(() => _maxPrice = maxPrice);
  }

  void _showRoomDetails(BuildContext context, _RoomListing room) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RoomDetailsSheet(
        room: room,
        onBook: () => _showPreviewNotice(context),
      ),
    );
  }
}

class _RoomListing {
  const _RoomListing({
    required this.name,
    required this.address,
    required this.price,
    required this.size,
    required this.distance,
    required this.category,
    required this.variant,
    required this.rating,
    required this.tags,
  });

  final String name;
  final String address;
  final int price;
  final String size;
  final String distance;
  final String category;
  final int variant;
  final String rating;
  final List<String> tags;
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onTap});

  final _RoomListing room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoomArtwork(variant: room.variant, height: 157),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _StatusPill(
                          'Còn phòng',
                          color: _green,
                          icon: Icons.check_circle_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: _muted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            room.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ),
                        Text(
                          room.distance,
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: _line),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _money(room.price),
                                  style: const TextStyle(
                                    color: _greenDark,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' / tháng',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _tinyFeature(Icons.square_foot_rounded, room.size),
                        const SizedBox(width: 11),
                        _tinyFeature(
                          Icons.star_rounded,
                          room.rating,
                          color: const Color(0xFFE6A426),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _tinyFeature(IconData icon, String label, {Color color = _muted}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _RoomArtwork extends StatelessWidget {
  const _RoomArtwork({required this.variant, this.height = 170});

  final int variant;
  final double height;

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFFD8ECE5), Color(0xFFAED1C4)],
      [Color(0xFFF1E5D4), Color(0xFFD8BFA5)],
      [Color(0xFFDCE8F2), Color(0xFFADC4D5)],
    ];
    final palette = palettes[variant % palettes.length];
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette,
              ),
            ),
          ),
          Positioned(
            top: -35,
            right: -10,
            child: _softCircle(105, Colors.white.withValues(alpha: 0.32)),
          ),
          Positioned(
            bottom: -62,
            left: 30,
            child: _softCircle(150, Colors.white.withValues(alpha: 0.22)),
          ),
          Positioned(
            right: 20,
            bottom: 1,
            child: Icon(
              Icons.apartment_rounded,
              size: height * 0.86,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 13, color: _green),
                  SizedBox(width: 4),
                  Text(
                    'Đã xác thực',
                    style: TextStyle(
                      color: _greenDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 13,
            top: 13,
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Lưu tin',
                onPressed: () => _showPreviewNotice(context),
                icon: const Icon(
                  Icons.favorite_border_rounded,
                  color: _green,
                  size: 19,
                ),
                constraints: const BoxConstraints.tightFor(
                  width: 37,
                  height: 37,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _softCircle(double size, Color color) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
);

class _RoomDetailsSheet extends StatelessWidget {
  const _RoomDetailsSheet({required this.room, required this.onBook});

  final _RoomListing room;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const _SheetHandle(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _RoomArtwork(variant: room.variant, height: 175),
                ),
                const SizedBox(height: 16),
                Text(
                  room.name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  room.address,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 15),
                _Surface(
                  child: Column(
                    children: [
                      _DataRow(
                        label: 'Giá thuê',
                        value: '${_money(room.price)} / tháng',
                        emphasized: true,
                      ),
                      const _ThinDivider(),
                      _DataRow(label: 'Diện tích', value: room.size),
                      const _ThinDivider(),
                      _DataRow(label: 'Khoảng cách', value: room.distance),
                      const _ThinDivider(),
                      _DataRow(
                        label: 'Đánh giá',
                        value: '★ ${room.rating} / 5',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionHeading('Tiện nghi nổi bật'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final tag in room.tags) _FeatureTag(tag)],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Không gian sáng thoáng, khu vực an ninh và thuận tiện di chuyển. Liên hệ để xem phòng trực tiếp.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.55),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onBook();
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Đặt lịch xem phòng'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryFilterSheet extends StatefulWidget {
  const _DiscoveryFilterSheet({required this.initialMaxPrice});

  final int initialMaxPrice;

  @override
  State<_DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

class _DiscoveryFilterSheetState extends State<_DiscoveryFilterSheet> {
  late int _maxPrice = widget.initialMaxPrice;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const Text(
            'Bộ lọc tìm phòng',
            style: TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 19),
          const _SectionHeading('Ngân sách mỗi tháng'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final price in [3000000, 4000000, 5000000, 10000000])
                ChoiceChip(
                  label: Text(
                    price == 10000000
                        ? 'Không giới hạn'
                        : 'Đến ${_money(price)}',
                  ),
                  selected: _maxPrice == price,
                  onSelected: (_) => setState(() => _maxPrice = price),
                  selectedColor: _green.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: _maxPrice == price ? _greenDark : _muted,
                    fontSize: 11,
                  ),
                  side: BorderSide(color: _maxPrice == price ? _green : _line),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const _SectionHeading('Tiện nghi'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureTag('Có máy lạnh'),
              _FeatureTag('Có gác'),
              _FeatureTag('Cho nuôi thú cưng'),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_maxPrice),
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              minimumSize: const Size.fromHeight(47),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text('Xem kết quả'),
          ),
          SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
        ],
      ),
    );
  }
}

class TenantHomePage extends StatelessWidget {
  const TenantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      children: [
        const _PageTitle(
          title: 'Chỗ ở của tôi',
          subtitle: 'Thông tin phòng và hợp đồng đang có hiệu lực.',
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_greenDark, _green],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2516836F),
                blurRadius: 20,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'CHỖ Ở HIỆN TẠI',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.17),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Đang thuê',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mây House',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Phòng A.302 · Tầng 3',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '25 Nguyễn Gia Trí, P. 25, Bình Thạnh',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 13),
              const Row(
                children: [
                  Expanded(
                    child: _LeaseMetric(
                      label: 'Ngày bắt đầu',
                      value: '01/06/2026',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _LeaseMetric(
                      label: 'Hết hạn hợp đồng',
                      value: '31/05/2027',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SectionHeading('Tổng quan tháng này'),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 560;
            final cards = [
              _OverviewCard(
                icon: Icons.payments_outlined,
                title: 'Tiền thuê',
                value: _money(3800000),
                caption: 'Mỗi tháng',
                color: _green,
              ),
              _OverviewCard(
                icon: Icons.event_available_outlined,
                title: 'Ngày thanh toán',
                value: 'Ngày 10',
                caption: 'Hạn kỳ tiếp theo',
                color: const Color(0xFF4784C7),
              ),
              _OverviewCard(
                icon: Icons.people_outline_rounded,
                title: 'Thành viên',
                value: '2 người',
                caption: 'Trong phòng',
                color: const Color(0xFFB17939),
              ),
            ];
            if (wide)
              return Row(
                children: [
                  for (var i = 0; i < cards.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i == cards.length - 1 ? 0 : 11,
                        ),
                        child: cards[i],
                      ),
                    ),
                ],
              );
            return Column(
              children: [
                for (final card in cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 11),
        _SectionHeading(
          'Hợp đồng thuê',
          trailing: _StatusPill('Còn hiệu lực', color: _green),
        ),
        _Surface(
          child: Column(
            children: [
              const _DataRow(label: 'Mã hợp đồng', value: 'HD-2026-0148'),
              const _ThinDivider(),
              const _DataRow(label: 'Tiền đặt cọc', value: '7.600.000 đ'),
              const _ThinDivider(),
              const _DataRow(
                label: 'Chu kỳ thanh toán',
                value: 'Hàng tháng · ngày 10',
              ),
              const _ThinDivider(),
              _DataRow(
                label: 'Bản hợp đồng',
                value: 'Xem chi tiết',
                valueColor: _greenDark,
                onTap: () => _showPreviewNotice(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 21),
        _SectionHeading(
          'Người ở cùng',
          trailing: const Text(
            '2 / 4 người',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ),
        _Surface(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Column(
            children: [
              const _MemberRow(
                initials: 'MA',
                name: 'Nguyễn Minh Anh',
                detail: 'Bạn · Người đại diện',
                color: _green,
              ),
              const Divider(height: 1, color: _line),
              const _MemberRow(
                initials: 'TL',
                name: 'Trần Thảo Linh',
                detail: 'Thành viên',
                color: Color(0xFF7181C1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: _OutlineAction(
                icon: Icons.description_outlined,
                label: 'Hợp đồng',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OutlineAction(
                icon: Icons.build_outlined,
                label: 'Báo sự cố',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LeaseMetric extends StatelessWidget {
  const _LeaseMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) => _Surface(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: _muted, fontSize: 10)),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(caption, style: const TextStyle(color: _muted, fontSize: 9)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.initials,
    required this.name,
    required this.detail,
    required this.color,
  });
  final String initials;
  final String name;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(
            initials,
            style: TextStyle(
              color: color,
              fontSize: 11,
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
                name,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(detail, style: const TextStyle(color: _muted, fontSize: 10)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: _muted, size: 19),
      ],
    ),
  );
}

class TenantInvoicesPage extends StatefulWidget {
  const TenantInvoicesPage({super.key});

  @override
  State<TenantInvoicesPage> createState() => _TenantInvoicesPageState();
}

class _TenantInvoicesPageState extends State<TenantInvoicesPage> {
  bool _showPaid = false;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      children: [
        const _PageTitle(
          title: 'Hóa đơn',
          subtitle: 'Theo dõi khoản cần thanh toán và chi tiết từng kỳ.',
        ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E8),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFF2E4BF)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EAC7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFB17A23),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng cần thanh toán',
                      style: TextStyle(color: Color(0xFF866A3D), fontSize: 11),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '4.670.000 đ',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const _StatusPill('1 hóa đơn', color: Color(0xFFB17A23)),
            ],
          ),
        ),
        const SizedBox(height: 19),
        Row(
          children: [
            _InvoiceFilter(
              label: 'Cần thanh toán',
              count: '1',
              selected: !_showPaid,
              onTap: () => setState(() => _showPaid = false),
            ),
            const SizedBox(width: 9),
            _InvoiceFilter(
              label: 'Đã thanh toán',
              count: '3',
              selected: _showPaid,
              onTap: () => setState(() => _showPaid = true),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (!_showPaid)
          _InvoiceCard(
            month: 'Tháng 10, 2026',
            invoiceId: 'HD-2026-10-0148',
            amount: 4670000,
            dueDate: '10/10/2026',
            status: 'Chưa thanh toán',
            paid: false,
            onTap: () => _showInvoiceDetails(context, paid: false),
          )
        else
          for (final invoice in const [
            ('Tháng 9, 2026', 'HD-2026-09-0148', 4590000, '10/09/2026'),
            ('Tháng 8, 2026', 'HD-2026-08-0148', 4510000, '10/08/2026'),
            ('Tháng 7, 2026', 'HD-2026-07-0148', 4380000, '10/07/2026'),
          ]) ...[
            _InvoiceCard(
              month: invoice.$1,
              invoiceId: invoice.$2,
              amount: invoice.$3,
              dueDate: invoice.$4,
              status: 'Đã thanh toán',
              paid: true,
              onTap: () => _showInvoiceDetails(context, paid: true),
            ),
            const SizedBox(height: 11),
          ],
        const SizedBox(height: 17),
        if (!_showPaid)
          _OutlineAction(
            icon: Icons.info_outline_rounded,
            label: 'Hướng dẫn chuyển khoản',
            onPressed: () => _showPaymentInstructions(context),
          ),
      ],
    );
  }

  void _showInvoiceDetails(BuildContext context, {required bool paid}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _InvoiceDetailSheet(paid: paid),
    );
  }
}

class _InvoiceFilter extends StatelessWidget {
  const _InvoiceFilter({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _green : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? _green : _line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              count,
              style: TextStyle(
                color: selected ? Colors.white70 : _muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.month,
    required this.invoiceId,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.paid,
    required this.onTap,
  });
  final String month;
  final String invoiceId;
  final int amount;
  final String dueDate;
  final String status;
  final bool paid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = paid ? _green : const Color(0xFFD18A22);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: _line),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: statusColor,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          month,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          invoiceId,
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status, color: statusColor),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Divider(height: 1, color: _line),
              ),
              _DataRow(
                label: paid ? 'Đã thanh toán' : 'Hạn thanh toán',
                value: dueDate,
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tổng cộng',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                  Text(
                    _money(amount),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (!paid) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showPaymentInstructions(context),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('Thanh toán hóa đơn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _showPaymentInstructions(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _PaymentInstructionsSheet(),
  );
}

class _PaymentInstructionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _BottomSheetSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHandle(),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Thanh toán hóa đơn',
            style: TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tháng 10, 2026 · HD-2026-10-0148',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
        ),
        const SizedBox(height: 17),
        _Surface(
          child: Column(
            children: [
              Container(
                width: 122,
                height: 122,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 82,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                '4.670.000 đ',
                style: TextStyle(
                  color: _greenDark,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 15),
              const _DataRow(label: 'Ngân hàng', value: 'Vietcombank'),
              const _ThinDivider(),
              const _DataRow(label: 'Chủ tài khoản', value: 'NGUYEN VAN AN'),
              const _ThinDivider(),
              const _DataRow(label: 'Số tài khoản', value: '0123 456 789'),
              const _ThinDivider(),
              const _DataRow(label: 'Nội dung', value: 'HD2026100148 MA'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Thông tin minh họa cho bản xem trước. Chưa phát sinh giao dịch thật.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 10, height: 1.45),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showPreviewNotice(context),
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: const Text('Gửi minh chứng thanh toán'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _greenDark,
              minimumSize: const Size.fromHeight(45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _InvoiceDetailSheet extends StatelessWidget {
  const _InvoiceDetailSheet({required this.paid});
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final paid = this.paid;
    return _BottomSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chi tiết hóa đơn',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(
                paid ? 'Đã thanh toán' : 'Chưa thanh toán',
                color: paid ? _green : const Color(0xFFD18A22),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Kỳ tháng 10, 2026 · Phòng A.302',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 15),
          _Surface(
            child: Column(
              children: const [
                _DataRow(label: 'Tiền thuê phòng', value: '3.800.000 đ'),
                _ThinDivider(),
                _DataRow(label: 'Điện · 180 kWh × 2.600 đ', value: '468.000 đ'),
                _ThinDivider(),
                _DataRow(label: 'Nước · 8 m³ × 14.000 đ', value: '112.000 đ'),
                _ThinDivider(),
                _DataRow(label: 'Internet', value: '80.000 đ'),
                _ThinDivider(),
                _DataRow(label: 'Gửi xe', value: '150.000 đ'),
                _ThinDivider(),
                _DataRow(label: 'Phí vệ sinh', value: '60.000 đ'),
                _ThinDivider(),
                _DataRow(
                  label: 'Tổng cộng',
                  value: '4.670.000 đ',
                  emphasized: true,
                ),
              ],
            ),
          ),
          if (!paid) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _showPaymentInstructions(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Thanh toán'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TenantPaymentHistoryPage extends StatefulWidget {
  const TenantPaymentHistoryPage({super.key});

  @override
  State<TenantPaymentHistoryPage> createState() =>
      _TenantPaymentHistoryPageState();
}

class _TenantPaymentHistoryPageState extends State<TenantPaymentHistoryPage> {
  String _filter = 'Tất cả';

  static const _payments = [
    _PaymentRecord(
      month: 'Tháng 9, 2026',
      date: '10/09/2026 · 09:42',
      amount: 4590000,
      method: 'Chuyển khoản ngân hàng',
      reference: 'VCB2809102408',
      status: 'Thành công',
    ),
    _PaymentRecord(
      month: 'Tháng 8, 2026',
      date: '09/08/2026 · 18:16',
      amount: 4510000,
      method: 'Chuyển khoản ngân hàng',
      reference: 'VCB2808091672',
      status: 'Thành công',
    ),
    _PaymentRecord(
      month: 'Tháng 7, 2026',
      date: '11/07/2026 · 11:03',
      amount: 4380000,
      method: 'Tiền mặt',
      reference: 'TM-2026-0711',
      status: 'Thành công',
    ),
    _PaymentRecord(
      month: 'Tiền cọc · HD-2026-0148',
      date: '28/05/2026 · 14:25',
      amount: 7600000,
      method: 'Chuyển khoản ngân hàng',
      reference: 'VCB2805281425',
      status: 'Đang xác nhận',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final payments = _payments
        .where((payment) => _filter == 'Tất cả' || payment.status == _filter)
        .toList();
    return _PageFrame(
      children: [
        const _PageTitle(
          title: 'Lịch sử thanh toán',
          subtitle: 'Các khoản thanh toán và trạng thái xác nhận.',
        ),
        Row(
          children: [
            Expanded(
              child: _HistorySummary(
                icon: Icons.check_circle_outline_rounded,
                title: 'Đã xác nhận',
                value: '3 khoản',
                color: _green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HistorySummary(
                icon: Icons.hourglass_top_rounded,
                title: 'Đang xử lý',
                value: '1 khoản',
                color: const Color(0xFFCE8A25),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeading(
          'Giao dịch gần đây',
          trailing: const Icon(Icons.tune_rounded, color: _muted, size: 19),
        ),
        SizedBox(
          height: 37,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final filter in ['Tất cả', 'Thành công', 'Đang xác nhận'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                    selectedColor: _green,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: _filter == filter ? _green : _line),
                    labelStyle: TextStyle(
                      color: _filter == filter ? Colors.white : _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        for (final payment in payments) ...[
          _PaymentHistoryCard(
            payment: payment,
            onTap: () => _showPaymentDetails(context, payment),
          ),
          const SizedBox(height: 10),
        ],
        if (payments.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có giao dịch',
            subtitle: 'Giao dịch sẽ hiển thị tại đây.',
          ),
        const SizedBox(height: 5),
        const Text(
          'Lịch sử minh họa trong bản xem trước',
          style: TextStyle(color: Color(0xFFA2ACB4), fontSize: 10),
        ),
      ],
    );
  }

  void _showPaymentDetails(BuildContext context, _PaymentRecord payment) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentDetailsSheet(payment: payment),
    );
  }
}

class _PaymentRecord {
  const _PaymentRecord({
    required this.month,
    required this.date,
    required this.amount,
    required this.method,
    required this.reference,
    required this.status,
  });
  final String month;
  final String date;
  final int amount;
  final String method;
  final String reference;
  final String status;
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => _Surface(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.payment, required this.onTap});
  final _PaymentRecord payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final success = payment.status == 'Thành công';
    final color = success ? _green : const Color(0xFFCE8A25);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  success ? Icons.check_rounded : Icons.hourglass_top_rounded,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.month,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.date,
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                    const SizedBox(height: 7),
                    _StatusPill(payment.status, color: color),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _money(payment.amount),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Chi tiết  ›',
                    style: TextStyle(
                      color: _green,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentDetailsSheet extends StatelessWidget {
  const _PaymentDetailsSheet({required this.payment});
  final _PaymentRecord payment;

  @override
  Widget build(BuildContext context) => _BottomSheetSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHandle(),
        Text(
          payment.month,
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(payment.date, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 15),
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            payment.status == 'Thành công'
                ? Icons.check_rounded
                : Icons.hourglass_top_rounded,
            color: _green,
            size: 29,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          _money(payment.amount),
          style: const TextStyle(
            color: _ink,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        _StatusPill(
          payment.status,
          color: payment.status == 'Thành công'
              ? _green
              : const Color(0xFFCE8A25),
        ),
        const SizedBox(height: 16),
        _Surface(
          child: Column(
            children: [
              _DataRow(label: 'Phương thức', value: payment.method),
              const _ThinDivider(),
              _DataRow(label: 'Mã giao dịch', value: payment.reference),
              const _ThinDivider(),
              const _DataRow(label: 'Nhà trọ', value: 'Mây House'),
              const _ThinDivider(),
              const _DataRow(label: 'Phòng', value: 'A.302'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Giao dịch minh họa trong bản xem trước.',
          style: TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
    this.onTap,
  });
  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized ? _ink : _muted,
              fontSize: 11,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: InkWell(
            onTap: onTap,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    valueColor ?? (emphasized ? _ink : const Color(0xFF43515D)),
                fontSize: 11,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 7),
    child: Divider(height: 1, color: _line),
  );
}

class _FeatureTag extends StatelessWidget {
  const _FeatureTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F6F4),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _greenDark,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => _Surface(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 30, color: const Color(0xFF9AA6AE)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _BottomSheetSurface extends StatelessWidget {
  const _BottomSheetSurface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        4,
        18,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(child: child),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 37,
      height: 4,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFD5DDE1),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

class _TenantSecondaryPage extends StatelessWidget {
  const _TenantSecondaryPage({required this.destination});
  final RoleDestination destination;

  @override
  Widget build(BuildContext context) => _PageFrame(
    children: [
      _PageTitle(
        title: destination.label,
        subtitle: 'Không gian người thuê tại An Cư.',
      ),
      _Surface(
        padding: const EdgeInsets.fromLTRB(23, 28, 23, 28),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(destination.icon, color: _green, size: 27),
              ),
              const SizedBox(height: 14),
              Text(
                destination.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Màn hình này sẽ được thiết kế ở bước tiếp theo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
