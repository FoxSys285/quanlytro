import 'package:flutter/material.dart';

import '../../../data/app_persistence.dart';
import '../landlord_theme.dart';

import '../landlord_glass.dart';
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
  final _store = LandlordDemoStore.activeInstance;

  static const _danhSachCachTinh = [
    'Theo chỉ số',
    'Theo phòng',
    'Theo người',
    'Theo cái / xe',
    'Cố định',
  ];

  // Danh mục mẫu dịch vụ chuẩn bị sẵn để chọn nhanh khi tạo mới
  static const _mauDichVu = [
    {
      'name': 'Internet',
      'unit': 'phòng',
      'price': '100000',
      'basis': 'Theo phòng',
    },
    {
      'name': 'Gửi xe máy',
      'unit': 'cái',
      'price': '80000',
      'basis': 'Theo cái / xe',
    },
    {
      'name': 'Vệ sinh',
      'unit': 'người',
      'price': '20000',
      'basis': 'Theo người',
    },
  ];

  bool _isUtilityRate(LandlordService service) =>
      service.id == 'electricity' || service.id == 'water';

  List<LandlordService> get _danhSachTienIch =>
      _store.services.where(_isUtilityRate).toList()..sort((a, b) {
        if (a.id == b.id) return 0;
        return a.id == 'electricity' ? -1 : 1;
      });

  List<LandlordService> get _danhSachDichVu =>
      _store.services.where((service) => !_isUtilityRate(service)).toList();

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

  Future<void> _moFormGiaTienIch(LandlordService service) async {
    final isElectricity = service.id == 'electricity';
    final priceController = TextEditingController(text: '${service.price}');
    var unit = service.unit.toLowerCase().contains('người') ? 'người' : 'm³';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => LandlordFormDialog(
          title: isElectricity ? 'Bảng giá tiền điện' : 'Bảng giá tiền nước',
          subtitle: isElectricity
              ? 'Cập nhật đơn giá điện áp dụng cho kWh tiêu thụ.'
              : 'Cập nhật đơn giá và cách tính tiền nước.',
          icon: isElectricity ? Icons.bolt_outlined : Icons.water_drop_outlined,
          footer: Row(
            children: [
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 7),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: landlordBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.save_outlined, size: 17),
                label: const Text('Lưu'),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: landlordModernInputDecoration(
                  isElectricity
                      ? 'Đơn giá tiền điện (đ/kWh)'
                      : 'Đơn giá tiền nước (đ)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
              if (!isElectricity) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey(unit),
                  initialValue: unit,
                  isExpanded: true,
                  decoration: landlordModernInputDecoration('Đơn vị tính'),
                  items: const [
                    DropdownMenuItem(value: 'm³', child: Text('m³')),
                    DropdownMenuItem(value: 'người', child: Text('người')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => unit = value);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
    final price = int.tryParse(priceController.text.trim());
    priceController.dispose();
    if (saved != true || !mounted) return;
    if (price == null || price < 0) {
      showLandlordMessage(context, 'Vui lòng nhập đơn giá hợp lệ.');
      return;
    }
    _store.saveService(
      existing: service,
      name: service.name,
      unit: isElectricity ? service.unit : unit,
      basis: isElectricity || unit == 'm³' ? 'Theo chỉ số' : 'Theo người',
      price: price,
    );
    try {
      await AppPersistence.current?.flush();
    } catch (failure) {
      if (!mounted) return;
      showLandlordMessage(context, AppPersistence.saveFailureMessage(failure));
      return;
    }
    if (mounted) {
      showLandlordMessage(
        context,
        'Đã cập nhật ${isElectricity ? 'tiền điện' : 'tiền nước'}.',
      );
    }
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
        builder: (context, setDialogState) => LandlordFormDialog(
          title: tieuDeHopThoai,
          subtitle: 'Thiết lập đơn giá và cách tính dịch vụ.',
          icon: Icons.price_change_outlined,
          footer: Row(
            children: [
              if (dichVuCanSua != null)
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      _store.deleteService(dichVuCanSua);
                      Navigator.pop(context, false);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD64545),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Xóa'),
                  ),
                )
              else
                const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 7),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: landlordBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.save_outlined, size: 17),
                label: const Text('Lưu'),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gợi ý chọn mẫu nhanh khi tạo dịch vụ mới
              if (dichVuCanSua == null) ...[
                Text(
                  'Chọn mẫu nhanh:',
                  style: TextStyle(
                    color: LandlordPalette.of(context).muted,
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
                decoration: landlordModernInputDecoration('Tên dịch vụ'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: oNhapDonVi,
                decoration: landlordModernInputDecoration(
                  'Đơn vị',
                  hintText: 'kWh, m³, cái, phòng...',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: oNhapDonGia,
                keyboardType: TextInputType.number,
                decoration: landlordModernInputDecoration(
                  'Đơn giá (đ)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: ValueKey(cachTinh),
                initialValue: _danhSachCachTinh.contains(cachTinh)
                    ? cachTinh
                    : _danhSachCachTinh.first,

                isExpanded: true,
                decoration: landlordModernInputDecoration('Cách tính'),
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
      ),
    );

    final tenDichVu = oNhapTen.text.trim();
    final donVi = oNhapDonVi.text.trim();
    final donGia = int.tryParse(oNhapDonGia.text.trim());
    oNhapTen.dispose();
    oNhapDonVi.dispose();
    oNhapDonGia.dispose();
    if (daLuu != true || !mounted) return;
    if (tenDichVu.isEmpty || donVi.isEmpty || donGia == null || donGia < 0) {
      showLandlordMessage(context, 'Vui lòng nhập đầy đủ và đúng đơn giá.');
      return;
    }

    try {
      _store.saveService(
        existing: dichVuCanSua,
        name: tenDichVu,
        unit: donVi,
        basis: cachTinh,
        price: donGia,
      );
    } on ArgumentError catch (failure) {
      showLandlordMessage(context, failure.message.toString());
      return;
    }
    try {
      await AppPersistence.current?.flush();
    } catch (failure) {
      if (!mounted) return;
      showLandlordMessage(context, AppPersistence.saveFailureMessage(failure));
      return;
    }
    if (!mounted) return;
    showLandlordMessage(context, 'Đã lưu dịch vụ $tenDichVu.');
  }

  // 4. HÀM BUILD ĐẶT Ở DƯỚI CÙNG
  @override
  Widget build(BuildContext context) {
    return LandlordFeaturePage(
      title: 'Dịch vụ & Bảng giá',
      subtitle: 'Cấu hình đơn giá điện, nước và dịch vụ của nhà trọ.',
      icon: Icons.price_change_outlined,
      children: [
        LandlordGlassSection(
          title: 'Bảng giá điện nước',
          subtitle: 'Hai khoản phí cơ bản luôn có sẵn và không thể xóa.',
        ),
        for (final dichVu in _danhSachTienIch)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LandlordGlassCard(
              onTap: () => _moFormGiaTienIch(dichVu),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4EFFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
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
                          dichVu.id == 'electricity'
                              ? 'Tiền điện'
                              : 'Tiền nước',
                          style: TextStyle(
                            color: LandlordPalette.of(context).ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatLandlordMoney(dichVu.price)} / ${dichVu.unit} · ${dichVu.basis}',
                          style: TextStyle(
                            color: LandlordPalette.of(context).muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip:
                        'Chỉnh sửa ${dichVu.id == 'electricity' ? 'tiền điện' : 'tiền nước'}',
                    onPressed: () => _moFormGiaTienIch(dichVu),
                    icon: const Icon(Icons.edit_outlined),
                    color: landlordBlue,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        LandlordGlassSection(
          title: 'Dịch vụ khác',
          subtitle: '${_danhSachDichVu.length} dịch vụ đang được quản lý.',
          trailing: FilledButton.icon(
            onPressed: () => _moFormDichVu(),
            style: FilledButton.styleFrom(
              backgroundColor: landlordBlue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Thêm dịch vụ'),
          ),
        ),
        if (_danhSachDichVu.isEmpty)
          const LandlordGlassCard(
            child: Center(child: Text('Chưa có dịch vụ khác.')),
          ),
        for (final dichVu in _danhSachDichVu)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LandlordGlassCard(
              onTap: () => _moFormDichVu(dichVuCanSua: dichVu),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4EFFF),
                      borderRadius: BorderRadius.circular(15),
                    ),
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
                          style: TextStyle(
                            color: LandlordPalette.of(context).ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatLandlordMoney(dichVu.price)} / ${dichVu.unit} · ${dichVu.basis}',
                          style: TextStyle(
                            color: LandlordPalette.of(context).muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: dichVu.active,
                    activeThumbColor: landlordBlue,
                    onChanged: (giaTriKichHoat) {
                      _store.setServiceActive(dichVu, giaTriKichHoat);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
