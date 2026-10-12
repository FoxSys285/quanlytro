import 'package:flutter/material.dart';

import '../tenant_ui.dart';

class TenantIncident {
  TenantIncident({
    required this.title,
    required this.category,
    required this.description,
    required this.date,
    this.status = 'Mới gửi',
  });

  final String title;
  final String category;
  final String description;
  final String date;

  /// Mới gửi / Đang xử lý / Đã xử lý / Đã xác nhận.
  String status;
}

class TenantIncidentsPage extends StatefulWidget {
  const TenantIncidentsPage({super.key});

  @override
  State<TenantIncidentsPage> createState() => _TenantIncidentsPageState();
}

class _TenantIncidentsPageState extends State<TenantIncidentsPage> {
  // Danh sách các loại sự cố phổ biến
  static const _danhMucSuCo = ['Điện', 'Nước', 'Điện lạnh', 'Internet', 'Khác'];

  // Danh sách các sự cố của người thuê phòng hiện tại
  final _danhSachSuCo = <TenantIncident>[
    TenantIncident(
      title: 'Máy lạnh không lạnh',
      category: 'Điện lạnh',
      description: 'Máy lạnh chạy nhưng không ra hơi lạnh từ tối qua.',
      date: '04/10/2026',
    ),
    TenantIncident(
      title: 'Bóng đèn nhà tắm hỏng',
      category: 'Điện',
      description: 'Bóng đèn không sáng.',
      date: '20/09/2026',
      status: 'Đã xử lý',
    ),
  ];

  // Hàm xác định màu sắc hiển thị theo trạng thái sự cố
  Color _layMauTrangThai(String trangThai) {
    if (trangThai == 'Mới gửi') {
      return const Color(0xFFD64545);
    } else if (trangThai == 'Đang xử lý') {
      return const Color(0xFFE08A1E);
    } else if (trangThai == 'Đã xử lý') {
      return tenantGreen;
    } else {
      return tenantMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách widget hiển thị trên toàn màn hình
    final List<Widget> danhSachWidget = [
      const TenantPageTitle(
        title: 'Báo sự cố',
        subtitle: 'Gửi yêu cầu sửa chữa cho chủ trọ phòng A.302.',
      ),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _moFormTaoMoi,
          style: FilledButton.styleFrom(backgroundColor: tenantGreen),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tạo yêu cầu mới'),
        ),
      ),
      const SizedBox(height: 18),
      const TenantSectionHeading('Yêu cầu của tôi'),
    ];

    // Kiểm tra nếu chưa có sự cố nào thì hiển thị giao diện trống
    if (_danhSachSuCo.isEmpty) {
      danhSachWidget.add(
        const TenantEmptyState(
          icon: Icons.build_outlined,
          title: 'Chưa có sự cố nào',
          subtitle: 'Khi phòng có vấn đề, hãy gửi yêu cầu cho chủ trọ.',
        ),
      );
    } else {
      // Duyệt qua từng sự cố để tạo thẻ hiển thị
      for (int i = 0; i < _danhSachSuCo.length; i++) {
        final suCo = _danhSachSuCo[i];

        // Nếu sự cố đã xử lý thì hiển thị thêm nút bấm xác nhận hoặc mở lại
        Widget? dongNutThaoTac;
        if (suCo.status == 'Đã xử lý') {
          dongNutThaoTac = Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _capNhatTrangThai(suCo, 'Mới gửi');
                  },
                  child: const Text('Mở lại'),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () {
                    _capNhatTrangThai(suCo, 'Đã xác nhận');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: tenantGreen,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ],
            ),
          );
        }

        // Tạo danh sách widget con bên trong thẻ sự cố
        final List<Widget> danhSachPhanTuThe = [
          Row(
            children: [
              Expanded(
                child: Text(
                  suCo.title,
                  style: const TextStyle(
                    color: tenantInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TenantStatusPill(
                suCo.status,
                color: _layMauTrangThai(suCo.status),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${suCo.category} · ${suCo.date}',
            style: const TextStyle(color: tenantMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            suCo.description,
            style: const TextStyle(color: tenantInk, fontSize: 13),
          ),
        ];

        // Thêm nút thao tác nếu có
        if (dongNutThaoTac != null) {
          danhSachPhanTuThe.add(dongNutThaoTac);
        }

        danhSachWidget.add(
          TenantSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: danhSachPhanTuThe,
            ),
          ),
        );
        danhSachWidget.add(const SizedBox(height: 10));
      }
    }

    return TenantPageFrame(
      children: danhSachWidget,
    );
  }

  // Hàm cập nhật trạng thái sự cố và hiển thị thông báo
  void _capNhatTrangThai(TenantIncident suCo, String trangThaiMoi) {
    setState(() {
      suCo.status = trangThaiMoi;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật: $trangThaiMoi')),
    );
  }

  // Hàm mở form tạo yêu cầu sửa chữa mới
  Future<void> _moFormTaoMoi() async {
    final oNhapTieuDe = TextEditingController();
    final oNhapMoTa = TextEditingController();
    var loaiSuCo = _danhMucSuCo.first;

    final ketQuaLuu = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => TenantBottomSheetSurface(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TenantSheetHandle(),
              const Text(
                'Tạo yêu cầu sửa chữa',
                style: TextStyle(
                  color: tenantInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: oNhapTieuDe,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: loaiSuCo,
                decoration: const InputDecoration(
                  labelText: 'Loại sự cố',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final muc in _danhMucSuCo)
                    DropdownMenuItem(value: muc, child: Text(muc)),
                ],
                onChanged: (giaTri) {
                  setSheetState(() {
                    if (giaTri != null) {
                      loaiSuCo = giaTri;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: oNhapMoTa,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(backgroundColor: tenantGreen),
                  child: const Text('Gửi yêu cầu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Kiểm tra nếu người dùng không bấm lưu hoặc màn hình đã đóng
    if (ketQuaLuu != true) {
      return;
    }
    if (!mounted) {
      return;
    }

    final tieuDe = oNhapTieuDe.text.trim();
    final moTa = oNhapMoTa.text.trim();
    if (tieuDe.isEmpty || moTa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề và mô tả.')),
      );
      return;
    }

    // Lấy ngày hiện tại và thêm vào đầu danh sách
    final thoiGianHienTai = DateTime.now();
    setState(() {
      _danhSachSuCo.insert(
        0,
        TenantIncident(
          title: tieuDe,
          category: loaiSuCo,
          description: moTa,
          date:
              '${thoiGianHienTai.day}/${thoiGianHienTai.month}/${thoiGianHienTai.year}',
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi yêu cầu cho chủ trọ.')),
    );
  }
}
