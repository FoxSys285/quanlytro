import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import 'models/landlord_dichvu.dart';

// Tên Class chính bằng tiếng Việt
class LandlordDichVuBangGiaPage extends StatefulWidget {
  const LandlordDichVuBangGiaPage({super.key});

  @override
  State<LandlordDichVuBangGiaPage> createState() =>
      _LandlordDichVuBangGiaPageState();
}

class _LandlordDichVuBangGiaPageState extends State<LandlordDichVuBangGiaPage> {
  // 1. DỮ KIỆN (Kho lưu trữ và biến trạng thái đưa lên đầu)
  final _store = LandlordDemoStore.instance;

  static const _danhSachCachTinh = [
    'Theo chỉ số',
    'Theo phòng',
    'Theo người',
    'Theo cái / xe',
    'Cố định',
  ];

  // Danh mục mẫu dịch vụ chuẩn bị sẵn để chọn nhanh khi tạo mới
  static const _mauDichVu = [
    {'name': 'Điện', 'unit': 'kWh', 'price': '4000', 'basis': 'Theo chỉ số'},
    {'name': 'Nước', 'unit': 'm³', 'price': '15000', 'basis': 'Theo chỉ số'},
    {'name': 'Internet', 'unit': 'phòng', 'price': '100000', 'basis': 'Theo phòng'},
    {'name': 'Gửi xe máy', 'unit': 'cái', 'price': '80000', 'basis': 'Theo cái / xe'},
    {'name': 'Vệ sinh', 'unit': 'người', 'price': '20000', 'basis': 'Theo người'},
  ];

  List<LandlordService> get _danhSachDichVu => _store.services;

  // 2. VÒNG ĐỜI VÀ LẮNG NGHE DỮ LIỆU
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
  // Hàm chọn icon tương ứng với tên dịch vụ
  IconData _layIconDichVu(String tenDichVu) {
    final tenVietThuong = tenDichVu.toLowerCase();
    if (tenVietThuong.contains('điện')) {
      return Icons.bolt_outlined;
    } else if (tenVietThuong.contains('nước')) {
      return Icons.water_drop_outlined;
    } else if (tenVietThuong.contains('internet') ||
        tenVietThuong.contains('wifi')) {
      return Icons.wifi_rounded;
    } else if (tenVietThuong.contains('xe')) {
      return Icons.two_wheeler_outlined;
    } else {
      return Icons.room_service_outlined;
    }
  }

  // Hàm tạo danh sách lựa chọn cho Dropdown bằng LINQ gọn gàng
  List<DropdownMenuItem<String>> _taoDanhSachLuaChonCachTinh() {
    return _danhSachCachTinh
        .map((cach) => DropdownMenuItem(value: cach, child: Text(cach)))
        .toList();
  }

