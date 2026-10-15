import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import '../finance/landlord_finance_models.dart';
import '../incidents/models/landlord_incident.dart';
import '../rooms/models/landlord_room.dart';
import '../../shared/rental/lease_member.dart';
import '../../shared/conversations/conversation_store.dart';
import '../../shared/viewings/viewing_store.dart';
import '../../shared/viewings/models/room_viewing.dart';

// Các màn hình chức năng của Minh
import '../conversations/landlord_danhsachtinnhan_page.dart';
import '../meter_readings/landlord_chisodiennuoc_page.dart';
import '../incidents/landlord_yeucausuachua_page.dart';
import '../members/landlord_nguoithue_page.dart';
import '../services/landlord_dichvubanggia_page.dart';

// Các màn hình chức năng liên quan khác
import '../billing/landlord_billing_page.dart';
import '../payments/landlord_payments_page.dart';
import '../leases/landlord_leases_page.dart';
import '../viewings/landlord_viewings_page.dart';
import '../announcements/landlord_announcements_page.dart';

// =====================================================================
// 1. CÁC WIDGET PHỤ (Được khai báo ở đầu tệp trước khi lớp chính gọi)
// =====================================================================

// Thẻ hiển thị ô số liệu thống kê ở đầu trang
class _TheThongKe extends StatelessWidget {
  const _TheThongKe({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

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
          Icon(icon, color: color),
          Text(
            value,
            style: const TextStyle(
              color: landlordInk,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: landlordMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Thẻ hiển thị từng mục việc cần làm có kèm số lượng cần xử lý
class _TheViecCanLam extends StatelessWidget {
  const _TheViecCanLam({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.soLuongCanXuLy,
    this.mauSac,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int? soLuongCanXuLy;
  final Color? mauSac;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mauHienThi = mauSac ?? landlordBlue;
    final coViecCanLam = soLuongCanXuLy != null && soLuongCanXuLy! > 0;

    return LandlordCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: mauHienThi.withValues(alpha: 0.12),
          child: Icon(icon, color: mauHienThi, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: coViecCanLam ? const Color(0xFFC0392B) : landlordMuted,
            fontWeight: coViecCanLam ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (coViecCanLam)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$soLuongCanXuLy',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: landlordMuted),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 2. LỚP CHÍNH LANDLORD TỔNG QUAN
// =====================================================================
class LandlordTongQuanPage extends StatelessWidget {
  const LandlordTongQuanPage({super.key});

  // Hàm chuyển trang tiện lợi có kèm thanh tiêu đề và nút quay lại
  static void _chuyenTrang(BuildContext context, String tieuDe, Widget trang) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(tieuDe)),
          body: trang,
        ),
      ),
    );
  }

  // Hàm build đặt ở cuối lớp, chạy liền mạch một đường từ trên xuống dưới
  @override
  Widget build(BuildContext context) {
    final khoDuLieu = LandlordDemoStore.instance;
    final khoTroChuyen = ConversationStore.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([khoDuLieu, khoTroChuyen]),
      builder: (context, _) {
        // 1. Thống kê số phòng trống và phòng đang thuê
        final danhSachPhong = khoDuLieu.roomDetails;
        int soPhongTrong = 0;
        int soPhongDangThue = 0;

        for (int i = 0; i < danhSachPhong.length; i++) {
          final phong = danhSachPhong[i];
          if (phong.status == LandlordRoomStatus.vacant) {
            soPhongTrong = soPhongTrong + 1;
          } else if (phong.status == LandlordRoomStatus.occupied) {
            soPhongDangThue = soPhongDangThue + 1;
          }
        }

        // 2. Tính tiền cần thu và tiền đã thu trong tháng hiện tại
        final thoiGianHienTai = DateTime.now();
        int tongTienCanThu = 0;
        int tongTienDaThu = 0;
        int soHoaDonChuaThu = 0;

        for (int i = 0; i < khoDuLieu.invoices.length; i++) {
          final hoaDon = khoDuLieu.invoices[i];
          if (!hoaDon.cancelled) {
            if (hoaDon.period.year == thoiGianHienTai.year &&
                hoaDon.period.month == thoiGianHienTai.month) {
              tongTienCanThu = tongTienCanThu + hoaDon.total;
              tongTienDaThu = tongTienDaThu + hoaDon.paidAmount;
            }
            if (hoaDon.status == LandlordInvoiceStatus.unpaid ||
                hoaDon.status == LandlordInvoiceStatus.overdue) {
              soHoaDonChuaThu = soHoaDonChuaThu + 1;
            }
          }
        }

        // 3. Đếm số tin nhắn mới chưa đọc từ người thuê
        int soTinNhanChuaDoc = 0;
        final danhSachHoiThoai = khoTroChuyen.conversations;
        for (int i = 0; i < danhSachHoiThoai.length; i++) {
          final hoiThoai = danhSachHoiThoai[i];
          if (hoiThoai.propertyId == khoDuLieu.property.id) {
            soTinNhanChuaDoc = soTinNhanChuaDoc + hoiThoai.unread;
          }
        }

        // 4. Lấy danh sách sự cố mới cần xử lý
        final List<LandlordIncident> danhSachSuCoMoi = [];
        for (int i = 0; i < khoDuLieu.incidents.length; i++) {
          final suCo = khoDuLieu.incidents[i];
          if (suCo.status == IncidentStatus.newly) {
            danhSachSuCoMoi.add(suCo);
          }
        }

        // 5. Đếm số phòng đang thuê chưa nhập chỉ số điện nước tháng này
        int soPhongChuaGhiChiSo = 0;
        final thangNay = DateTime(thoiGianHienTai.year, thoiGianHienTai.month);
        for (int i = 0; i < khoDuLieu.activeLeases.length; i++) {
          final hopDong = khoDuLieu.activeLeases[i];
          final chiSo = khoDuLieu.readingForRoom(hopDong.room, thangNay);
          if (chiSo == null || !chiSo.isDone) {
            soPhongChuaGhiChiSo = soPhongChuaGhiChiSo + 1;
          }
        }

        // 6. Đếm số thành viên mới đang chờ duyệt
        int soThanhVienChoDuyet = 0;
        for (int i = 0; i < khoDuLieu.members.length; i++) {
          final thanhVien = khoDuLieu.members[i];
          final hopDong = khoDuLieu.leaseById(thanhVien.leaseId);
          if (thanhVien.status == LeaseMemberStatus.pending &&
              hopDong != null &&
              hopDong.isCurrent) {
            soThanhVienChoDuyet = soThanhVienChoDuyet + 1;
          }
        }

        // 7. Đếm số khoản thanh toán chờ duyệt
        int soKhoanChoDuyet = 0;
        for (int i = 0; i < khoDuLieu.payments.length; i++) {
          if (khoDuLieu.payments[i].status == LandlordPaymentStatus.pending) {
            soKhoanChoDuyet = soKhoanChoDuyet + 1;
          }
        }

        // 8. Đếm số lịch xem phòng của khách mới
        final khoXemPhong = ViewingStore.instance;
        int soLichXemPhong = 0;
        for (int i = 0; i < khoXemPhong.records.length; i++) {
          final lich = khoXemPhong.records[i];
          if (lich.status == ViewingStatus.pending ||
              lich.status == ViewingStatus.confirmed) {
            soLichXemPhong = soLichXemPhong + 1;
          }
        }

        // 9. Đếm số hợp đồng sắp hết hạn trong vòng 30 ngày
        int soHopDongSapHetHan = 0;
        for (int i = 0; i < khoDuLieu.activeLeases.length; i++) {
          final hopDong = khoDuLieu.activeLeases[i];
          final soNgayConLai =
              hopDong.endDate.difference(thoiGianHienTai).inDays;
          if (soNgayConLai >= 0 && soNgayConLai <= 30) {
            soHopDongSapHetHan = soHopDongSapHetHan + 1;
          }
        }

        // 10. Tính tỉ lệ phần trăm thu tiền bằng if-else (tránh chia cho 0)
        double tyLeTienDo = 0.0;
        int phanTramDaThu = 0;
        if (tongTienCanThu > 0) {
          tyLeTienDo = (tongTienDaThu / tongTienCanThu).clamp(0.0, 1.0);
          phanTramDaThu = ((tongTienDaThu * 100) / tongTienCanThu).round();
        }

        // 11. Xây dựng danh sách các Widget hiển thị
        final List<Widget> danhSachWidget = [
          LandlordPageTitle(
            title: 'Xin chào, ${khoDuLieu.property.ownerName}',
            subtitle: 'Tình hình nhà trọ ${khoDuLieu.property.name} hôm nay.',
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _TheThongKe(
                label: 'Phòng trống',
                value: '$soPhongTrong / ${danhSachPhong.length}',
                icon: Icons.meeting_room_outlined,
                color: const Color(0xFF16836F),
              ),
              _TheThongKe(
                label: 'Đang thuê',
                value: '$soPhongDangThue',
                icon: Icons.groups_outlined,
                color: landlordBlue,
              ),
              _TheThongKe(
                label: 'Hóa đơn cần thu',
                value: '$soHoaDonChuaThu',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFFE08A1E),
              ),
              _TheThongKe(
                label: 'Sự cố mới',
                value: '${danhSachSuCoMoi.length}',
                icon: Icons.build_outlined,
                color: const Color(0xFFD64545),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LandlordCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đã thu cho hóa đơn tháng này',
                  style: TextStyle(color: landlordMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  formatLandlordMoney(tongTienDaThu),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: tyLeTienDo,
                  color: landlordBlue,
                ),
                const SizedBox(height: 6),
                Text(
                  'Đã thu $phanTramDaThu% · còn $soKhoanChoDuyet thanh toán chờ duyệt',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Việc cần làm',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          // Mục 1: Tin nhắn từ khách thuê (Module Tin nhắn của Minh)
          _TheViecCanLam(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Tin nhắn khách thuê',
            subtitle: soTinNhanChuaDoc > 0
                ? '$soTinNhanChuaDoc tin nhắn mới cần phản hồi'
                : 'Đã phản hồi hết tất cả tin nhắn',
            soLuongCanXuLy: soTinNhanChuaDoc,
            mauSac: const Color(0xFF2980B9),
            onTap: () {
              _chuyenTrang(
                context,
                'Tin nhắn',
                const LandlordDanhSachTinNhanPage(),
              );
            },
          ),

          // Mục 2: Nhập chỉ số điện nước (Module Chỉ số điện nước của Minh)
          _TheViecCanLam(
            icon: Icons.bolt_outlined,
            title: 'Nhập chỉ số điện nước tháng ${thoiGianHienTai.month}',
            subtitle: soPhongChuaGhiChiSo > 0
                ? 'Còn $soPhongChuaGhiChiSo phòng đang thuê chưa chốt số'
                : 'Đã nhập đủ chỉ số các phòng',
            soLuongCanXuLy: soPhongChuaGhiChiSo,
            mauSac: const Color(0xFFF39C12),
            onTap: () {
              _chuyenTrang(
                context,
                'Chỉ số điện nước',
                const LandlordChiSoDienNuocPage(),
              );
            },
          ),
        ];

        // Mục 3: Các thẻ sự cố sửa chữa mới (Module Yêu cầu sửa chữa của Minh)
        if (danhSachSuCoMoi.isEmpty) {
          danhSachWidget.add(
            _TheViecCanLam(
              icon: Icons.build_outlined,
              title: 'Yêu cầu sửa chữa & Sự cố',
              subtitle: 'Không có sự cố mới nào cần xử lý',
              mauSac: const Color(0xFF27AE60),
              onTap: () {
                _chuyenTrang(
                  context,
                  'Yêu cầu sửa chữa',
                  const LandlordYeuCauSuaChuaPage(),
                );
              },
            ),
          );
        } else {
          for (int i = 0; i < danhSachSuCoMoi.length; i++) {
            final suCo = danhSachSuCoMoi[i];
            danhSachWidget.add(
              _TheViecCanLam(
                icon: Icons.build_outlined,
                title: 'Sự cố: ${suCo.title}',
                subtitle: 'Phòng ${suCo.room} · ${suCo.status.label}',
                soLuongCanXuLy: 1,
                mauSac: const Color(0xFFE74C3C),
                onTap: () {
                  _chuyenTrang(
                    context,
                    'Yêu cầu sửa chữa',
                    const LandlordYeuCauSuaChuaPage(),
                  );
                },
              ),
            );
          }
        }

        // Mục 4: Duyệt thành viên mới vào phòng (Module Người thuê của Minh)
        danhSachWidget.add(
          _TheViecCanLam(
            icon: Icons.person_add_alt_outlined,
            title: 'Duyệt thành viên mới',
            subtitle: soThanhVienChoDuyet > 0
                ? '$soThanhVienChoDuyet yêu cầu thêm người vào phòng'
                : 'Không có yêu cầu thêm người mới',
            soLuongCanXuLy: soThanhVienChoDuyet,
            mauSac: const Color(0xFF8E44AD),
            onTap: () {
              _chuyenTrang(
                context,
                'Người thuê',
                const LandlordNguoiThuePage(),
              );
            },
          ),
        );

        // Mục 5: Thu tiền phòng & Hóa đơn
        danhSachWidget.add(
          _TheViecCanLam(
            icon: Icons.receipt_long_outlined,
            title: 'Thu tiền phòng tháng ${thoiGianHienTai.month}',
            subtitle: soHoaDonChuaThu > 0
                ? 'Còn $soHoaDonChuaThu hóa đơn chưa thanh toán'
                : 'Tất cả hóa đơn đã được thu đủ',
            soLuongCanXuLy: soHoaDonChuaThu,
            mauSac: const Color(0xFFD35400),
            onTap: () {
              _chuyenTrang(
                context,
                'Hóa đơn tiền phòng',
                const LandlordBillingPage(),
              );
            },
          ),
        );

        // Mục 6: Duyệt thanh toán chuyển khoản
        danhSachWidget.add(
          _TheViecCanLam(
            icon: Icons.fact_check_outlined,
            title: 'Duyệt thanh toán',
            subtitle: soKhoanChoDuyet > 0
                ? '$soKhoanChoDuyet khoản đang chờ kiểm tra sao kê'
                : 'Đã duyệt hết các khoản chuyển khoản',
            soLuongCanXuLy: soKhoanChoDuyet,
            mauSac: const Color(0xFF16A085),
            onTap: () {
              _chuyenTrang(
                context,
                'Duyệt thanh toán',
                const LandlordPaymentsPage(),
              );
            },
          ),
        );

        // Mục 7: Lịch hẹn xem phòng của khách mới
        danhSachWidget.add(
          _TheViecCanLam(
            icon: Icons.calendar_month_outlined,
            title: 'Lịch hẹn dẫn khách xem phòng',
            subtitle: soLichXemPhong > 0
                ? '$soLichXemPhong lịch hẹn xem phòng cần chuẩn bị'
                : 'Chưa có lịch hẹn xem phòng mới',
            soLuongCanXuLy: soLichXemPhong,
            mauSac: const Color(0xFF2C3E50),
            onTap: () {
              _chuyenTrang(
                context,
                'Lịch xem phòng',
                const LandlordViewingsPage(),
              );
            },
          ),
        );

        // Mục 8: Hợp đồng thuê sắp hết hạn
        danhSachWidget.add(
          _TheViecCanLam(
            icon: Icons.description_outlined,
            title: 'Theo dõi hợp đồng thuê',
            subtitle: soHopDongSapHetHan > 0
                ? '$soHopDongSapHetHan hợp đồng sắp hết hạn trong 30 ngày'
                : 'Các hợp đồng đang trong thời hạn hiệu lực',
            soLuongCanXuLy: soHopDongSapHetHan,
            mauSac: const Color(0xFF7F8C8D),
            onTap: () {
              _chuyenTrang(
                context,
                'Hợp đồng thuê',
                const LandlordLeasesPage(),
              );
            },
          ),
        );

        // Mục 9: Quản lý bảng giá dịch vụ (Module Dịch vụ của Minh)
        danhSachWidget.add(
          _TheViecCanLam(
            icon: Icons.tune_rounded,
            title: 'Bảng giá dịch vụ phòng',
            subtitle:
                '${khoDuLieu.services.length} dịch vụ đang áp dụng (Điện, nước, rác, wifi)',
            mauSac: const Color(0xFF34495E),
            onTap: () {
              _chuyenTrang(
                context,
                'Dịch vụ & Bảng giá',
                const LandlordDichVuBangGiaPage(),
              );
            },
          ),
        );

        // Mục 10: Gửi thông báo chung cho nhà trọ
        danhSachWidget.add(
          _TheViecCanLam(
            icon: Icons.campaign_outlined,
            title: 'Gửi thông báo chung',
            subtitle: 'Phát thông báo nội quy, bảo trì hoặc tiền phòng',
            mauSac: const Color(0xFFC0392B),
            onTap: () {
              _chuyenTrang(
                context,
                'Thông báo',
                const LandlordAnnouncementsPage(),
              );
            },
          ),
        );

        return LandlordPageFrame(
          children: danhSachWidget,
        );
      },
    );
  }
}
