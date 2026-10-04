import 'package:flutter/material.dart';

import '../landlord_ui.dart';

class LandlordTenant {
  LandlordTenant({
    required this.name,
    required this.phone,
    required this.room,
    required this.moveIn,
    this.isRepresentative = false,
    this.pending = false,
  });

  final String name;
  final String phone;
  final String room;
  final String moveIn;
  final bool isRepresentative;

  /// true = yêu cầu thêm thành viên đang chờ chủ trọ duyệt.
  bool pending;
}

class LandlordMembersPage extends StatefulWidget {
  const LandlordMembersPage({super.key});

  @override
  State<LandlordMembersPage> createState() => _LandlordMembersPageState();
}

class _LandlordMembersPageState extends State<LandlordMembersPage> {
  String _search = '';

  final _tenants = <LandlordTenant>[
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

  @override
  Widget build(BuildContext context) {
    final pending = _tenants.where((t) => t.pending).toList();
    final active = _tenants
        .where((t) => !t.pending)
        .where(
          (t) =>
              t.name.toLowerCase().contains(_search.toLowerCase()) ||
              t.room.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();

    return LandlordPageFrame(
      children: [
        LandlordPageTitle(
          title: 'Người thuê',
          subtitle: '${active.length} người đang ở · ${pending.length} chờ duyệt',
        ),
        if (pending.isNotEmpty) ...[
          const Text(
            'Chờ duyệt thành viên',
            style: TextStyle(
              color: landlordInk,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final tenant in pending) _buildPendingCard(tenant),
          const SizedBox(height: 10),
        ],
        TextField(
          decoration: const InputDecoration(
            hintText: 'Tìm theo tên hoặc phòng',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 12),
        if (active.isEmpty)
          const LandlordEmptyState(message: 'Không tìm thấy người thuê.'),
        for (final tenant in active) _buildTenantCard(tenant),
      ],
    );
  }

  Widget _buildTenantCard(LandlordTenant tenant) {
    return LandlordCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: landlordBlue.withValues(alpha: 0.1),
          child: Text(
            tenant.name[0],
            style: const TextStyle(
              color: landlordBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          tenant.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Phòng ${tenant.room} · ${tenant.phone}\nVào ở: ${tenant.moveIn}',
        ),
        isThreeLine: true,
        trailing: tenant.isRepresentative
            ? const LandlordStatusPill('Đại diện', color: landlordBlue)
            : null,
      ),
    );
  }

  Widget _buildPendingCard(LandlordTenant tenant) {
    return LandlordCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tenant.name,
            style: const TextStyle(
              color: landlordInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Xin vào phòng ${tenant.room} · dự kiến ${tenant.moveIn}',
            style: const TextStyle(color: landlordMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() => _tenants.remove(tenant));
                  showLandlordMessage(context, 'Đã từ chối ${tenant.name}.');
                },
                child: const Text('Từ chối'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  setState(() => tenant.pending = false);
                  showLandlordMessage(context, 'Đã duyệt ${tenant.name}.');
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
