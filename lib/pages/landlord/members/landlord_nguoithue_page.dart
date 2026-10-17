import 'package:flutter/material.dart';

import '../landlord_ui.dart';
import '../landlord_demo_store.dart';
import '../finance/landlord_finance_models.dart';
import '../../shared/rental/lease_member.dart';
import 'member_rejection_dialog.dart';

class LandlordNguoiThuePage extends StatefulWidget {
  const LandlordNguoiThuePage({super.key, this.store});
  final LandlordDemoStore? store;

  @override
  State<LandlordNguoiThuePage> createState() => _LandlordNguoiThuePageState();
}

class _LandlordNguoiThuePageState extends State<LandlordNguoiThuePage> {
  String _query = '';
  bool _requests = true;
  LeaseMemberStatus? _requestStatus = LeaseMemberStatus.pending;
  LandlordDemoStore get _store => widget.store ?? LandlordDemoStore.instance;

  Future<void> _review(LeaseMember member, bool approve) async {
    String reason = '';
    if (!approve) {
      final result = await showDialog<String>(
        context: context,
        builder: (_) => MemberRejectionDialog(),
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

  bool _matches(LeaseMember member) {
    final lease = _store.leaseById(member.leaseId);
    return '${member.name} ${member.phone} ${lease?.room ?? ''} ${lease?.tenantName ?? ''}'
        .toLowerCase()
        .contains(_query.trim().toLowerCase());
  }

  String _statusLabel(LeaseMemberStatus status) => switch (status) {
    LeaseMemberStatus.pending => 'Chờ duyệt',
    LeaseMemberStatus.active => 'Đã duyệt',
    LeaseMemberStatus.rejected => 'Đã từ chối',
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final current = _store.members
          .where(
            (member) => _store.leaseById(member.leaseId)?.isCurrent == true,
          )
          .toList();
      final active = current
          .where((member) => member.status == LeaseMemberStatus.active)
          .toList();
      final pending = current
          .where((member) => member.status == LeaseMemberStatus.pending)
          .length;
      final requests =
          current
              .where(
                (member) =>
                    !member.isRepresentative &&
                    (member.status != LeaseMemberStatus.active ||
                        member.requestedAt != null),
              )
              .where(
                (member) =>
                    (_requestStatus == null ||
                        member.status == _requestStatus) &&
                    _matches(member),
              )
              .toList()
            ..sort(
              (a, b) => (b.requestedAt ?? b.joinedAt).compareTo(
                a.requestedAt ?? a.joinedAt,
              ),
            );
      final filtered = active.where(_matches).toList();
      final leaseIds = filtered.map((member) => member.leaseId).toSet().toList()
        ..sort(
          (a, b) =>
              _store.leaseById(a)!.room.compareTo(_store.leaseById(b)!.room),
        );
      return LandlordPageFrame(
        children: [
          LandlordPageTitle(
            title: 'Người thuê',
            subtitle:
                '${active.length} người đang ở · $pending yêu cầu chờ duyệt',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('Yêu cầu thêm người ($pending)'),
                selected: _requests,
                onSelected: (_) => setState(() => _requests = true),
              ),
              ChoiceChip(
                label: Text('Danh sách người thuê (${active.length})'),
                selected: !_requests,
                onSelected: (_) => setState(() => _requests = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm theo tên, số điện thoại hoặc phòng',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (_requests) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả yêu cầu'),
                  selected: _requestStatus == null,
                  onSelected: (_) => setState(() => _requestStatus = null),
                ),
                for (final status in LeaseMemberStatus.values)
                  ChoiceChip(
                    label: Text(_statusLabel(status)),
                    selected: _requestStatus == status,
                    onSelected: (_) => setState(() => _requestStatus = status),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (requests.isEmpty)
              const LandlordEmptyState(message: 'Không có yêu cầu phù hợp.'),
            for (final member in requests) _requestCard(member),
          ] else ...[
            if (filtered.isEmpty)
              const LandlordEmptyState(message: 'Không tìm thấy người thuê.'),
            for (final leaseId in leaseIds)
              LandlordCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  key: PageStorageKey('members-$leaseId'),
                  initiallyExpanded: true,
                  leading: const Icon(
                    Icons.meeting_room_outlined,
                    color: landlordBlue,
                  ),
                  title: Text(
                    'Phòng ${_store.leaseById(leaseId)!.room}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${_store.membersForLease(leaseId).length} / ${_store.roomByCode(_store.leaseById(leaseId)!.room)?.capacity ?? '—'} người',
                  ),
                  children: [
                    for (final member in filtered.where(
                      (item) => item.leaseId == leaseId,
                    ))
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(member.name.characters.first),
                        ),
                        title: Text(member.name),
                        subtitle: Text(
                          '${member.phone}\nVào ở: ${landlordDate(member.joinedAt)}',
                        ),
                        isThreeLine: true,
                        trailing: member.isRepresentative
                            ? const LandlordStatusPill(
                                'Đại diện',
                                color: landlordBlue,
                              )
                            : null,
                      ),
                  ],
                ),
              ),
          ],
        ],
      );
    },
  );

  Widget _requestCard(LeaseMember member) {
    final lease = _store.leaseById(member.leaseId)!;
    final color = switch (member.status) {
      LeaseMemberStatus.pending => const Color(0xFFAB7623),
      LeaseMemberStatus.active => const Color(0xFF16836F),
      LeaseMemberStatus.rejected => Colors.red,
    };
    final requester = _store.members
        .where(
          (item) =>
              item.leaseId == lease.id && item.tenantId == member.requestedBy,
        )
        .firstOrNull;
    return LandlordCard(
      key: ValueKey(member.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Phòng ${lease.room}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              LandlordStatusPill(_statusLabel(member.status), color: color),
            ],
          ),
          const Divider(height: 24),
          Text(
            member.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text('Điện thoại: ${member.phone}'),
          Text('Ngày dự kiến vào ở: ${landlordDate(member.joinedAt)}'),
          Text('Người gửi: ${requester?.name ?? lease.tenantName}'),
          if (member.requestedAt != null)
            Text('Ngày gửi: ${landlordDate(member.requestedAt!)}'),
          Text(
            'Đang ở: ${_store.membersForLease(lease.id).length} / ${_store.roomByCode(lease.room)?.capacity ?? '—'} người',
          ),
          if (member.rejectionReason != null)
            Text(
              'Lý do: ${member.rejectionReason}',
              style: const TextStyle(color: Colors.red),
            ),
          if (member.status == LeaseMemberStatus.pending) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _review(member, true),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Duyệt'),
                ),
                OutlinedButton(
                  onPressed: () => _review(member, false),
                  child: const Text('Từ chối'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
