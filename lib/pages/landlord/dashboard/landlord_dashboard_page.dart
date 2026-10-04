import 'package:flutter/material.dart';

import '../landlord_ui.dart';

class LandlordDashboardPage extends StatelessWidget {
  const LandlordDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LandlordPageFrame(
      children: [
        const LandlordPageTitle(
          title: 'Xin chào, Nguyễn Văn An',
          subtitle: 'Tình hình nhà trọ Bình An hôm nay.',
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: const [
            _StatCard(
              label: 'Phòng trống',
              value: '3 / 20',
              icon: Icons.meeting_room_outlined,
              color: Color(0xFF16836F),
            ),
            _StatCard(
              label: 'Đang thuê',
              value: '17',
              icon: Icons.groups_outlined,
              color: landlordBlue,
            ),
            _StatCard(
              label: 'Hóa đơn đến hạn',
              value: '5',
              icon: Icons.receipt_long_outlined,
              color: Color(0xFFE08A1E),
            ),
            _StatCard(
              label: 'Sự cố mới',
              value: '2',
              icon: Icons.build_outlined,
              color: Color(0xFFD64545),
            ),
          ],
        ),
        const SizedBox(height: 18),
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
        const Text(
          'Việc cần làm',
          style: TextStyle(
            color: landlordInk,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const _TodoTile(
          icon: Icons.bolt_outlined,
          title: 'Nhập chỉ số điện nước tháng 10',
          subtitle: 'Còn 8 phòng chưa nhập',
        ),
        const _TodoTile(
          icon: Icons.fact_check_outlined,
          title: 'Duyệt thanh toán',
          subtitle: '4 minh chứng đang chờ kiểm tra',
        ),
        const _TodoTile(
          icon: Icons.build_outlined,
          title: 'Sự cố: Máy lạnh không lạnh',
          subtitle: 'Phòng A.302 · mới gửi 2 giờ trước',
        ),
        const _TodoTile(
          icon: Icons.person_add_alt_outlined,
          title: 'Duyệt thành viên mới',
          subtitle: 'Phòng B.105 có 1 yêu cầu thêm người',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LandlordCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: landlordBlue.withValues(alpha: 0.1),
          child: Icon(icon, color: landlordBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
