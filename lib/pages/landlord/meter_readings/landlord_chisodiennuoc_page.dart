import 'package:flutter/material.dart';

import '../landlord_theme.dart';
import '../landlord_glass.dart';

import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import '../finance/landlord_finance_models.dart';
import 'models/landlord_chisodiennuoc.dart';

// Tên Class chính bằng tiếng Việt
class LandlordChiSoDienNuocPage extends StatefulWidget {
  const LandlordChiSoDienNuocPage({super.key, this.store, this.initialRoom});

  final LandlordDemoStore? store;
  final String? initialRoom;

  @override
  State<LandlordChiSoDienNuocPage> createState() =>
      _LandlordChiSoDienNuocPageState();
}

class _LandlordChiSoDienNuocPageState extends State<LandlordChiSoDienNuocPage> {
  // 1. DỮ KIỆN (Kho lưu trữ và biến trạng thái đưa lên đầu)
  late final LandlordDemoStore _store =
      widget.store ?? LandlordDemoStore.activeInstance;

  DateTime _ngayKyGhi = DateTime(DateTime.now().year, DateTime.now().month);
  List<DateTime> get _cacKy => List.generate(
    25,
    (i) => DateTime(DateTime.now().year, DateTime.now().month + 1 - i),
  );

  List<LandlordMeterReading> get _danhSachChiSo =>
      _store.readingsForPeriod(_ngayKyGhi).where((reading) {
        final room = widget.initialRoom;
        return room == null ||
            _store.canonicalRoom(reading.room) == _store.canonicalRoom(room);
      }).toList();

