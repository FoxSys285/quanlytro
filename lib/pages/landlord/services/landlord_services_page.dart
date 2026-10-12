import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import 'models/landlord_service.dart';

class LandlordServicesPage extends StatefulWidget {
  const LandlordServicesPage({super.key});

  @override
  State<LandlordServicesPage> createState() => _LandlordServicesPageState();
}

class _LandlordServicesPageState extends State<LandlordServicesPage> {
  // Các hình thức tính phí dịch vụ
  static const _danhSachCachTinh = [
    'Theo chỉ số',
    'Theo phòng',
    'Theo người',
    'Cố định',
  ];

  // Danh sách các dịch vụ đang được áp dụng
  final _danhSachDichVu = <LandlordService>[
    LandlordService(
      name: 'Điện',
      unit: 'kWh',
      basis: 'Theo chỉ số',
      price: 3500,
    ),
    LandlordService(name: 'Nước', unit: 'm³', basis: 'Theo chỉ số', price: 15000),
    LandlordService(
      name: 'Internet',
      unit: 'phòng',
      basis: 'Theo phòng',
      price: 100000,
    ),
    LandlordService(
      name: 'Gửi xe máy',
      unit: 'xe',
      basis: 'Cố định',
      price: 80000,
    ),
    LandlordService(
      name: 'Vệ sinh',
      unit: 'người',
      basis: 'Theo người',
      price: 20000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Danh sách widget hiển thị trên trang
    final List<Widget> danhSachWidget = [
      LandlordPageTitle(
        title: 'Dịch vụ và bảng giá',
        subtitle: 'Đơn giá áp dụng khi lập hóa đơn hằng tháng.',
        trailing: FilledButton.icon(
          onPressed: () {
            _moFormDichVu();
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Thêm'),
        ),
      ),
    ];

    // Kiểm tra nếu chưa có dịch vụ nào
    if (_danhSachDichVu.isEmpty) {
      danhSachWidget.add(
        const LandlordEmptyState(message: 'Chưa có dịch vụ nào.'),
      );
    } else {
      // Duyệt qua từng dịch vụ để tạo thẻ hiển thị
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
                    setState(() {
                      dichVu.active = giaTriKichHoat;
                    });
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

  // Hàm mở form thêm mới hoặc chỉnh sửa dịch vụ
  Future<void> _moFormDichVu({LandlordService? dichVuCanSua}) async {
    String tenBanDau = '';
    String donViBanDau = '';
    String giaBanDau = '';
    String cachTinh = _danhSachCachTinh.first;

    // Nếu là chế độ sửa thì gán dữ liệu hiện có
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
              children: [
                TextField(
                  controller: oNhapTen,
                  decoration: const InputDecoration(labelText: 'Tên dịch vụ'),
                ),
                TextField(
                  controller: oNhapDonVi,
                  decoration: const InputDecoration(
                    labelText: 'Đơn vị (kWh, m³, phòng...)',
                  ),
                ),
                TextField(
                  controller: oNhapDonGia,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Đơn giá (đ)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: cachTinh,
                  decoration: const InputDecoration(labelText: 'Cách tính'),
                  items: [
                    for (final cach in _danhSachCachTinh)
                      DropdownMenuItem(value: cach, child: Text(cach)),
                  ],
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
            // Nút xóa nếu đang chỉnh sửa dịch vụ có sẵn
            if (dichVuCanSua != null)
              TextButton(
                onPressed: () {
                  setState(() => _danhSachDichVu.remove(dichVuCanSua));
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

    // Kiểm tra nếu người dùng không bấm lưu hoặc màn hình đã đóng
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

    // Cập nhật vào danh sách
    setState(() {
      if (dichVuCanSua == null) {
        _danhSachDichVu.add(
          LandlordService(
            name: tenDichVu,
            unit: donVi,
            basis: cachTinh,
            price: donGia,
          ),
        );
      } else {
        dichVuCanSua.name = tenDichVu;
        dichVuCanSua.unit = donVi;
        dichVuCanSua.basis = cachTinh;
        dichVuCanSua.price = donGia;
      }
    });
    showLandlordMessage(context, 'Đã lưu dịch vụ $tenDichVu.');
  }
}
