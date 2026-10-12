import 'package:flutter/material.dart';

import '../landlord_ui.dart';

// Lớp đại diện cho thông tin một người thuê phòng
class LandlordTenant {
  LandlordTenant({
    required this.name,
    required this.phone,
    required this.room,
    required this.moveIn,
    this.isRepresentative = false,
    this.pending = false,
  });

  final String name; // Tên người thuê
  final String phone; // Số điện thoại
  final String room; // Số phòng
  final String moveIn; // Ngày vào ở
  final bool isRepresentative; // Là người đại diện hợp đồng

  /// true = yêu cầu thêm thành viên đang chờ chủ trọ duyệt.
  bool pending;
}

class LandlordMembersPage extends StatefulWidget {
  const LandlordMembersPage({super.key});

  @override
  State<LandlordMembersPage> createState() => _LandlordMembersPageState();
}

class _LandlordMembersPageState extends State<LandlordMembersPage> {
  // Từ khóa tìm kiếm người thuê
  String _tuKhoaTimKiem = '';

  // Danh sách mẫu người thuê trọ
  final List<LandlordTenant> _danhSachNguoiThue = [
    LandlordTenant(
      name: 'Minh Anh',
      phone: '0901 234 567',
      room: 'A.302',
      moveIn: '01/03/2026',
      isRepresentative: true,
    ),
    LandlordTenant(
      name: 'Trần Thu Hà',
      phone: '0912 888 111',
      room: 'A.302',
      moveIn: '01/03/2026',
    ),
    LandlordTenant(
      name: 'Lê Văn Khoa',
      phone: '0987 654 321',
      room: 'A.101',
      moveIn: '15/05/2026',
      isRepresentative: true,
    ),
    LandlordTenant(
      name: 'Phạm Quốc Bảo',
      phone: '0933 222 444',
      room: 'B.105',
      moveIn: '10/08/2026',
      isRepresentative: true,
    ),
    LandlordTenant(
      name: 'Võ Ngọc Lan',
      phone: '0977 111 999',
      room: 'B.105',
      moveIn: '15/10/2026',
      pending: true,
    ),
  ];

  // Hàm xử lý từ chối yêu cầu thành viên mới
  void _tuChoiThanhVien(LandlordTenant nguoiThue) {
    setState(() {
      _danhSachNguoiThue.remove(nguoiThue);
    });
    showLandlordMessage(context, 'Đã từ chối ${nguoiThue.name}.');
  }

  // Hàm xử lý duyệt thành viên mới vào phòng
  void _duyetThanhVien(LandlordTenant nguoiThue) {
    setState(() {
      nguoiThue.pending = false;
    });
    showLandlordMessage(context, 'Đã duyệt ${nguoiThue.name}.');
  }

  @override
  Widget build(BuildContext context) {
    // Tách riêng danh sách chờ duyệt và danh sách đang ở
    final List<LandlordTenant> danhSachChoDuyet = [];
    final List<LandlordTenant> danhSachDangO = [];
    final tuKhoaThuong = _tuKhoaTimKiem.toLowerCase();

    // Dùng vòng lặp for đơn giản để phân loại và lọc tìm kiếm
    for (int i = 0; i < _danhSachNguoiThue.length; i++) {
      final nguoiThue = _danhSachNguoiThue[i];
      if (nguoiThue.pending) {
        danhSachChoDuyet.add(nguoiThue);
      } else {
        if (tuKhoaThuong.isEmpty) {
          danhSachDangO.add(nguoiThue);
        } else if (nguoiThue.name.toLowerCase().contains(tuKhoaThuong) ||
            nguoiThue.room.toLowerCase().contains(tuKhoaThuong)) {
          danhSachDangO.add(nguoiThue);
        }
      }
    }

    // Danh sách các widget hiển thị trên màn hình
    final List<Widget> danhSachWidget = [];

    // Tiêu đề trang
    danhSachWidget.add(
      LandlordPageTitle(
        title: 'Người thuê',
        subtitle: '${danhSachDangO.length} người đang ở · ${danhSachChoDuyet.length} chờ duyệt',
      ),
    );

    // Phần danh sách chờ duyệt nếu có
    if (danhSachChoDuyet.isNotEmpty) {
      danhSachWidget.add(
        const Text(
          'Chờ duyệt thành viên',
          style: TextStyle(
            color: landlordInk,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      danhSachWidget.add(const SizedBox(height: 8));
      for (int i = 0; i < danhSachChoDuyet.length; i++) {
        danhSachWidget.add(_taoTheChoDuyet(danhSachChoDuyet[i]));
      }
      danhSachWidget.add(const SizedBox(height: 10));
    }

    // Ô tìm kiếm người thuê
    danhSachWidget.add(
      TextField(
        decoration: const InputDecoration(
          hintText: 'Tìm theo tên hoặc phòng',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (giaTri) {
          setState(() {
            _tuKhoaTimKiem = giaTri;
          });
        },
      ),
    );
    danhSachWidget.add(const SizedBox(height: 12));

    // Hiển thị danh sách người thuê đang ở hoặc thông báo trống
    if (danhSachDangO.isEmpty) {
      danhSachWidget.add(
        const LandlordEmptyState(message: 'Không tìm thấy người thuê.'),
      );
    } else {
      for (int i = 0; i < danhSachDangO.length; i++) {
        danhSachWidget.add(_taoTheNguoiThue(danhSachDangO[i]));
      }
    }

    return LandlordPageFrame(
      children: danhSachWidget,
    );
  }

  // Tạo thẻ hiển thị thông tin người thuê đang ở
  Widget _taoTheNguoiThue(LandlordTenant nguoiThue) {
    Widget? nhanDaiDien;
    if (nguoiThue.isRepresentative) {
      nhanDaiDien = const LandlordStatusPill('Đại diện', color: landlordBlue);
    }

    return LandlordCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: landlordBlue.withValues(alpha: 0.1),
          child: Text(
            nguoiThue.name[0],
            style: const TextStyle(
              color: landlordBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          nguoiThue.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Phòng ${nguoiThue.room} · ${nguoiThue.phone}\nVào ở: ${nguoiThue.moveIn}',
        ),
        isThreeLine: true,
        trailing: nhanDaiDien,
      ),
    );
  }

  // Tạo thẻ cho người thuê đang chờ duyệt
  Widget _taoTheChoDuyet(LandlordTenant nguoiThue) {
    return LandlordCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nguoiThue.name,
            style: const TextStyle(
              color: landlordInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Xin vào phòng ${nguoiThue.room} · dự kiến ${nguoiThue.moveIn}',
            style: const TextStyle(color: landlordMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  _tuChoiThanhVien(nguoiThue);
                },
                child: const Text('Từ chối'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  _duyetThanhVien(nguoiThue);
                },
                child: const Text('Duyệt'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
