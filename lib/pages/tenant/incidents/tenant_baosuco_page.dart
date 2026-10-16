import 'package:flutter/material.dart';

import '../../landlord/incidents/models/landlord_suco.dart';
import '../../landlord/landlord_demo_store.dart';
import '../../shared/rental/tenant_session.dart';
import '../tenant_ui.dart';

// Tên Class chính bằng tiếng Việt
class TenantBaoSuCoPage extends StatefulWidget {
  const TenantBaoSuCoPage({
    super.key,
    this.store,
    this.tenantId = TenantSession.tenantId,
  });

  final LandlordDemoStore? store;
  final String tenantId;

  @override
  State<TenantBaoSuCoPage> createState() => _TenantBaoSuCoPageState();
}

class _TenantBaoSuCoPageState extends State<TenantBaoSuCoPage> {
  // 1. DỮ KIỆN (Biến dữ liệu đưa lên đầu)
  static const _danhMucSuCo = ['Điện', 'Nước', 'Điện lạnh', 'Internet', 'Khác'];

  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;
  List<LandlordIncident> get _danhSachSuCo =>
      _store.incidentsForTenant(widget.tenantId);

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
  // Hàm cập nhật trạng thái sự cố và hiển thị thông báo
  void _capNhatTrangThai(LandlordIncident suCo, IncidentStatus trangThaiMoi) {
    _store.updateIncident(suCo, trangThaiMoi, tenantId: widget.tenantId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật: ${trangThaiMoi.label}')),
    );
  }

  // Hàm tạo danh sách loại sự cố cho Dropdown bằng LINQ gọn gàng
  List<DropdownMenuItem<String>> _taoDanhSachMucSuCo() {
    return _danhMucSuCo
        .map((muc) => DropdownMenuItem(value: muc, child: Text(muc)))
        .toList();
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
                items: _taoDanhSachMucSuCo(),
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

    try {
      _store.createIncident(
        tenantId: widget.tenantId,
        title: tieuDe,
        category: loaiSuCo,
        description: moTa,
      );
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi yêu cầu cho chủ trọ.')),
    );
  }

  // 4. HÀM BUILD ĐẶT Ở DƯỚI CÙNG
  @override
  Widget build(BuildContext context) {
    String tieuDePhu = 'Gửi yêu cầu sửa chữa cho chủ trọ.';
    final hopDong = _store.currentLeaseForTenant(widget.tenantId);
    if (hopDong != null) {
      tieuDePhu = 'Gửi yêu cầu sửa chữa cho chủ trọ phòng ${hopDong.room}.';
    }

    VoidCallback? hamTaoMoi;
    if (hopDong != null) {
      hamTaoMoi = _moFormTaoMoi;
    }

    // Danh sách widget hiển thị trên toàn màn hình
    final List<Widget> danhSachWidget = [
      TenantPageTitle(
        title: 'Báo sự cố',
        subtitle: tieuDePhu,
      ),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: hamTaoMoi,
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
      // Duyệt qua từng sự cố để tạo thẻ hiển thị bằng vòng lặp for đơn giản
      for (int i = 0; i < _danhSachSuCo.length; i++) {
        final suCo = _danhSachSuCo[i];

        // Nếu sự cố đã được chủ trọ xử lý thì hiển thị 2 nút: Mở lại hoặc Xác nhận
        Widget? dongNutThaoTac;
        if (suCo.status == IncidentStatus.resolved) {
          dongNutThaoTac = Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _capNhatTrangThai(suCo, IncidentStatus.newly);
                  },
                  child: const Text('Mở lại'),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () {
                    _capNhatTrangThai(suCo, IncidentStatus.closed);
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
                suCo.status.label,
                color: suCo.status.color,
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
}

