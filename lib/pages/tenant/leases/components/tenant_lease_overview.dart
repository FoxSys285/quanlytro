import 'package:flutter/material.dart';

import '../../../landlord/finance/landlord_finance_models.dart';
import '../../../landlord/landlord_demo_store.dart';
import '../../../shared/media/room_photo.dart';
import '../../../shared/media/room_photo_gallery.dart';
import '../../tenant_detail_ui.dart';
import '../../tenant_ui.dart';

class TenantLeaseNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  const TenantLeaseNavigationBar({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: const Color(0xFFF0FAF3),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    title: const Text(
      'Hợp đồng thuê',
      style: TextStyle(
        color: tenantInk,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    leading: Padding(
      padding: const EdgeInsets.all(8),
      child: IconButton.filledTonal(
        onPressed: onBack,
        tooltip: 'Quay lại',
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: tenantInk,
        ),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      ),
    ),
  );
}

class TenantLeaseHero extends StatelessWidget {
  const TenantLeaseHero({super.key, required this.hasLease});
  final bool hasLease;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 360;
      return SizedBox(
        height: compact ? 244 : 230,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/tenant_contract_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              excludeFromSemantics: true,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF0FAF3),
                    Color(0xD9F0FAF3),
                    Color(0x00F0FAF3),
                  ],
                  stops: [0, 0.43, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 25, 18, 28),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: constraints.maxWidth < 600
                      ? constraints.maxWidth * 0.60
                      : 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TenantStatusPill(
                        hasLease ? 'Đang hiệu lực' : 'Hợp đồng của bạn',
                        color: tenantGreenDark,
                        icon: hasLease
                            ? Icons.check_circle_rounded
                            : Icons.description_outlined,
                      ),
                      const SizedBox(height: 13),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Hợp đồng thuê\nphòng trọ',
                          style: TextStyle(
                            fontSize: compact ? 25 : 29,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: const Color(0xFF073B25),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Thông tin chi tiết hợp đồng thuê của bạn',
                        style: TextStyle(
                          color: Color(0xFF465369),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class TenantLeaseOverview extends StatelessWidget {
  const TenantLeaseOverview({
    super.key,
    required this.data,
    required this.lease,
  });
  final LandlordDemoStore data;
  final LandlordLease lease;

  @override
  Widget build(BuildContext context) {
    final room = data.roomByCode(lease.room);
    final types = data.roomTypes.where((type) => type.id == room?.roomTypeId);
    final photos = types.isEmpty ? const <RoomPhoto>[] : types.first.photos;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
      lease.endDate.year,
      lease.endDate.month,
      lease.endDate.day,
    );
    final days = end.difference(today).inDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TenantSurface(
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: tenantGreenDark,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thời gian thuê',
                          style: TextStyle(color: tenantMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${landlordDate(lease.startDate)} – ${landlordDate(lease.endDate)}',
                          style: const TextStyle(
                            color: tenantInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TenantStatusPill(
                days == 0 ? 'Hết hạn hôm nay' : 'Còn $days ngày',
                color: tenantGreenDark,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TenantSurface(
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    SizedBox(
                      width: (constraints.maxWidth * 0.39).clamp(88.0, 200.0),
                      height: 112,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: photos.isEmpty
                            ? const RoomPhotoPlaceholder()
                            : RoomPhotoGallery(
                                photos: photos,
                                label: 'Phòng ${lease.room}',
                                height: 112,
                                interactive: true,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.home_rounded,
                                size: 17,
                                color: tenantGreenDark,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Phòng trọ',
                                style: TextStyle(
                                  color: tenantGreenDark,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Phòng ${lease.room}',
                            style: const TextStyle(
                              color: tenantInk,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.property.name,
                            style: const TextStyle(
                              color: tenantInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            data.property.address,
                            style: const TextStyle(
                              color: tenantMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const TenantThinDivider(),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    _metric(
                      Icons.payments_outlined,
                      'Giá thuê',
                      '${formatTenantMoney(lease.monthlyRent)}/tháng',
                      (constraints.maxWidth - 12) * 0.58,
                      green: true,
                    ),
                    _metric(
                      Icons.square_foot_rounded,
                      'Diện tích',
                      room == null ? 'Chưa cập nhật' : '${room.area} m²',
                      (constraints.maxWidth - 12) * 0.42,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8F3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Heading(Icons.people_alt_rounded, 'Các bên tham gia'),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tenant = _party(
                    'Người thuê',
                    lease.tenantName,
                    lease.phone,
                    Icons.person_rounded,
                  );
                  final landlord = _party(
                    'Chủ trọ',
                    lease.landlordName,
                    lease.landlordContact,
                    Icons.home_work_rounded,
                  );
                  return constraints.maxWidth < 300
                      ? Column(
                          children: [
                            tenant,
                            const SizedBox(height: 16),
                            landlord,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: tenant),
                            const SizedBox(width: 16),
                            Expanded(child: landlord),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _Heading(Icons.history_toggle_off_rounded, 'Tiến độ hợp đồng'),
        const SizedBox(height: 16),
        _timeline(
          'Bắt đầu thuê',
          landlordDate(lease.startDate),
          'Hoàn tất',
          false,
        ),
        _timeline(
          'Đang hiệu lực',
          'Từ ${landlordDate(lease.startDate)} đến ${landlordDate(lease.endDate)}',
          'Hiện tại',
          false,
          current: true,
        ),
        _timeline(
          'Kết thúc hợp đồng',
          landlordDate(lease.endDate),
          'Dự kiến',
          true,
          upcoming: true,
        ),
        const SizedBox(height: 10),
        const TenantDetailNote(
          'Thông tin được cập nhật từ hợp đồng do chủ trọ cung cấp.',
          icon: Icons.fact_check_outlined,
        ),
      ],
    );
  }

  Widget _metric(
    IconData icon,
    String label,
    String value,
    double width, {
    bool green = false,
  }) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: tenantGreenDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: tenantMuted, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: green ? tenantGreenDark : tenantInk,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _party(String role, String name, String phone, IconData icon) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 19,
        backgroundColor: Colors.white,
        child: Icon(icon, color: tenantGreenDark, size: 23),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: const TextStyle(color: tenantMuted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              name.isEmpty ? 'Chưa cập nhật' : name,
              style: const TextStyle(
                color: tenantInk,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phone.isEmpty ? 'Chưa có liên hệ' : phone,
              style: const TextStyle(color: tenantMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _timeline(
    String title,
    String date,
    String status,
    bool last, {
    bool current = false,
    bool upcoming = false,
  }) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: upcoming
                    ? const Color(0xFFEDF1EF)
                    : const Color(0xFFDFF4E7),
                child: Icon(
                  upcoming
                      ? Icons.schedule_rounded
                      : current
                      ? Icons.arrow_forward_rounded
                      : Icons.check_circle_rounded,
                  size: 20,
                  color: upcoming ? tenantMuted : tenantGreen,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFBBE4CC)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 21, top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: tenantInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  date,
                  style: const TextStyle(
                    color: tenantMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 7),
        Align(
          alignment: Alignment.topRight,
          child: TenantStatusPill(
            status,
            color: upcoming ? tenantMuted : tenantGreenDark,
          ),
        ),
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.icon, this.title);
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: tenantGreenDark, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: tenantInk,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}
