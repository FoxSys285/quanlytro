import 'package:flutter/material.dart';

import 'landlord_demo_store.dart';
import 'landlord_theme.dart';

class LandlordCompactHeader extends StatelessWidget {
  const LandlordCompactHeader({
    super.key,
    required this.store,
    required this.dark,
    required this.onToggleTheme,
    required this.onNotifications,
  });

  final LandlordDemoStore store;
  final bool dark;
  final VoidCallback? onToggleTheme;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final portfolio = RentalPortfolio.instance;
    final name = store.property.ownerName.trim();
    final words = name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? 'CT'
        : words.length == 1
        ? words.first[0].toUpperCase()
        : '${words.first[0]}${words.last[0]}'.toUpperCase();
    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<String>(
            tooltip: 'Chọn nhà trọ đang quản lý',
            onSelected: portfolio.select,
            itemBuilder: (_) => [
              for (final item in portfolio.stores)
                PopupMenuItem(
                  value: item.property.id,
                  child: Text(
                    '${item.property.name} · ${item.catalog.length} phòng',
                  ),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border.all(color: palette.line),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: palette.primarySoft,
                    child: Icon(
                      Icons.apartment_rounded,
                      color: palette.primary,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.property.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${store.catalog.length} phòng · Hoạt động',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: palette.muted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: palette.muted,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 3),
        IconButton(
          tooltip: dark
              ? 'Chuyển sang giao diện sáng'
              : 'Chuyển sang giao diện tối',
          onPressed: onToggleTheme,
          icon: Icon(
            dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: palette.ink,
            size: 20,
          ),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: onNotifications,
          icon: Icon(
            Icons.notifications_none_rounded,
            color: palette.ink,
            size: 21,
          ),
        ),
        InkWell(
          onTap: () => Scaffold.of(context).openDrawer(),
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: palette.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
