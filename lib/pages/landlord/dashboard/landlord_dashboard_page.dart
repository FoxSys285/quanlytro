import 'package:flutter/material.dart';

import '../incidents/landlord_incidents_page.dart';
import '../landlord_ui.dart';
import '../members/landlord_members_page.dart';
import '../meter_readings/landlord_meter_readings_page.dart';

// Trang tổng quan của chủ trọ, hiển thị thống kê nhanh và các việc cần làm
class LandlordDashboardPage extends StatelessWidget {
  const LandlordDashboardPage({super.key});

  // Hàm chuyển trang đơn giản có bọc Scaffold để có Material và nút Quay lại (Back)
  void _chuyenTrang(BuildContext context, Widget manHinh) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: landlordCanvas,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: landlordInk),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: manHinh,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LandlordPageFrame(
      children: [
        // Lời chào và tên khu trọ
        const LandlordPageTitle(
          title: 'Xin chào, Nguyễn Văn An',
          subtitle: 'Tình hình nhà trọ Bình An hôm nay.',
        ),

        // Lưới 4 thẻ thống kê nhanh các thông số cơ bản
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: const [
            _TheThongKe(
              nhanTieuDe: 'Phòng trống',
              giaTri: '3 / 20',
              bieuTuong: Icons.meeting_room_outlined,
              mauSac: Color(0xFF16836F),
            ),
            _TheThongKe(
              nhanTieuDe: 'Đang thuê',
              giaTri: '17',
              bieuTuong: Icons.groups_outlined,
              mauSac: landlordBlue,
            ),
            _TheThongKe(
              nhanTieuDe: 'Hóa đơn đến hạn',
              giaTri: '5',
              bieuTuong: Icons.receipt_long_outlined,
              mauSac: Color(0xFFE08A1E),
            ),
            _TheThongKe(
              nhanTieuDe: 'Sự cố mới',
              giaTri: '2',
              bieuTuong: Icons.build_outlined,
              mauSac: Color(0xFFD64545),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Thẻ hiển thị doanh thu tháng và tiến độ thu tiền
        const LandlordCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doanh thu tháng này',
                style: TextStyle(color: landlordMuted, fontSize: 12),
              ),
              SizedBox(height: 6),
              Text(
                '52.400.000 đ',
                style: TextStyle(
                  color: landlordInk,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 10),
              LinearProgressIndicator(
                value: 0.72,
                color: landlordBlue,
                backgroundColor: landlordLine,
              ),
              SizedBox(height: 6),
              Text(
                'Đã thu 72% · còn 4 thanh toán chờ duyệt',
                style: TextStyle(color: landlordMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Danh sách các việc chủ trọ cần xử lý
        const Text(
          'Việc cần làm',
          style: TextStyle(
            color: landlordInk,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),

        // 1. Nhập chỉ số điện nước (chuyển sang trang Chỉ số điện nước)
        _DongViecCanLam(
          bieuTuong: Icons.bolt_outlined,
          tieuDe: 'Nhập chỉ số điện nước tháng 10',
          moTa: 'Còn 8 phòng chưa nhập',
          khiBam: () {
            _chuyenTrang(context, const LandlordMeterReadingsPage());
          },
        ),

        // 2. Duyệt thanh toán (chức năng duyệt thanh toán)
        _DongViecCanLam(
          bieuTuong: Icons.fact_check_outlined,
          tieuDe: 'Duyệt thanh toán',
          moTa: '4 minh chứng đang chờ kiểm tra',
          khiBam: () {
            showLandlordMessage(
              context,
              'Chức năng Duyệt thanh toán nằm trong mục Thu chi.',
            );
          },
        ),

        // 3. Sự cố máy lạnh (chuyển sang trang Yêu cầu sửa chữa)
        _DongViecCanLam(
          bieuTuong: Icons.build_outlined,
          tieuDe: 'Sự cố: Máy lạnh không lạnh',
          moTa: 'Phòng A.302 · mới gửi 2 giờ trước',
          khiBam: () {
            _chuyenTrang(context, const LandlordIncidentsPage());
          },
        ),

        // 4. Duyệt thành viên mới (chuyển sang trang Người thuê)
        _DongViecCanLam(
          bieuTuong: Icons.person_add_alt_outlined,
          tieuDe: 'Duyệt thành viên mới',
          moTa: 'Phòng B.105 có 1 yêu cầu thêm người',
          khiBam: () {
            _chuyenTrang(context, const LandlordMembersPage());
          },
        ),
      ],
    );
  }
}

// Thẻ hiển thị một chỉ số thống kê
class _TheThongKe extends StatelessWidget {
  const _TheThongKe({
    required this.nhanTieuDe,
    required this.giaTri,
    required this.bieuTuong,
    required this.mauSac,
  });

  final String nhanTieuDe;
  final String giaTri;
  final IconData bieuTuong;
  final Color mauSac;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: landlordLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(bieuTuong, color: mauSac),
          Text(
            giaTri,
            style: const TextStyle(
              color: landlordInk,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            nhanTieuDe,
            style: const TextStyle(color: landlordMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Thẻ dòng hiển thị một đầu việc cần làm
class _DongViecCanLam extends StatelessWidget {
  const _DongViecCanLam({
    required this.bieuTuong,
    required this.tieuDe,
    required this.moTa,
    this.khiBam,
  });

  final IconData bieuTuong;
  final String tieuDe;
  final String moTa;
  final VoidCallback? khiBam;

  @override
  Widget build(BuildContext context) {
    return LandlordCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: khiBam,
        leading: CircleAvatar(
          backgroundColor: landlordBlue.withValues(alpha: 0.1),
          child: Icon(bieuTuong, color: landlordBlue, size: 20),
        ),
        title: Text(
          tieuDe,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(moTa, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
