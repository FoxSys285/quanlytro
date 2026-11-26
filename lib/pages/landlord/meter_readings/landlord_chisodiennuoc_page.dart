import 'package:flutter/material.dart';

import '../../../data/app_persistence.dart';
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
  LandlordDemoStore get _store =>
      widget.store ?? LandlordDemoStore.activeInstance;
  late LandlordDemoStore _observedStore;

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
    _observedStore = _store;
    _observedStore.addListener(_capNhat);
    if (widget.store == null) {
      RentalPortfolio.instance.addListener(_dongBoKhoHoatDong);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _store.prepareReadings(_ngayKyGhi);
    });
  }

  void _dongBoKhoHoatDong() {
    final current = _store;
    if (!identical(_observedStore, current)) {
      _observedStore.removeListener(_capNhat);
      _observedStore = current;
      _observedStore.addListener(_capNhat);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _store.prepareReadings(_ngayKyGhi);
      });
    }
    _capNhat();
  }

  void _capNhat() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (widget.store == null) {
      RentalPortfolio.instance.removeListener(_dongBoKhoHoatDong);
    }
    _observedStore.removeListener(_capNhat);
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
    final result = await showDialog<({int electric, int water})>(
      context: context,
      builder: (_) => _MeterReadingInputDialog(
        chiSo: chiSo,
        fieldBuilder: _truongNhapChiSo,
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    if (result.electric < chiSo.oldElectric || result.water < chiSo.oldWater) {
      showLandlordMessage(context, 'Chỉ số mới không được nhỏ hơn chỉ số cũ.');
      return;
    }

    _store.saveReading(chiSo, result.electric, result.water);
    try {
      await AppPersistence.current?.flush();
    } catch (failure) {
      if (!mounted) return;
      showLandlordMessage(context, AppPersistence.saveFailureMessage(failure));
      return;
    }
    if (!mounted) return;
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
    if (hopDong != null &&
        (hopDong.waterType == 'Theo tháng' ||
            hopDong.waterType == 'Theo người')) {
      widgetNuoc = Text(
        hopDong.waterType == 'Theo người'
            ? 'Nước theo người · ${formatLandlordMoney(hopDong.waterPrice)}/người'
            : 'Nước theo tháng · ${formatLandlordMoney(hopDong.waterPrice)}',
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

class _MeterReadingInputDialog extends StatefulWidget {
  const _MeterReadingInputDialog({
    required this.chiSo,
    required this.fieldBuilder,
  });

  final LandlordMeterReading chiSo;
  final Widget Function({
    required TextEditingController controller,
    required IconData icon,
    required String ten,
    required String donVi,
    required int chiSoCu,
    required TextInputAction textInputAction,
  })
  fieldBuilder;

  @override
  State<_MeterReadingInputDialog> createState() =>
      _MeterReadingInputDialogState();
}

class _MeterReadingInputDialogState extends State<_MeterReadingInputDialog> {
  late final TextEditingController _controllerDien = TextEditingController(
    text: widget.chiSo.newElectric?.toString() ?? '',
  );
  late final TextEditingController _controllerNuoc = TextEditingController(
    text: widget.chiSo.newWater?.toString() ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controllerDien.dispose();
    _controllerNuoc.dispose();
    super.dispose();
  }

  void _submit() {
    final electric = int.tryParse(_controllerDien.text.trim());
    final water = int.tryParse(_controllerNuoc.text.trim());
    if (electric == null || water == null) {
      setState(() => _error = 'Vui lòng nhập số hợp lệ.');
      return;
    }
    if (electric < widget.chiSo.oldElectric ||
        water < widget.chiSo.oldWater) {
      setState(() => _error = 'Chỉ số mới không được nhỏ hơn chỉ số cũ.');
      return;
    }
    Navigator.pop(context, (electric: electric, water: water));
  }

  @override
  Widget build(BuildContext context) {
    final palette = LandlordPalette.of(context);
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        'Nhập chỉ số phòng ${widget.chiSo.room}',
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
            widget.fieldBuilder(
              controller: _controllerDien,
              icon: Icons.bolt_outlined,
              ten: 'Chỉ số điện',
              donVi: 'kWh',
              chiSoCu: widget.chiSo.oldElectric,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 20),
            widget.fieldBuilder(
              controller: _controllerNuoc,
              icon: Icons.water_drop_outlined,
              ten: 'Chỉ số nước',
              donVi: 'm³',
              chiSoCu: widget.chiSo.oldWater,
              textInputAction: TextInputAction.done,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Lưu')),
      ],
    );
  }
}
