import 'package:flutter/material.dart';

import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
import '../room_types/landlord_room_types_page.dart';
import '../rooms/landlord_rooms_page.dart';
import 'components/landlord_property_image.dart';
import 'components/property_contact_actions.dart';

/// Property details replace the portfolio content without opening a nested Scaffold.
class LandlordPropertyDetailPage extends StatefulWidget {
  const LandlordPropertyDetailPage({
    super.key,
    required this.store,
    required this.onBack,
    required this.onEdit,
  });
  final LandlordDemoStore store;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  State<LandlordPropertyDetailPage> createState() =>
      _LandlordPropertyDetailPageState();
}

class _LandlordPropertyDetailPageState
    extends State<LandlordPropertyDetailPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final property = widget.store.property;
      final palette = LandlordPalette.of(context);
      return PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) widget.onBack();
        },
        child: PropertyPortfolioBackdrop(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              key: PageStorageKey('property-detail-${property.id}'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Quay lại danh sách nhà trọ',
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.ink,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Chi tiết nhà trọ',
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'Chỉnh sửa thông tin nhà trọ',
                            onPressed: widget.onEdit,
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: propertyBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LandlordGlassCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LandlordPropertyImage(
                              url: property.imageUrl,
                              bytes: property.imageBytes,
                              height: MediaQuery.sizeOf(context).width >= 700
                                  ? 220
                                  : 150,
                              borderRadius: 21,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: propertyBlue,
                                    size: 21,
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          property.address.isEmpty
                                              ? 'Chưa cập nhật địa chỉ'
                                              : property.address,
                                          style: TextStyle(
                                            color: palette.ink,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${widget.store.catalog.length} phòng · ${widget.store.roomTypes.length} loại phòng',
                                          style: TextStyle(
                                            color: palette.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      LandlordGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vị trí và liên hệ',
                              style: TextStyle(
                                color: palette.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            PropertyContactActions(property: property),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      LandlordGlassCard(
                        padding: const EdgeInsets.all(5),
                        child: DefaultTabController(
                          length: 2,
                          initialIndex: _tab,
                          child: TabBar(
                            dividerColor: Colors.transparent,
                            onTap: (value) {
                              FocusScope.of(context).unfocus();
                              setState(() => _tab = value);
                            },
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF45BCFF), propertyBlue],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: palette.muted,
                            labelStyle: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            tabs: [
                              Tab(
                                text:
                                    'Phòng trọ (${widget.store.catalog.length})',
                              ),
                              Tab(
                                text:
                                    'Loại phòng (${widget.store.roomTypes.length})',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Offstage(
                        offstage: _tab != 0,
                        child: TickerMode(
                          enabled: _tab == 0,
                          child: LandlordRoomsPage(
                            key: ValueKey('${property.id}-rooms'),
                            store: widget.store,
                            embedded: true,
                          ),
                        ),
                      ),
                      Offstage(
                        offstage: _tab != 1,
                        child: TickerMode(
                          enabled: _tab == 1,
                          child: LandlordRoomTypesPage(
                            key: ValueKey('${property.id}-types'),
                            store: widget.store,
                            embedded: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
