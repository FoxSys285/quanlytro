import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import '../finance/landlord_finance_models.dart';
import 'models/landlord_meter_reading.dart';

// Tên Class chính bằng tiếng Việt
class LandlordChiSoDienNuocPage extends StatefulWidget {
  const LandlordChiSoDienNuocPage({super.key});

  @override
  State<LandlordChiSoDienNuocPage> createState() =>
      _LandlordChiSoDienNuocPageState();
}

class _LandlordChiSoDienNuocPageState extends State<LandlordChiSoDienNuocPage> {
  // 1. DỮ KIỆN (Kho lưu trữ và biến trạng thái đưa lên đầu)
  final _store = LandlordDemoStore.instance;

  String _kyGhi = 'Tháng 10/2026';

  DateTime get _ngayKyGhi {
    if (_kyGhi == 'Tháng 10/2026') {
      return DateTime(2026, 10);
    } else {
      return DateTime(2026, 9);
    }
  }

  List<LandlordMeterReading> get _danhSachChiSo =>
      _store.readingsForPeriod(_ngayKyGhi);

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
      chuoiThanhTien = '$soTieuThu $donViTinh · ${formatLandlordMoney(thanhTien)}';
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: landlordBlue),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$tenLoai: $chiSoCu → $chuoiChiSoMoi',
            style: const TextStyle(color: landlordInk, fontSize: 13),
          ),
        ),
        Text(
          chuoiThanhTien,
          style: const TextStyle(color: landlordMuted, fontSize: 12),
        ),
      ],
    );
  }

  // Hộp thoại nhập chỉ số mới
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
      builder: (context) => AlertDialog(
        title: Text('Nhập chỉ số phòng ${chiSo.room}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerDien,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Chỉ số điện mới',
                helperText: 'Chỉ số cũ: ${chiSo.oldElectric}',
              ),
            ),
            TextField(
              controller: controllerNuoc,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Chỉ số nước mới',
                helperText: 'Chỉ số cũ: ${chiSo.oldWater}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
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
    LandlordLease? hopDong;
    for (int i = 0; i < _store.activeLeases.length; i++) {
      final item = _store.activeLeases[i];
      if (_store.canonicalRoom(item.room) ==
          _store.canonicalRoom(chiSo.room)) {
        hopDong = item;
        break;
      }
    }

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

    int donGiaDien = 0;
    if (hopDong != null) {
      donGiaDien = hopDong.electricityPrice;
    } else {
      final dichVuDien = _store.serviceById('electricity');
      if (dichVuDien != null) {
        donGiaDien = dichVuDien.price;
      }
    }

    Widget widgetNuoc;
    if (hopDong != null && hopDong.waterType == 'Theo tháng') {
      widgetNuoc = Text(
        'Nước theo tháng · ${formatLandlordMoney(hopDong.waterPrice)}',
      );
    } else {
      int donGiaNuoc = 0;
      if (hopDong != null) {
        donGiaNuoc = hopDong.waterPrice;
      } else {
        final dichVuNuoc = _store.serviceById('water');
        if (dichVuNuoc != null) {
          donGiaNuoc = dichVuNuoc.price;
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

    return LandlordCard(
      onTap: () {
        _moHopThoaiNhapChiSo(chiSo);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Phòng ${chiSo.room}',
                style: const TextStyle(
                  color: landlordInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
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
    int soLuongDaNhap = 0;
    for (int i = 0; i < _danhSachChiSo.length; i++) {
      if (_danhSachChiSo[i].isDone) {
        soLuongDaNhap = soLuongDaNhap + 1;
      }
    }

    Color mauTrangThai;
    if (soLuongDaNhap == _danhSachChiSo.length) {
      mauTrangThai = const Color(0xFF16836F);
    } else {
      mauTrangThai = const Color(0xFFE08A1E);
    }

    final List<Widget> danhSachWidget = [
      const LandlordPageTitle(
        title: 'Chỉ số điện nước',
        subtitle: 'Nhập chỉ số cuối kỳ cho từng phòng.',
      ),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _kyGhi,
              decoration: const InputDecoration(
                labelText: 'Kỳ ghi chỉ số',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Tháng 10/2026',
                  child: Text('Tháng 10/2026'),
                ),
                DropdownMenuItem(
                  value: 'Tháng 9/2026',
                  child: Text('Tháng 9/2026'),
                ),
              ],
              onChanged: (giaTriMoi) {
                if (giaTriMoi != null) {
                  setState(() {
                    _kyGhi = giaTriMoi;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          LandlordStatusPill(
            'Đã nhập $soLuongDaNhap/${_danhSachChiSo.length}',
            color: mauTrangThai,
          ),
        ],
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

    return LandlordPageFrame(
      children: danhSachWidget,
    );
  }
}

