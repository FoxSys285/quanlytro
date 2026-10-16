import 'package:flutter/material.dart';

import '../landlord_demo_store.dart';
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

  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(nhan),
        selected: _boLocTrangThai == trangThai,
        onSelected: (_) {
          setState(() {
            _boLocTrangThai = trangThai;
          });
        },
      ),
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
    // Tạo danh sách các chip chọn trạng thái bằng LINQ map
    final danhSachNutChonTrangThai = IncidentStatus.values.map(
      (trangThai) => ChoiceChip(
        label: Text(trangThai.label),
        selected: suCo.status == trangThai,
        onSelected: (_) {
          _store.updateIncident(suCo, trangThai);
          Navigator.pop(context);
          showLandlordMessage(
            context,
            'Đã chuyển "${suCo.title}" sang ${trangThai.label}.',
          );
        },
      ),
    ).toList();


    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (nguCanhBang) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suCo.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('Phòng ${suCo.room} · ${suCo.category}'),
            Text('Người báo: ${suCo.reporter} · ${suCo.date}'),
            const SizedBox(height: 10),
            Text(suCo.description),
            const SizedBox(height: 16),
            const Text(
              'Cập nhật trạng thái',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: danhSachNutChonTrangThai,
            ),
          ],
        ),
      ),
    );
  }

  // 4. HÀM BUILD ĐẶT Ở DƯỚI CÙNG
  @override
  Widget build(BuildContext context) {
    // Lọc danh sách sự cố theo trạng thái bằng LINQ gọn gàng
    final danhSachHienThi = _boLocTrangThai == null
        ? _danhSachSuCo
        : _danhSachSuCo.where((s) => s.status == _boLocTrangThai).toList();


    // Danh sách widget hiển thị trên toàn trang
    final List<Widget> danhSachWidget = [
      const LandlordPageTitle(
        title: 'Yêu cầu sửa chữa',
        subtitle: 'Tiếp nhận và cập nhật tiến độ sự cố của người thuê.',
      ),
      // Thanh chip lọc trạng thái sự cố nằm ngang
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _taoDanhSachChipLoc(),
        ),
      ),
      const SizedBox(height: 12),
    ];

    // Kiểm tra danh sách rỗng
    if (danhSachHienThi.isEmpty) {
      danhSachWidget.add(
        const LandlordEmptyState(message: 'Không có yêu cầu nào.'),
      );
    } else {
      for (int i = 0; i < danhSachHienThi.length; i++) {
        final suCo = danhSachHienThi[i];

        // Huy hiệu khẩn cấp nếu sự cố được đánh dấu gấp
        Widget? huyHieuKhanCap;
        if (suCo.urgent) {
          huyHieuKhanCap = const Padding(
            padding: EdgeInsets.only(top: 6),
            child: LandlordStatusPill('Khẩn cấp', color: Colors.red),
          );
        }

        // Nội dung chi tiết trong thẻ sự cố
        final List<Widget> noiDungTheSuCo = [
          Row(
            children: [
              Expanded(
                child: Text(
                  suCo.title,
                  style: const TextStyle(
                    color: landlordInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              LandlordStatusPill(
                suCo.status.label,
                color: suCo.status.color,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Phòng ${suCo.room} · ${suCo.reporter} · ${suCo.date}',
            style: const TextStyle(color: landlordMuted, fontSize: 12),
          ),
        ];

        if (huyHieuKhanCap != null) {
          noiDungTheSuCo.add(huyHieuKhanCap);
        }

        // Thêm thẻ sự cố vào danh sách giao diện
        danhSachWidget.add(
          LandlordCard(
            onTap: () {
              _moChiTietSuCo(suCo);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: noiDungTheSuCo,
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

