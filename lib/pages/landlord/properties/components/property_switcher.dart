import 'package:flutter/material.dart';

import '../../landlord_demo_store.dart';
import '../../landlord_theme.dart';

class PropertySwitcher extends StatelessWidget {
  const PropertySwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    final portfolio = RentalPortfolio.instance;
    if (portfolio.stores.length <= 1) return const SizedBox.shrink();
    final store = portfolio.active;
    return ColoredBox(
      color: palette.canvas,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: DropdownButtonFormField<String>(
          key: ValueKey(store.property.id),
          initialValue: store.property.id,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.apartment_rounded,
              size: 22,
              color: palette.primary,
            ),
            labelText: 'Nhà trọ đang quản lý',
            isDense: true,
            filled: true,
            fillColor: palette.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.line),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
          items: [
            for (final item in portfolio.stores)
              DropdownMenuItem(
                value: item.property.id,
                child: Text(
                  '${item.property.name} · ${item.catalog.length} phòng',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) {
            if (id != null) portfolio.select(id);
          },
        ),
      ),
    );
  }
}
