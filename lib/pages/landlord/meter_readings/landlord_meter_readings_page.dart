import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import 'models/landlord_meter_reading.dart';

class LandlordMeterReadingsPage extends StatefulWidget {
  const LandlordMeterReadingsPage({super.key});

  @override
  State<LandlordMeterReadingsPage> createState() =>
      _LandlordMeterReadingsPageState();
}

class _LandlordMeterReadingsPageState extends State<LandlordMeterReadingsPage> {
  // Đơn giá điện và nước áp dụng mặc định
  static const _giaDien = 3500;
  static const _giaNuoc = 15000;

  // Kỳ ghi chỉ số hiện tại
  String _kyGhiChiSo = 'Tháng 10/2026';

  // Danh sách chỉ số điện nước theo từng phòng
  final _danhSachChiSo = <LandlordMeterReading>[
    LandlordMeterReading(
      room: 'A.101',
      oldElectric: 1250,
      oldWater: 320,
      newElectric: 1362,
      newWater: 328,
    ),
    LandlordMeterReading(room: 'A.102', oldElectric: 980, oldWater: 210),
    LandlordMeterReading(
      room: 'A.302',
      oldElectric: 2104,
      oldWater: 455,
      newElectric: 2230,
      newWater: 462,
    ),
    LandlordMeterReading(room: 'B.105', oldElectric: 640, oldWater: 150),
    LandlordMeterReading(room: 'B.201', oldElectric: 1530, oldWater: 298),
  ];

