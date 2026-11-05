import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../data/app_persistence.dart';
import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import '../landlord/landlord_demo_store.dart';
import '../shared/widgets/list_pagination.dart';
import 'admin_ui.dart';
import '../shared/rental/lease_member.dart';
import '../landlord/finance/landlord_finance_models.dart';

typedef AdminAccount = ({
  String id,
  String email,
  String name,
  String role,
  bool disabled,
});

Future<List<AdminAccount>> loadAdminAccounts() async {
  final auth = LocalAuth.instance;
  if (!auth.isCloudMode) {
    return [
      for (final a in auth.localAccounts)
        (
          id: a.email,
          email: a.email,
          name: a.role.label,
          role: a.role.name,
          disabled: a.disabled,
        ),
    ];
  }
  if (auth.role != AppRole.admin) {
    throw ArgumentError('Đăng nhập admin để đọc danh sách tài khoản.');
  }
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .get();
  return [
    for (final doc in snapshot.docs)
      (
        id: doc.id,
        email: doc.data()['email'] as String? ?? '',
        name: doc.data()['displayName'] as String? ?? doc.id,
        role: doc.data()['role'] as String? ?? 'unknown',
        disabled: doc.data()['disabled'] != false,
      ),
  ];
}

Future<void> setAdminAccountDisabled(String uid, bool disabled) async {
  final auth = LocalAuth.instance;
  if (!auth.isCloudMode || auth.role != AppRole.admin || auth.session == null) {
    throw ArgumentError('Đăng nhập admin để quản lý tài khoản Firebase.');
  }
  if (uid.isEmpty || uid.contains('/') || uid == auth.session!.uid) {
    throw ArgumentError('Không thể thay đổi tài khoản quản trị hiện tại.');
  }
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'disabled': disabled,
  });
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key, this.activity = false});
  final bool activity;
  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _updatingAccounts = <String>{};
  String _query = '', _role = 'all', _house = 'all', _segment = 'accounts';
  bool _lockedOnly = false;
  int _page = 0;
  late Future<List<AdminAccount>> _accounts = loadAdminAccounts();
  RentalPortfolio get portfolio => RentalPortfolio.instance;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      LocalAuth.instance,
      RentalPortfolio.instance,
    ]),
    builder: (context, _) => FutureBuilder<List<AdminAccount>>(
      future: _accounts,
      builder: (context, snapshot) {
        final auth = LocalAuth.instance;
        final accounts = auth.isCloudMode
            ? snapshot.data
            : [
                for (final a in auth.localAccounts)
                  (
                    id: a.email,
                    email: a.email,
                    name: a.role.label,
                    role: a.role.name,
                    disabled: a.disabled,
                  ),
              ];
        if (widget.activity) return _activity(context, accounts);
        final matched =
            accounts
                ?.where(
                  (a) =>
                      (_role == 'all' || a.role == _role) &&
                      (!_lockedOnly || a.disabled) &&
                      '${a.email} ${a.name} ${a.id}'.toLowerCase().contains(
                        _query,
                      ),
                )
                .toList() ??
            [];
        final page = _page.clamp(
          0,
          ListPagination.lastPage(matched.length, 12),
        );
        final members = {
          for (final s in portfolio.stores)
            for (final m in s.members) m.tenantId,
        }.length;
        return AdminFrame(
          title: 'Người dùng & tài khoản',
          subtitle: 'Tìm đúng người, kiểm tra hồ sơ và trạng thái tài khoản.',
          children: [
            const AdminSyncBar(),
            AdminPanel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _count(
                      '${accounts?.length ?? '—'}',
                      'Tài khoản',
                      Icons.manage_accounts_outlined,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _count(
                      '$members',
                      'Hồ sơ thuê',
                      Icons.groups_outlined,
                      color: adminTeal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _count(
                      '${accounts?.where((a) => a.disabled).length ?? '—'}',
                      'Đang khóa',
                      Icons.lock_outline,
                      color: adminOrange,
                    ),
                  ),
                ],
              ),
            ),
            AdminPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'accounts',
                        label: Text('Tài khoản'),
                        icon: Icon(Icons.badge_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: 'members',
                        label: Text('Người thuê'),
                        icon: Icon(Icons.groups_outlined, size: 18),
                      ),
                    ],
                    selected: {_segment},
                    onSelectionChanged: (v) => setState(() {
                      _segment = v.single;
                      _query = '';
                      _page = 0;
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: ValueKey(_segment),
                    decoration: InputDecoration(
                      labelText: _segment == 'members'
                          ? 'Tìm tên, điện thoại hoặc phòng'
                          : 'Tìm tên, email hoặc mã tài khoản',
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                    onChanged: (v) => setState(() {
                      _query = v.trim().toLowerCase();
                      _page = 0;
                    }),
                  ),
                  if (_segment == 'accounts') ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item in [
                          (id: 'all', label: 'Tất cả'),
                          ...AppRole.values.map(
                            (r) => (id: r.name, label: r.label),
                          ),
                        ])
                          ChoiceChip(
                            label: Text(item.label),
                            selected: _role == item.id,
                            onSelected: (_) => setState(() {
                              _role = item.id;
                              _page = 0;
                            }),
                          ),
                        FilterChip(
                          label: const Text('Đang khóa'),
                          selected: _lockedOnly,
                          onSelected: (v) => setState(() {
                            _lockedOnly = v;
                            _page = 0;
                          }),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_segment == 'members')
              ..._members(context)
            else ...[
              AdminSection(
                'Danh sách tài khoản',
                caption: '${matched.length} tài khoản phù hợp',
              ),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  auth.isCloudMode)
                const LinearProgressIndicator(),
              if (snapshot.hasError)
                AdminPanel(
                  child: Column(
                    children: [
                      const Text(
                        'Không đọc được tài khoản. Kiểm tra kết nối và quyền admin.',
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _accounts = loadAdminAccounts()),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              if (auth.isCloudMode)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Khóa tài khoản sẽ tạm chặn quyền truy cập ứng dụng; hợp đồng và lịch sử vẫn được giữ.',
                    style: TextStyle(color: adminMuted, fontSize: 12),
                  ),
                ),
              if (accounts != null && matched.isEmpty)
                const AdminPanel(
                  child: Text(
                    'Không có tài khoản phù hợp. Thử tên hoặc vai trò khác.',
                  ),
                ),
              for (final account in matched.skip(page * 12).take(12))
                _account(context, account),
              ListPagination(
                total: matched.length,
                page: page,
                pageSize: 12,
                onChanged: (v) => setState(() => _page = v),
              ),
            ],
          ],
        );
      },
    ),
  );

  Widget _count(
    String value,
    String label,
    IconData icon, {
    Color color = adminBlue,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(child: Icon(icon, color: color, size: 22)),
      const SizedBox(height: 10),
      Text(
        value,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: adminInk,
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: adminMuted)),
    ],
  );

  Color _roleColor(String role) => role == 'landlord' ? adminTeal : adminBlue;

  Widget _account(BuildContext context, AdminAccount account) => AdminPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: account.disabled
                  ? adminOrange.withValues(alpha: 0.08)
                  : _roleColor(account.role).withValues(alpha: 0.1),
              foregroundColor: account.disabled
                  ? adminOrange
                  : _roleColor(account.role),
              child: Icon(
                account.role == 'landlord'
                    ? Icons.apartment_outlined
                    : account.role == 'admin'
                    ? Icons.admin_panel_settings_outlined
                    : Icons.person_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: adminInk,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    account.email.isEmpty ? account.id : account.email,
                    style: const TextStyle(color: adminMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AdminStatus(
              AppRole.values
                      .where((r) => r.name == account.role)
                      .firstOrNull
                      ?.label ??
                  account.role,
              color: _roleColor(account.role),
            ),
            AdminStatus(
              account.disabled ? 'Đang khóa' : 'Hoạt động',
              color: account.disabled ? adminOrange : adminGreen,
            ),
            if (account.role != 'admin')
              OutlinedButton(
                onPressed:
                    LocalAuth.instance.role != AppRole.admin ||
                        _updatingAccounts.contains(account.id)
                    ? null
                    : () async {
                        final disabled = !account.disabled;
                        if (!await adminConfirm(
                          context,
                          disabled ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?',
                          '${account.email}\n${disabled ? 'Tài khoản sẽ không đăng nhập được cho đến khi mở khóa.' : 'Tài khoản có thể đăng nhập trở lại.'}',
                        )) {
                          return;
                        }
                        if (!context.mounted) return;
                        setState(() => _updatingAccounts.add(account.id));
                        try {
                          if (LocalAuth.instance.isCloudMode) {
                            await setAdminAccountDisabled(account.id, disabled);
                            if (!mounted) return;
                            setState(() => _accounts = loadAdminAccounts());
                          } else {
                            LocalAuth.instance.setDisabled(
                              AppRole.values.byName(account.role),
                              disabled,
                            );
                          }
                          AdminStore.instance.record(
                            '${disabled ? 'Khóa' : 'Mở khóa'} tài khoản ${account.email}',
                          );
                        } on ArgumentError catch (e) {
                          if (context.mounted) {
                            adminMessage(context, '${e.message}');
                          }
                        } catch (_) {
                          if (context.mounted) {
                            adminMessage(
                              context,
                              'Chưa cập nhật được tài khoản. Kiểm tra kết nối và quyền Firebase.',
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(
                              () => _updatingAccounts.remove(account.id),
                            );
                          }
                        }
                      },
                child: _updatingAccounts.contains(account.id)
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Đang cập nhật'),
                        ],
                      )
                    : Text(account.disabled ? 'Mở khóa' : 'Khóa tài khoản'),
              ),
          ],
        ),
      ],
    ),
  );

  List<Widget> _members(BuildContext context) {
    if (_house != 'all' && portfolio.byId(_house) == null) _house = 'all';
    final entries = [
      for (final store in portfolio.stores)
        for (final member in store.members)
          if ((_house == 'all' || store.property.id == _house) &&
              '${member.name} ${member.phone} ${store.leaseById(member.leaseId)?.room ?? ''}'
                  .toLowerCase()
                  .contains(_query))
            (store: store, member: member),
    ];
    final page = _page.clamp(0, ListPagination.lastPage(entries.length, 12));
    final visible = entries.skip(page * 12).take(12).toList();
    return [
      DropdownButtonFormField<String>(
        initialValue: _house,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Nhà trọ'),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('Tất cả nhà trọ')),
          for (final s in portfolio.stores)
            DropdownMenuItem(
              value: s.property.id,
              child: Text(s.property.name),
            ),
        ],
        onChanged: (v) => setState(() {
          _house = v ?? 'all';
          _page = 0;
        }),
      ),
      const SizedBox(height: 16),
      Text(
        '${entries.length} hồ sơ phù hợp',
        style: const TextStyle(color: adminMuted, fontSize: 12),
      ),
      const SizedBox(height: 12),
      if (entries.isEmpty)
        const AdminPanel(
          child: Text('Không tìm thấy hồ sơ. Thử nhà trọ hoặc từ khóa khác.'),
        ),
      if (visible.isNotEmpty)
        AdminPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              for (final e in visible) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _memberDetails(context, e.store, e.member),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: e.member.isRepresentative
                              ? adminBlue.withValues(alpha: 0.08)
                              : adminTeal.withValues(alpha: 0.08),
                          foregroundColor: e.member.isRepresentative
                              ? adminBlue
                              : adminTeal,
                          child: Text(
                            e.member.name.isEmpty
                                ? '?'
                                : e.member.name.substring(0, 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.member.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: adminInk,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Phòng ${e.store.leaseById(e.member.leaseId)?.room ?? '—'} · ${e.store.property.name}',
                                style: const TextStyle(
                                  color: adminMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  Text(
                                    e.member.phone,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: adminMuted,
                                    ),
                                  ),
                                  AdminStatus(
                                    e.member.status == LeaseMemberStatus.active
                                        ? 'Đang ở'
                                        : e.member.status ==
                                              LeaseMemberStatus.pending
                                        ? 'Chờ duyệt'
                                        : 'Từ chối',
                                    color:
                                        e.member.status ==
                                            LeaseMemberStatus.active
                                        ? adminGreen
                                        : e.member.status ==
                                              LeaseMemberStatus.pending
                                        ? adminGold
                                        : adminOrange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: adminMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (e != visible.last)
                  const Divider(height: 1, indent: 52, color: adminLine),
              ],
            ],
          ),
        ),
      ListPagination(
        total: entries.length,
        page: page,
        pageSize: 12,
        onChanged: (v) => setState(() => _page = v),
      ),
    ];
  }

  Future<void> _memberDetails(
    BuildContext context,
    LandlordDemoStore store,
    LeaseMember member,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              member.name,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: adminInk,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: Text(member.phone),
              subtitle: const Text('Số điện thoại'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.apartment_outlined),
              title: Text(store.property.name),
              subtitle: Text(
                'Phòng ${store.leaseById(member.leaseId)?.room ?? '—'}',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(landlordDate(member.joinedAt)),
              subtitle: const Text('Ngày vào ở'),
            ),
            Text(
              member.isRepresentative
                  ? 'Người đại diện hợp đồng'
                  : 'Thành viên phòng',
              style: const TextStyle(color: adminBlue),
            ),
            if (LocalAuth.instance.role == AppRole.admin) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Sửa hồ sơ'),
                onPressed: () async {
                  final name = await adminInput(
                    context,
                    title: 'Sửa hồ sơ',
                    label: 'Họ tên',
                    initial: member.name,
                  );
                  if (name == null || !context.mounted) return;
                  final phone = await adminInput(
                    context,
                    title: 'Sửa hồ sơ',
                    label: 'Số điện thoại',
                    initial: member.phone,
                    numeric: true,
                  );
                  if (phone == null || !context.mounted) return;
                  try {
                    AdminStore.instance.editMemberContact(
                      store.property.id,
                      member.id,
                      name,
                      phone,
                    );
                    Navigator.pop(context);
                    await AppPersistence.current?.saveAdminChanges();
                  } on ArgumentError catch (e) {
                    if (mounted) adminMessage(this.context, '${e.message}');
                  } on StateError catch (e) {
                    if (mounted) adminMessage(this.context, e.message);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _activity(BuildContext context, List<AdminAccount>? accounts) {
    final auth = LocalAuth.instance;
    final count = auth.role != null && auth.isForeground ? 1 : 0;
    return AdminFrame(
      title: 'Hoạt động ứng dụng',
      subtitle: 'Theo dõi phiên sử dụng và tình trạng tài khoản.',
      children: [
        const AdminSyncBar(),
        AdminPanel(
          backgroundColor: const Color(0xFF0F2537),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B192C),
              Color(0xFF0F2942),
              Color(0xFF0369A1),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.sensors_rounded, color: Color(0xFF2DD4BF)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Thiết bị hiện tại',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                count == 1
                    ? 'Phiên đăng nhập đang hoạt động'
                    : 'Chưa có phiên đang hoạt động',
                style: const TextStyle(color: Color(0xFFBAE6FD), fontSize: 13),
              ),
            ],
          ),
        ),
        const AdminPanel(
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline_rounded, color: adminBlue),
            title: Text('Phạm vi thống kê'),
            subtitle: Text(
              'Số online toàn hệ thống chưa khả dụng',
              style: TextStyle(fontSize: 12, color: adminMuted),
            ),
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Chỉ đếm phiên đăng nhập trên thiết bị đang dùng. Không suy ra số online từ số tài khoản hay lần đăng nhập gần nhất.',
                ),
              ),
            ],
          ),
        ),
        const AdminSection('Phân bố tài khoản'),
        for (final role in AppRole.values)
          AdminPanel(
            child: Row(
              children: [
                Icon(role.icon, color: adminBlue),
                const SizedBox(width: 12),
                Expanded(child: Text(role.label)),
                Text(
                  '${accounts?.where((a) => a.role == role.name).length ?? '—'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: adminInk,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