  // Hàm mở form thêm mới hoặc chỉnh sửa dịch vụ
  Future<void> _moFormDichVu({LandlordService? dichVuCanSua}) async {
    String tenBanDau = '';
    String donViBanDau = '';
    String giaBanDau = '';
    String cachTinh = _danhSachCachTinh.first;

    if (dichVuCanSua != null) {
      tenBanDau = dichVuCanSua.name;
      donViBanDau = dichVuCanSua.unit;
      giaBanDau = dichVuCanSua.price.toString();
      cachTinh = dichVuCanSua.basis;
    }

    final oNhapTen = TextEditingController(text: tenBanDau);
    final oNhapDonVi = TextEditingController(text: donViBanDau);
    final oNhapDonGia = TextEditingController(text: giaBanDau);

    String tieuDeHopThoai = 'Thêm dịch vụ';
    if (dichVuCanSua != null) {
      tieuDeHopThoai = 'Sửa dịch vụ';
    }

    final daLuu = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tieuDeHopThoai),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gợi ý chọn mẫu nhanh khi tạo dịch vụ mới
                if (dichVuCanSua == null) ...[
                  const Text(
                    'Chọn mẫu nhanh:',
                    style: TextStyle(
                      color: landlordMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _mauDichVu.map((mau) {
                        final daChon = oNhapTen.text == mau['name'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(mau['name']!),
                            selected: daChon,
                            onSelected: (_) {
                              setDialogState(() {
                                oNhapTen.text = mau['name']!;
                                oNhapDonVi.text = mau['unit']!;
                                oNhapDonGia.text = mau['price']!;
                                cachTinh = mau['basis']!;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: oNhapTen,
                  decoration: const InputDecoration(labelText: 'Tên dịch vụ'),
                ),
                TextField(
                  controller: oNhapDonVi,
                  decoration: const InputDecoration(
                    labelText: 'Đơn vị (kWh, m³, cái, phòng...)',
                  ),
                ),
                TextField(
                  controller: oNhapDonGia,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Đơn giá (đ)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey(cachTinh),
                  initialValue: _danhSachCachTinh.contains(cachTinh)
                      ? cachTinh
                      : _danhSachCachTinh.first,

                  decoration: const InputDecoration(labelText: 'Cách tính'),
                  items: _taoDanhSachLuaChonCachTinh(),
                  onChanged: (giaTri) {
                    setDialogState(() {
                      if (giaTri != null) {
                        cachTinh = giaTri;
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          actions: [
            if (dichVuCanSua != null)
              TextButton(
                onPressed: () {
                  _store.deleteService(dichVuCanSua);
                  Navigator.pop(context, false);
                },
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
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
      ),
    );

    if (daLuu != true) {
      return;
    }
    if (!mounted) {
      return;
    }

    final tenDichVu = oNhapTen.text.trim();
    final donVi = oNhapDonVi.text.trim();
    final donGia = int.tryParse(oNhapDonGia.text.trim());
    if (tenDichVu.isEmpty || donVi.isEmpty || donGia == null || donGia < 0) {
      showLandlordMessage(context, 'Vui lòng nhập đầy đủ và đúng đơn giá.');
      return;
    }

    _store.saveService(
      existing: dichVuCanSua,
      name: tenDichVu,
      unit: donVi,
      basis: cachTinh,
      price: donGia,
    );
    showLandlordMessage(context, 'Đã lưu dịch vụ $tenDichVu.');
  }

  // 4. HÀM BUILD ĐẶT Ở DƯỚI CÙNG
  @override
  Widget build(BuildContext context) {
    // Danh sách widget hiển thị trên trang
    final List<Widget> danhSachWidget = [
      const LandlordPageTitle(
        title: 'Dịch vụ & Bảng giá',
        subtitle: 'Cấu hình đơn giá điện, nước và các dịch vụ khác.',
      ),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            _moFormDichVu();
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm dịch vụ mới'),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Bảng giá hiện tại',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
    ];

    // Thêm các thẻ dịch vụ bằng vòng lặp for cơ bản
    if (_danhSachDichVu.isEmpty) {
      danhSachWidget.add(
        const LandlordEmptyState(message: 'Chưa có dịch vụ nào.'),
      );
    } else {
      for (int i = 0; i < _danhSachDichVu.length; i++) {
        final dichVu = _danhSachDichVu[i];
        danhSachWidget.add(
          LandlordCard(
            onTap: () {
              _moFormDichVu(dichVuCanSua: dichVu);
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: landlordBlue.withValues(alpha: 0.1),
                  child: Icon(
                    _layIconDichVu(dichVu.name),
                    color: landlordBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dichVu.name,
                        style: const TextStyle(
                          color: landlordInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${formatLandlordMoney(dichVu.price)} / ${dichVu.unit} · ${dichVu.basis}',
                        style: const TextStyle(
                          color: landlordMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: dichVu.active,
                  onChanged: (giaTriKichHoat) {
                    _store.setServiceActive(dichVu, giaTriKichHoat);
                  },
                ),
              ],
            ),
          ),
        );
      }
    }

    return LandlordPageFrame(
      children: danhSachWidget,
    );
  }
}
