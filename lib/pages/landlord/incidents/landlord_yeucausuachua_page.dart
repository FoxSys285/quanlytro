import 'package:flutter/material.dart';

import '../landlord_theme.dart';

import '../landlord_demo_store.dart';
import '../landlord_glass.dart';
import '../landlord_ui.dart';
import 'models/landlord_suco.dart';

// Tên Class chính bằng tiếng Việt
class LandlordYeuCauSuaChuaPage extends StatefulWidget {
  const LandlordYeuCauSuaChuaPage({super.key, this.store});

  final LandlordDemoStore? store;

  @override
  State<LandlordYeuCauSuaChuaPage> createState() =>
      _LandlordYeuCauSuaChuaPageState();
}

class _LandlordYeuCauSuaChuaPageState extends State<LandlordYeuCauSuaChuaPage> {
  // 1. DỮ KIỆN (Biến trạng thái đưa lên đầu)
  IncidentStatus? _boLocTrangThai;

  LandlordDemoStore get _store =>
      widget.store ?? LandlordDemoStore.activeInstance;
  List<LandlordIncident> get _danhSachSuCo => _store.incidents;

  // 2. VÒNG ĐỜI VÀ LẮNG NGHE
  @override
  void initState() {
    super.initState();
    _store.addListener(_capNhat);
  }

  void _capNhat() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _store.removeListener(_capNhat);
    super.dispose();
  }

  // 3. CÁC HÀM XỬ LÝ (Viết trước hàm build)
  // Hàm tạo chip lọc trạng thái
  Widget _taoChipLoc(String nhan, IncidentStatus? trangThai) {
    final selected = _boLocTrangThai == trangThai;
    return ChoiceChip(
      label: Text(nhan),
      selected: selected,
      selectedColor: landlordBlue,
      backgroundColor: LandlordPalette.of(context).surface,
      side: BorderSide(color: selected ? Colors.transparent : Colors.white),
      labelStyle: TextStyle(
        color: selected ? Colors.white : landlordBlue,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _boLocTrangThai = trangThai),
    );
  }

  // Hàm tạo danh sách chip lọc trạng thái bằng LINQ gọn gàng
  List<Widget> _taoDanhSachChipLoc() {
    return [
      _taoChipLoc('Tất cả', null),
      ...IncidentStatus.values.map(
        (trangThai) => _taoChipLoc(trangThai.label, trangThai),
      ),
    ];
  }

  // Hàm mở bảng chi tiết sự cố và cho phép chủ trọ chuyển đổi trạng thái
  void _moChiTietSuCo(LandlordIncident suCo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (nguCanhBang) => Container(
        decoration: BoxDecoration(
          color: LandlordPalette.of(context).surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LandlordPalette.of(context).line,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  suCo.title,
                  style: TextStyle(
                    color: LandlordPalette.of(context).ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    LandlordStatusPill(
                      suCo.status.label,
                      color: suCo.status.color,
                    ),
                    if (suCo.urgent)
                      const LandlordStatusPill(
                        'Khẩn cấp',
                        color: Color(0xFFD64545),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Phòng ${suCo.room} · ${suCo.category}',
                  style: TextStyle(
                    color: LandlordPalette.of(context).ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Người báo: ${suCo.reporter} · ${suCo.date}',
                  style: TextStyle(color: LandlordPalette.of(context).muted),
                ),
                const SizedBox(height: 14),
                LandlordGlassCard(child: Text(suCo.description)),
                const SizedBox(height: 16),
                LandlordGlassSection(
                  title: 'Cập nhật trạng thái',
                  subtitle: 'Chọn trạng thái mới cho yêu cầu này.',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final trangThai in IncidentStatus.values)
                      _statusChoice(
                        suCo,
                        trangThai,
                        () => Navigator.pop(nguCanhBang),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChoice(
    LandlordIncident suCo,
    IncidentStatus trangThai,
    VoidCallback close,
  ) {
    final selected = suCo.status == trangThai;
    return ChoiceChip(
      label: Text(trangThai.label),
      selected: selected,
      selectedColor: landlordBlue,
      backgroundColor: LandlordPalette.of(context).surfaceAlt,
      labelStyle: TextStyle(
        color: selected ? Colors.white : LandlordPalette.of(context).ink,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) {
        _store.updateIncident(suCo, trangThai);
        close();
        showLandlordMessage(
          context,
          'Đã chuyển "${suCo.title}" sang ${trangThai.label}.',
        );
      },
    );
  }

  // 4. HÀM BUILD ĐẶT Ở DƯỚI CÙNG
  @override
  Widget build(BuildContext context) {
    // Lọc danh sách sự cố theo trạng thái bằng LINQ gọn gàng
    final danhSachHienThi = _boLocTrangThai == null
        ? _danhSachSuCo
        : _danhSachSuCo.where((s) => s.status == _boLocTrangThai).toList();

    return LandlordFeaturePage(
      title: 'Yêu cầu sửa chữa',
      subtitle: 'Tiếp nhận và cập nhật tiến độ sự cố của người thuê.',
      icon: Icons.build_outlined,
      kicker: 'BẢO TRÌ NHÀ TRỌ',
      children: [
        LandlordGlassSection(
          title: 'Yêu cầu sửa chữa',
          subtitle: '${danhSachHienThi.length} yêu cầu phù hợp.',
        ),
        Wrap(spacing: 8, runSpacing: 8, children: _taoDanhSachChipLoc()),
        const SizedBox(height: 10),
        if (danhSachHienThi.isEmpty)
          const LandlordGlassCard(
            child: Center(child: Text('Không có yêu cầu nào.')),
          ),
        for (final suCo in danhSachHienThi)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LandlordGlassCard(
              onTap: () => _moChiTietSuCo(suCo),
              tint: suCo.urgent ? const Color(0xFFD64545) : null,
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
                          color: suCo.urgent
                              ? const Color(0xFFFCE8EA)
                              : const Color(0xFFE4EFFF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          suCo.urgent
                              ? Icons.warning_amber_rounded
                              : Icons.build_outlined,
                          color: suCo.urgent
                              ? const Color(0xFFD64545)
                              : landlordBlue,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suCo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: LandlordPalette.of(context).ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Phòng ${suCo.room} · ${suCo.reporter}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: LandlordPalette.of(context).muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      LandlordStatusPill(
                        suCo.status.label,
                        color: suCo.status.color,
                      ),
                    ],
                  ),
                  if (suCo.urgent) ...[
                    const SizedBox(height: 8),
                    const LandlordStatusPill(
                      'Khẩn cấp',
                      color: Color(0xFFD64545),
                    ),
                  ],
                  if (suCo.description.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      suCo.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: LandlordPalette.of(context).muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    suCo.date,
                    style: TextStyle(
                      color: LandlordPalette.of(context).muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
