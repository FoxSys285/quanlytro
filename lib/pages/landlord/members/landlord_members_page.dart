import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import '../finance/landlord_finance_models.dart';
import '../../shared/rental/lease_member.dart';

class LandlordMembersPage extends StatefulWidget {
  const LandlordMembersPage({super.key, this.store});
  final LandlordDemoStore? store;
  @override
  State<LandlordMembersPage> createState() => _LandlordMembersPageState();
}

class _LandlordMembersPageState extends State<LandlordMembersPage> {
  String _search = '';
  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final members = _store.members.where(
        (member) => _store.leaseById(member.leaseId)?.isCurrent ?? false,
      );
      final pending = members
          .where((member) => member.status == LeaseMemberStatus.pending)
          .toList();
      final active = members
          .where((member) => member.status == LeaseMemberStatus.active)
          .toList();
      final filtered = active
          .where(
            (member) =>
                '${member.name} ${_store.leaseById(member.leaseId)!.room}'
                    .toLowerCase()
                    .contains(_search.toLowerCase()),
          )
          .toList();
      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Người thuê',
            subtitle:
                '${active.length} người đang ở · ${pending.length} chờ duyệt',
          ),
          if (pending.isNotEmpty)
            const Text(
              'Chờ duyệt thành viên',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          for (final member in pending)
            LandlordCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Xin vào phòng ${_store.leaseById(member.leaseId)!.room} · dự kiến ${landlordDate(member.joinedAt)}',
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _review(member, false),
                        child: const Text('Từ chối'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _review(member, true),
                        child: const Text('Duyệt'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
          if (filtered.isEmpty)
            const LandlordEmptyState(message: 'Không tìm thấy người thuê.'),
          for (final member in filtered)
            LandlordCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(child: Text(member.name[0])),
                title: Text(member.name),
                subtitle: Text(
                  'Phòng ${_store.leaseById(member.leaseId)!.room} · ${member.phone}\nVào ở: ${landlordDate(member.joinedAt)}',
                ),
                isThreeLine: true,
                trailing: member.isRepresentative
                    ? const LandlordStatusPill('Đại diện', color: landlordBlue)
                    : null,
              ),
            ),
        ],
      );
    },
  );

  Future<void> _review(LeaseMember member, bool approve) async {
    var reason = '';
    if (!approve) {
      final result = await showDialog<String>(
        context: context,
        builder: (_) => _RejectionDialog(),
      );
      if (!mounted || result == null) return;
      reason = result;
    }
    try {
      _store.reviewMember(member, approve: approve, reason: reason);
      showLandlordMessage(
        context,
        'Đã ${approve ? 'duyệt' : 'từ chối'} ${member.name}.',
      );
    } on ArgumentError catch (error) {
      showLandlordMessage(context, error.message.toString());
    }
  }
}

class _RejectionDialog extends StatefulWidget {
  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Từ chối thành viên'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _reason,
        decoration: const InputDecoration(labelText: 'Lý do từ chối'),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Nhập lý do từ chối.'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _reason.text.trim());
          }
        },
        child: const Text('Từ chối'),
      ),
    ],
  );
}
