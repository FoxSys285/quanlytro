import 'package:flutter/material.dart';

import '../tenant_detail_ui.dart';
import '../tenant_ui.dart';
import '../../landlord/properties/components/landlord_property_image.dart';
import '../discovery/models/tenant_property_listing.dart';

class TenantConversationPropertyDetailPage extends StatelessWidget {
  const TenantConversationPropertyDetailPage({
    super.key,
    required this.listing,
  });

  final TenantPropertyListing listing;

  @override
  Widget build(BuildContext context) {
    final property = listing.property;
    return TenantDetailTheme(
      child: Scaffold(
        appBar: AppBar(title: Text(property.name)),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TenantSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LandlordPropertyImage(
                            url: property.imageUrl,
                            bytes: property.imageBytes,
                            height: 220,
                            borderRadius: 20,
                            semanticLabel: 'Ảnh ${property.name}',
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.name,
                                  style: const TextStyle(
                                    color: tenantInk,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _PropertyFact(
                                  icon: Icons.location_on_outlined,
                                  text: property.address.isEmpty
                                      ? 'Chưa cập nhật địa chỉ'
                                      : property.address,
                                ),
                                const SizedBox(height: 10),
                                _PropertyFact(
                                  icon: Icons.person_outline_rounded,
                                  text: property.ownerName.isEmpty
                                      ? 'Chủ trọ chưa cập nhật tên'
                                      : property.ownerName,
                                ),
                                if (property.phone.trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _PropertyFact(
                                    icon: Icons.call_outlined,
                                    text: property.phone,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (property.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const TenantSectionHeading('Giới thiệu'),
                      TenantSurface(
                        child: Text(
                          property.description,
                          style: const TextStyle(
                            color: tenantMuted,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                    if (property.amenities.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const TenantSectionHeading('Tiện nghi'),
                      TenantSurface(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final amenity in property.amenities)
                              Chip(
                                avatar: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 17,
                                  color: tenantGreenDark,
                                ),
                                label: Text(amenity),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (listing.roomCount > 0 ||
                        listing.minRent != null ||
                        listing.roomTypes.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const TenantSectionHeading('Quy mô nhà trọ'),
                      TenantSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (listing.roomCount > 0)
                              _PropertyFact(
                                icon: Icons.meeting_room_outlined,
                                text: '${listing.roomCount} phòng',
                              ),
                            if (listing.roomTypes.isNotEmpty) ...[
                              if (listing.roomCount > 0)
                                const SizedBox(height: 14),
                              _PropertyFact(
                                icon: Icons.category_outlined,
                                text: '${listing.roomTypes.length} loại phòng',
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final type in listing.roomTypes)
                                    Chip(label: Text(type)),
                                ],
                              ),
                            ],
                            if (listing.minRent != null) ...[
                              if (listing.roomCount > 0 ||
                                  listing.roomTypes.isNotEmpty)
                                const SizedBox(height: 14),
                              _PropertyFact(
                                icon: Icons.payments_outlined,
                                text:
                                    'Giá thuê từ ${formatTenantMoney(listing.minRent!)}/tháng',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PropertyFact extends StatelessWidget {
  const _PropertyFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: tenantGreenDark, size: 19),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: tenantInk, fontSize: 13, height: 1.45),
        ),
      ),
    ],
  );
}