  @override
  Widget build(BuildContext context) {
    // Đếm số lượng phòng đã hoàn tất ghi chỉ số
    int soLuongDaNhap = 0;
    for (int i = 0; i < _danhSachChiSo.length; i++) {
      if (_danhSachChiSo[i].isDone) {
        soLuongDaNhap++;
      }
    }

    // Chọn màu sắc hiển thị cho huy hiệu thống kê tiến độ
    Color mauHuyHieu;
    if (soLuongDaNhap == _danhSachChiSo.length) {
      mauHuyHieu = const Color(0xFF16836F); // Xanh lá khi hoàn thành 100%
    } else {
      mauHuyHieu = const Color(0xFFE08A1E); // Cam khi chưa nhập đủ
    }

    // Danh sách widget hiển thị trên màn hình
    final List<Widget> danhSachWidget = [
      const LandlordPageTitle(
        title: 'Chỉ số điện nước',
        subtitle: 'Nhập chỉ số cuối kỳ cho từng phòng.',
      ),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _kyGhiChiSo,
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
                    _kyGhiChiSo = giaTriMoi;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          LandlordStatusPill(
            'Đã nhập $soLuongDaNhap/${_danhSachChiSo.length}',
            color: mauHuyHieu,
          ),
        ],
      ),
      const SizedBox(height: 14),
    ];

    // Tạo thẻ chỉ số cho từng phòng
    for (int i = 0; i < _danhSachChiSo.length; i++) {
      danhSachWidget.add(_taoTheChiSo(_danhSachChiSo[i]));
    }

    return LandlordPageFrame(
      children: danhSachWidget,
    );
  }

  // Hàm xây dựng thẻ hiển thị chỉ số của một phòng
  Widget _taoTheChiSo(LandlordMeterReading chiSoPhong) {
    Widget huyHieuTrangThai;
    if (chiSoPhong.isDone) {
      huyHieuTrangThai = const LandlordStatusPill(
        'Đã nhập',
        color: Color(0xFF16836F),
      );
    } else {
      huyHieuTrangThai = const LandlordStatusPill(
        'Chưa nhập',
        color: Color(0xFFE08A1E),
      );
    }

    return LandlordCard(
      onTap: () => _moHopThoaiNhapChiSo(chiSoPhong),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Phòng ${chiSoPhong.room}',
                style: const TextStyle(
                  color: landlordInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              huyHieuTrangThai,
            ],
          ),
          const SizedBox(height: 10),
          _taoDongChiSo(
            icon: Icons.bolt_outlined,
            label: 'Điện',
            chiSoCu: chiSoPhong.oldElectric,
            chiSoMoi: chiSoPhong.newElectric,
            soLuongSuDung: chiSoPhong.electricUsage,
            donVi: 'kWh',
            donGia: _giaDien,
          ),
          const SizedBox(height: 6),
          _taoDongChiSo(
            icon: Icons.water_drop_outlined,
            label: 'Nước',
            chiSoCu: chiSoPhong.oldWater,
            chiSoMoi: chiSoPhong.newWater,
            soLuongSuDung: chiSoPhong.waterUsage,
            donVi: 'm³',
            donGia: _giaNuoc,
          ),
        ],
      ),
    );
  }

  // Hàm tạo dòng hiển thị chi tiết (Điện hoặc Nước)
  Widget _taoDongChiSo({
    required IconData icon,
    required String label,
    required int chiSoCu,
    required int? chiSoMoi,
    required int soLuongSuDung,
    required String donVi,
    required int donGia,
  }) {
    String chuoiChiSoMoi;
    if (chiSoMoi != null) {
      chuoiChiSoMoi = chiSoMoi.toString();
    } else {
      chuoiChiSoMoi = '...';
    }

    String chuoiChiPhi;
    if (chiSoMoi == null) {
      chuoiChiPhi = '--';
    } else {
      chuoiChiPhi =
          '$soLuongSuDung $donVi · ${formatLandlordMoney(soLuongSuDung * donGia)}';
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: landlordBlue),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$label: $chiSoCu → $chuoiChiSoMoi',
            style: const TextStyle(color: landlordInk, fontSize: 13),
          ),
        ),
        Text(
          chuoiChiPhi,
          style: const TextStyle(color: landlordMuted, fontSize: 12),
        ),
      ],
    );
  }

  // Hàm mở hộp thoại nhập chỉ số điện nước mới
  Future<void> _moHopThoaiNhapChiSo(LandlordMeterReading chiSoPhong) async {
    String chiSoDienBanDau = '';
    if (chiSoPhong.newElectric != null) {
      chiSoDienBanDau = chiSoPhong.newElectric.toString();
    }

    String chiSoNuocBanDau = '';
    if (chiSoPhong.newWater != null) {
      chiSoNuocBanDau = chiSoPhong.newWater.toString();
    }

    final oNhapDien = TextEditingController(text: chiSoDienBanDau);
    final oNhapNuoc = TextEditingController(text: chiSoNuocBanDau);

    final daLuu = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nhập chỉ số phòng ${chiSoPhong.room}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oNhapDien,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Chỉ số điện mới',
                helperText: 'Chỉ số cũ: ${chiSoPhong.oldElectric}',
              ),
            ),
            TextField(
              controller: oNhapNuoc,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Chỉ số nước mới',
                helperText: 'Chỉ số cũ: ${chiSoPhong.oldWater}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    // Kiểm tra nếu người dùng không bấm lưu hoặc màn hình đã đóng
    if (daLuu != true) {
      return;
    }
    if (!mounted) {
      return;
    }

    final chiSoDienMoi = int.tryParse(oNhapDien.text.trim());
    final chiSoNuocMoi = int.tryParse(oNhapNuoc.text.trim());
    if (chiSoDienMoi == null || chiSoNuocMoi == null) {
      showLandlordMessage(context, 'Vui lòng nhập số hợp lệ.');
      return;
    }
    // Chỉ số mới không được nhỏ hơn chỉ số cũ.
    if (chiSoDienMoi < chiSoPhong.oldElectric ||
        chiSoNuocMoi < chiSoPhong.oldWater) {
      showLandlordMessage(context, 'Chỉ số mới không được nhỏ hơn chỉ số cũ.');
      return;
    }

    setState(() {
      chiSoPhong.newElectric = chiSoDienMoi;
      chiSoPhong.newWater = chiSoNuocMoi;
    });
    showLandlordMessage(context, 'Đã lưu chỉ số phòng ${chiSoPhong.room}.');
  }
}
