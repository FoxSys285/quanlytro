import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import '../finance/landlord_finance_models.dart';
import '../../shared/rental/lease_member.dart';

// Tên Class chính bằng tiếng Việt
class LandlordNguoiThuePage extends StatefulWidget {
  const LandlordNguoiThuePage({super.key, this.store});

  final LandlordDemoStore? store;

  @override
  State<LandlordNguoiThuePage> createState() => _LandlordNguoiThuePageState();
}

class _LandlordNguoiThuePageState extends State<LandlordNguoiThuePage> {
  // 1. DỮ KIỆN (Biến trạng thái đưa lên đầu)
  String _tuKhoaTimKiem = '';

  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;

  // 2. CÁC HÀM XỬ LÝ (Viết trước hàm build)
  // Hàm xử lý duyệt hoặc từ chối thành viên
  Future<void> _xuLyYeuCau(LeaseMember thanhVien, bool dongY) async {
    String lyDo = '';
    if (!dongY) {
      final ketQua = await showDialog<String>(
        context: context,
        builder: (_) => _HopThoaiTuChoi(),
      );
      if (!mounted || ketQua == null) {
        return;
      }
      lyDo = ketQua;
    }

    try {
      _store.reviewMember(thanhVien, approve: dongY, reason: lyDo);
      String tenHanhDong;
      if (dongY) {
        tenHanhDong = 'duyệt';
      } else {
        tenHanhDong = 'từ chối';
      }
      showLandlordMessage(
        context,
        'Đã $tenHanhDong ${thanhVien.name}.',
      );
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }

  // 3. HÀM BUILD ĐẶT Ở DƯỚI CÙNG
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        // Phân loại thành viên đang ở và thành viên chờ duyệt bằng LINQ gọn gàng
        final currentMembers = _store.members.where((thanhVien) {
          final hopDong = _store.leaseById(thanhVien.leaseId);
          return hopDong != null && hopDong.isCurrent;
        });
        final danhSachChoDuyet = currentMembers
            .where((m) => m.status == LeaseMemberStatus.pending)
            .toList();
        final danhSachDangO = currentMembers
            .where((m) => m.status == LeaseMemberStatus.active)
            .toList();

        // Lọc danh sách người đang ở theo từ khóa tìm kiếm bằng LINQ
        final tuKhoa = _tuKhoaTimKiem.trim().toLowerCase();
        final danhSachLoc = danhSachDangO.where((thanhVien) {
          final hopDong = _store.leaseById(thanhVien.leaseId);
          final soPhong = hopDong?.room ?? '';
          final chuoiGop = '${thanhVien.name} $soPhong'.toLowerCase();
          return chuoiGop.contains(tuKhoa);
        }).toList();


        // Danh sách widget hiển thị trên màn hình
        final List<Widget> danhSachWidget = [
          LandlordPageTitle(
            title: 'Người thuê',
            subtitle:
                '${danhSachDangO.length} người đang ở · ${danhSachChoDuyet.length} chờ duyệt',
          ),
        ];

        // Nếu có yêu cầu chờ duyệt thì hiển thị phần duyệt ở trên đầu
        if (danhSachChoDuyet.isNotEmpty) {
          danhSachWidget.add(
            const Text(
              'Chờ duyệt thành viên',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          );
          danhSachWidget.add(const SizedBox(height: 8));

          for (int i = 0; i < danhSachChoDuyet.length; i++) {
            final thanhVien = danhSachChoDuyet[i];
            final hopDong = _store.leaseById(thanhVien.leaseId);
            String soPhong = '';
            if (hopDong != null) {
              soPhong = hopDong.room;
            }

            danhSachWidget.add(
              LandlordCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thanhVien.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Xin vào phòng $soPhong · dự kiến ${landlordDate(thanhVien.joinedAt)}',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            _xuLyYeuCau(thanhVien, false);
                          },
                          child: const Text('Từ chối'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            _xuLyYeuCau(thanhVien, true);
                          },
                          child: const Text('Duyệt'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          danhSachWidget.add(const SizedBox(height: 12));
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

        // Hiển thị danh sách kết quả tìm kiếm
        if (danhSachLoc.isEmpty) {
          danhSachWidget.add(
            const LandlordEmptyState(message: 'Không tìm thấy người thuê.'),
          );
        } else {
          for (int i = 0; i < danhSachLoc.length; i++) {
            final thanhVien = danhSachLoc[i];
            final hopDong = _store.leaseById(thanhVien.leaseId);
            String soPhong = '';
            if (hopDong != null) {
              soPhong = hopDong.room;
            }

            Widget? huyHieuDaiDien;
            if (thanhVien.isRepresentative) {
              huyHieuDaiDien = const LandlordStatusPill(
                'Đại diện',
                color: landlordBlue,
              );
            }

            danhSachWidget.add(
              LandlordCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(thanhVien.name[0]),
                  ),
                  title: Text(thanhVien.name),
                  subtitle: Text(
                    'Phòng $soPhong · ${thanhVien.phone}\nVào ở: ${landlordDate(thanhVien.joinedAt)}',
                  ),
                  isThreeLine: true,
                  trailing: huyHieuDaiDien,
                ),
              ),
            );
          }
        }

        return LandlordPageFrame(
          children: danhSachWidget,
        );
      },
    );
  }
}

// Hộp thoại nhập lý do khi từ chối thành viên
class _HopThoaiTuChoi extends StatefulWidget {
  @override
  State<_HopThoaiTuChoi> createState() => _HopThoaiTuChoiState();
}

class _HopThoaiTuChoiState extends State<_HopThoaiTuChoi> {
  final _controllerLyDo = TextEditingController();
  final _khoaBieuMau = GlobalKey<FormState>();

  @override
  void dispose() {
    _controllerLyDo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Từ chối thành viên'),
      content: Form(
        key: _khoaBieuMau,
        child: TextFormField(
          controller: _controllerLyDo,
          decoration: const InputDecoration(labelText: 'Lý do từ chối'),
          validator: (giaTri) {
            if (giaTri == null || giaTri.trim().isEmpty) {
              return 'Nhập lý do từ chối.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (_khoaBieuMau.currentState!.validate()) {
              Navigator.pop(context, _controllerLyDo.text.trim());
            }
          },
          child: const Text('Từ chối'),
        ),
      ],
    );
  }
}