  // 2. VÒNG ĐỜI VÀ LẮNG NGHE
  @override
  void initState() {
    super.initState();
    _store.addListener(_capNhat);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _store.prepareReadings(_ngayKyGhi);
    });
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
  // Hàm tạo từng dòng thông số điện / nước
  Widget _taoDongChiSo({
    required IconData icon,
    required String tenLoai,
    required int chiSoCu,
    required int? chiSoMoi,
    required int soTieuThu,
    required String donViTinh,
    required int donGia,
  }) {
    String chuoiChiSoMoi = '...';
    if (chiSoMoi != null) {
      chuoiChiSoMoi = '$chiSoMoi';
    }

    String chuoiThanhTien;
    if (chiSoMoi == null) {
      chuoiThanhTien = '--';
    } else {
      final thanhTien = soTieuThu * donGia;
      chuoiThanhTien =
          '$soTieuThu $donViTinh · ${formatLandlordMoney(thanhTien)}';
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: landlordBlue),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$tenLoai: $chiSoCu → $chuoiChiSoMoi',
            style: TextStyle(
              color: LandlordPalette.of(context).ink,
              fontSize: 13,
            ),
          ),
        ),
        Flexible(
          child: Text(
            chuoiThanhTien,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: LandlordPalette.of(context).muted,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Hộp thoại nhập chỉ số mới
  Widget _truongNhapChiSo({
    required TextEditingController controller,
    required IconData icon,
    required String ten,
    required String donVi,
    required int chiSoCu,
    required TextInputAction textInputAction,
  }) {
    final palette = LandlordPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: palette.primary),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                ten,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'Cũ: $chiSoCu $donVi',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: 'Nhập chỉ số mới',
            suffixText: donVi,
            filled: true,
            fillColor: palette.surfaceAlt,
          ),
        ),
      ],
    );
  }

  Future<void> _moHopThoaiNhapChiSo(LandlordMeterReading chiSo) async {
    String chuoiDienBanDau = '';
    if (chiSo.newElectric != null) {
      chuoiDienBanDau = chiSo.newElectric.toString();
    }

    String chuoiNuocBanDau = '';
    if (chiSo.newWater != null) {
      chuoiNuocBanDau = chiSo.newWater.toString();
    }

    final controllerDien = TextEditingController(text: chuoiDienBanDau);
    final controllerNuoc = TextEditingController(text: chuoiNuocBanDau);

    final daBamLuu = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final palette = LandlordPalette.of(dialogContext);
        return AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          backgroundColor: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Nhập chỉ số phòng ${chiSo.room}',
            style: TextStyle(
              color: palette.ink,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cập nhật chỉ số điện nước cho kỳ ghi hiện tại.',
                  style: TextStyle(color: palette.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                _truongNhapChiSo(
                  controller: controllerDien,
                  icon: Icons.bolt_outlined,
                  ten: 'Chỉ số điện',
                  donVi: 'kWh',
                  chiSoCu: chiSo.oldElectric,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                _truongNhapChiSo(
                  controller: controllerNuoc,
                  icon: Icons.water_drop_outlined,
                  ten: 'Chỉ số nước',
                  donVi: 'm³',
                  chiSoCu: chiSo.oldWater,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (daBamLuu != true || !mounted) {
      return;
    }

    final chiSoDienMoi = int.tryParse(controllerDien.text.trim());
    final chiSoNuocMoi = int.tryParse(controllerNuoc.text.trim());
    if (chiSoDienMoi == null || chiSoNuocMoi == null) {
      showLandlordMessage(context, 'Vui lòng nhập số hợp lệ.');
      return;
    }

    if (chiSoDienMoi < chiSo.oldElectric || chiSoNuocMoi < chiSo.oldWater) {
      showLandlordMessage(context, 'Chỉ số mới không được nhỏ hơn chỉ số cũ.');
      return;
    }

    _store.saveReading(chiSo, chiSoDienMoi, chiSoNuocMoi);
    showLandlordMessage(context, 'Đã lưu chỉ số phòng ${chiSo.room}.');
  }

  // Hàm tạo thẻ hiển thị thông tin điện nước của 1 phòng
  Widget _taoTheChiSo(LandlordMeterReading chiSo) {
    // Tìm hợp đồng của phòng bằng LINQ gọn gàng
    final hopDong = _store.activeLeases
        .where(
          (item) =>
              _store.canonicalRoom(item.room) ==
              _store.canonicalRoom(chiSo.room),
        )
        .firstOrNull;

    Widget widgetTrangThai;
    if (chiSo.isDone) {
      widgetTrangThai = const LandlordStatusPill(
        'Đã nhập',
        color: Color(0xFF16836F),
      );
    } else {
      widgetTrangThai = const LandlordStatusPill(
        'Chưa nhập',
        color: Color(0xFFE08A1E),
      );
    }

    // Lấy đơn giá điện: ưu tiên cấu hình giá trong Bảng giá dịch vụ bằng LINQ
    int donGiaDien = 3500;
    final dichVuDien = _store.serviceById('electricity');
    if (dichVuDien != null) {
      donGiaDien = dichVuDien.price;
    } else {
      final dvDien = _store.services
          .where((dv) => dv.active && dv.name.toLowerCase().contains('điện'))
          .firstOrNull;
      if (dvDien != null) {
        donGiaDien = dvDien.price;
      } else if (hopDong != null) {
        donGiaDien = hopDong.electricityPrice;
      }
    }

    Widget widgetNuoc;
    if (hopDong != null && hopDong.waterType == 'Theo tháng') {
      widgetNuoc = Text(
        'Nước theo tháng · ${formatLandlordMoney(hopDong.waterPrice)}',
      );
    } else {
      // Lấy đơn giá nước: ưu tiên cấu hình giá trong Bảng giá dịch vụ bằng LINQ
      int donGiaNuoc = 15000;
      final dichVuNuoc = _store.serviceById('water');
      if (dichVuNuoc != null) {
        donGiaNuoc = dichVuNuoc.price;
      } else {
        final dvNuoc = _store.services
            .where((dv) => dv.active && dv.name.toLowerCase().contains('nước'))
            .firstOrNull;
        if (dvNuoc != null) {
          donGiaNuoc = dvNuoc.price;
        } else if (hopDong != null) {
          donGiaNuoc = hopDong.waterPrice;
        }
      }

      widgetNuoc = _taoDongChiSo(
        icon: Icons.water_drop_outlined,
        tenLoai: 'Nước',
        chiSoCu: chiSo.oldWater,
        chiSoMoi: chiSo.newWater,
        soTieuThu: chiSo.waterUsage,
        donViTinh: 'm³',
        donGia: donGiaNuoc,
      );
    }

    return LandlordGlassCard(
      onTap: () {
        _moHopThoaiNhapChiSo(chiSo);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Phòng ${chiSo.room}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: LandlordPalette.of(context).ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              widgetTrangThai,
            ],
          ),
          const SizedBox(height: 10),
          _taoDongChiSo(
            icon: Icons.bolt_outlined,
            tenLoai: 'Điện',
            chiSoCu: chiSo.oldElectric,
            chiSoMoi: chiSo.newElectric,
            soTieuThu: chiSo.electricUsage,
            donViTinh: 'kWh',
            donGia: donGiaDien,
          ),
          const SizedBox(height: 6),
          widgetNuoc,
        ],
      ),
    );
  }

  // 4. HÀM BUILD ĐẶT Ở DƯỚI CÙNG
  @override
  Widget build(BuildContext context) {
    // Đếm số lượng phòng đã ghi chỉ số bằng LINQ
    final soLuongDaNhap = _danhSachChiSo.where((c) => c.isDone).length;

    Color mauTrangThai;
    if (soLuongDaNhap == _danhSachChiSo.length) {
      mauTrangThai = const Color(0xFF16836F);
    } else {
      mauTrangThai = const Color(0xFFE08A1E);
    }

    final List<Widget> danhSachWidget = [
      LandlordGlassSection(
        title: widget.initialRoom == null
            ? 'Ghi điện nước'
            : 'Phòng ${widget.initialRoom}',
        subtitle: 'Cập nhật chỉ số điện nước kỳ ${landlordMonth(_ngayKyGhi)}.',
      ),
      LandlordGlassCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final picker = DropdownButtonFormField<DateTime>(
              initialValue: _ngayKyGhi,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Kỳ ghi chỉ số',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final period in _cacKy)
                  DropdownMenuItem(
                    value: period,
                    child: Text(
                      landlordMonth(period),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (giaTriMoi) {
                if (giaTriMoi != null) {
                  setState(() {
                    _ngayKyGhi = giaTriMoi;
                  });
                  _store.prepareReadings(giaTriMoi);
                }
              },
            );
            final status = LandlordStatusPill(
              'Đã nhập $soLuongDaNhap/${_danhSachChiSo.length}',
              color: mauTrangThai,
            );
            if (constraints.maxWidth < 480) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [picker, const SizedBox(height: 8), status],
              );
            }
            return Row(
              children: [
                Expanded(child: picker),
                const SizedBox(width: 12),
                status,
              ],
            );
          },
        ),
      ),
      const SizedBox(height: 14),
    ];

    if (_danhSachChiSo.isEmpty) {
      danhSachWidget.add(
        const LandlordEmptyState(message: 'Chưa có chỉ số cho kỳ đã chọn.'),
      );
    } else {
      for (int i = 0; i < _danhSachChiSo.length; i++) {
        danhSachWidget.add(_taoTheChiSo(_danhSachChiSo[i]));
      }
    }

    return LandlordGlassPage(
      title: 'Ghi điện nước',
      subtitle: _store.property.name,
      kicker: 'QUẢN LÝ VẬN HÀNH',
      store: _store,
      children: danhSachWidget,
    );
  }
}
