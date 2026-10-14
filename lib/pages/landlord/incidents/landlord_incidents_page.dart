import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import 'models/landlord_incident.dart';

class LandlordIncidentsPage extends StatefulWidget {
  const LandlordIncidentsPage({super.key});

  @override
  State<LandlordIncidentsPage> createState() => _LandlordIncidentsPageState();
}

class _LandlordIncidentsPageState extends State<LandlordIncidentsPage> {
  // Bộ lọc trạng thái đang chọn (null là hiển thị tất cả)
  IncidentStatus? _boLocTrangThai;

  // Danh sách mẫu các sự cố / yêu cầu sửa chữa từ người thuê
  final List<LandlordIncident> _danhSachSuCo = [
    LandlordIncident(
      title: 'Máy lạnh không lạnh',
      room: 'A.302',
      reporter: 'Minh Anh',
      category: 'Điện lạnh',
      description: 'Máy lạnh chạy nhưng không ra hơi lạnh từ tối qua.',
      date: '04/10/2026',
      urgent: true,
    ),
    LandlordIncident(
      title: 'Vòi nước rò rỉ',
      room: 'A.101',
      reporter: 'Lê Văn Khoa',
      category: 'Nước',
      description: 'Vòi trong nhà vệ sinh bị rỉ nước liên tục.',
      date: '02/10/2026',
      status: IncidentStatus.inProgress,
    ),
    LandlordIncident(
      title: 'Bóng đèn hành lang hỏng',
      room: 'B.105',
      reporter: 'Phạm Quốc Bảo',
      category: 'Điện',
      description: 'Bóng đèn trước cửa phòng không sáng.',
      date: '28/09/2026',
      status: IncidentStatus.resolved,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách sự cố theo trạng thái được chọn bằng vòng lặp for đơn giản
    final List<LandlordIncident> danhSachHienThi = [];
    if (_boLocTrangThai == null) {
      danhSachHienThi.addAll(_danhSachSuCo);
    } else {
      for (int i = 0; i < _danhSachSuCo.length; i++) {
        if (_danhSachSuCo[i].status == _boLocTrangThai) {
          danhSachHienThi.add(_danhSachSuCo[i]);
        }
      }
    }

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

  // Hàm tạo danh sách chip lọc trạng thái bằng vòng lặp for cơ bản
  List<Widget> _taoDanhSachChipLoc() {
    final List<Widget> danhSachChip = [];
    danhSachChip.add(_taoChipLoc('Tất cả', null));
    for (int i = 0; i < IncidentStatus.values.length; i++) {
      final trangThai = IncidentStatus.values[i];
      danhSachChip.add(_taoChipLoc(trangThai.label, trangThai));
    }
    return danhSachChip;
  }

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

  // Hàm mở bảng chi tiết sự cố và cho phép chủ trọ chuyển đổi trạng thái
  void _moChiTietSuCo(LandlordIncident suCo) {
    // Tạo danh sách các chip chọn trạng thái bằng vòng lặp for cơ bản
    final List<Widget> danhSachNutChonTrangThai = [];
    for (int i = 0; i < IncidentStatus.values.length; i++) {
      final trangThai = IncidentStatus.values[i];
      danhSachNutChonTrangThai.add(
        ChoiceChip(
          label: Text(trangThai.label),
          selected: suCo.status == trangThai,
          onSelected: (_) {
            setState(() {
              suCo.status = trangThai;
            });
            Navigator.pop(context);
            showLandlordMessage(
              context,
              'Đã chuyển "${suCo.title}" sang ${trangThai.label}.',
            );
          },
        ),
      );
    }

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
}
