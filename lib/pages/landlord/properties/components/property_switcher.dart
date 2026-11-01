import 'package:flutter/material.dart';

import '../../landlord_demo_store.dart';

class PropertySwitcher extends StatelessWidget {
  const PropertySwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolio = RentalPortfolio.instance;
    if (portfolio.stores.length <= 1) return const SizedBox.shrink();
    final store = portfolio.active;
    return Material(
      color: const Color(0xFFEDF3FF),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: DropdownButtonFormField<String>(
          key: ValueKey(store.property.id),
          initialValue: store.property.id,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.apartment_rounded, size: 22),
            labelText: 'Nhà trọ đang quản lý',
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
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
