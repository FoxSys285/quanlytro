import 'package:flutter/material.dart';

import '../../../data/admin_store.dart';
import '../../../layouts/landlord_navigation.dart';
import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_theme.dart';
import 'components/landlord_property_image.dart';
import 'components/verification_visuals.dart';
import 'landlord_verification_page.dart';

class LandlordVerificationListPage extends StatefulWidget {
  const LandlordVerificationListPage({super.key});
  @override
  State<LandlordVerificationListPage> createState() =>
      _LandlordVerificationListPageState();
}

class _LandlordVerificationListPageState
    extends State<LandlordVerificationListPage> {
  String _query = '';
  String _filter = 'Tất cả';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      RentalPortfolio.instance,
      AdminStore.instance,
    ]),
    builder: (context, _) {
      final stores = RentalPortfolio.instance.stores;
      final admin = AdminStore.instance;
      final palette = LandlordPalette.of(context);
      final verifiedCount = stores
          .where((s) => admin.isVerified(s.property.id))
          .length;
      final visible = stores.where((s) {
        final verified = admin.isVerified(s.property.id);
        return '${s.property.name} ${s.property.address}'
                .toLowerCase()
                .contains(_query.trim().toLowerCase()) &&
            switch (_filter) {
              'Đã xác minh' => verified,
              'Chưa xác minh' => !verified,
              _ => true,
            };
      }).toList();
      return VerificationPageFrame(
        title: 'Xác minh nhà trọ',
        subtitle: 'Theo dõi trạng thái xác minh và hoàn thiện hồ sơ cho từng nhà trọ của bạn.',
        children: [
          LandlordBluePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .17),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'An tâm cho thuê',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hồ sơ minh bạch, kết nối tin cậy.',
                            style: TextStyle(
                              color: Color(0xFFDDEEFF),
                              fontSize: 12,
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
                    _SummaryValue(value: stores.length, label: 'Nhà trọ'),
                    _SummaryValue(value: verifiedCount, label: 'Đã xác minh'),
                    _SummaryValue(
                      value: stores.length - verifiedCount,
                      label: 'Chưa xác minh',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stores.isEmpty ? 0 : verifiedCount / stores.length,
                    minHeight: 5,
                    color: const Color(0xFF8FE9E2),
                    backgroundColor: Colors.white.withValues(alpha: .2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const LandlordGlassSection(
            title: 'Nhà trọ của bạn',
            subtitle: 'Chọn nhà trọ để xem hồ sơ và phản hồi xét duyệt.',
          ),
          LandlordGlassSearch(
            hint: 'Tìm tên nhà trọ, địa chỉ...',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filter in ['Tất cả', 'Chưa xác minh', 'Đã xác minh'])
                ChoiceChip(
                  label: Text(filter),
                  selected: _filter == filter,
                  showCheckmark: false,
                  selectedColor: palette.primarySoft,
                  backgroundColor: palette.surface.withValues(alpha: .8),
                  side: BorderSide(
                    color: _filter == filter
                        ? palette.primary.withValues(alpha: .35)
                        : palette.surface,
                  ),
                  labelStyle: TextStyle(
                    color: _filter == filter ? palette.primary : palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  onSelected: (_) => setState(() => _filter = filter),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (visible.isEmpty)
            LandlordGlassCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Column(
                  children: [
                    VerificationIcon(
                      icon: stores.isEmpty
                          ? Icons.home_work_outlined
                          : Icons.search_off_rounded,
                      size: 58,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      stores.isEmpty
                          ? 'Chưa có nhà trọ'
                          : 'Không tìm thấy nhà trọ',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stores.isEmpty
                          ? 'Thêm nhà trọ để bắt đầu gửi hồ sơ xác minh.'
                          : 'Thử từ khóa khác hoặc thay đổi bộ lọc.',
                      style: TextStyle(color: palette.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 2 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final store in visible)
                    SizedBox(
                      width: width,
                      child: _PropertyVerificationCard(store: store),
                    ),
                ],
              );
            },
          ),
        ],
      );
    },
  );
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});
  final int value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFDDEEFF)),
        ),
      ],
    ),
  );
}

class _PropertyVerificationCard extends StatelessWidget {
  const _PropertyVerificationCard({required this.store});
  final LandlordDemoStore store;
  @override
  Widget build(BuildContext context) {
    final property = store.property;
    final palette = LandlordPalette.of(context);
    final admin = AdminStore.instance;
    final verified = admin.isVerified(property.id);
    final note = admin.pendingReviewNote(property.id);
    final submitted = property.verificationSubmittedAt != null;
    return LandlordGlassCard(
      onTap: () => LandlordNavigation.push<void>(
        context,
        page: LandlordVerificationPage(store: store),
        destinationId: 'properties',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 76,
                child: LandlordPropertyImage(
                  url: property.imageUrl,
                  bytes: property.imageBytes,
                  height: 82,
                  borderRadius: 15,
                  showIllustrationLabel: false,
                ),
              ),
              const SizedBox(width: 13),
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
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      property.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${store.catalog.length} phòng',
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: palette.line.withValues(alpha: .7)),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: VerificationBadge(
                    label: verified ? 'Đã xác minh' : 'Chưa xác minh',
                    color: verified ? verificationGreen : palette.primary,
                    icon: verified
                        ? Icons.verified_rounded
                        : Icons.shield_outlined,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verified
                      ? 'Xem hồ sơ'
                      : submitted
                      ? 'Chi tiết hồ sơ'
                      : 'Xác minh ngay',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                color: palette.primary,
                size: 17,
              ),
            ],
          ),
          if (!verified && (submitted || note.isNotEmpty)) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                Icon(
                  note.isNotEmpty
                      ? Icons.mark_chat_unread_outlined
                      : Icons.schedule_rounded,
                  size: 14,
                  color: note.isNotEmpty ? verificationAmber : palette.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note.isNotEmpty
                        ? 'Admin yêu cầu bổ sung hồ sơ'
                        : 'Đã nộp hồ sơ · Đang chờ xét duyệt',
                    style: TextStyle(
                      color: note.isNotEmpty
                          ? verificationAmber
                          : palette.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
