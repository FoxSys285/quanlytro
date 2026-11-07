import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/local_auth.dart';
import '../../layouts/role_layout.dart';
import '../shared/widgets/list_pagination.dart';
import 'admin_ui.dart';

typedef _AdminAccountRow = ({
  String id,
  String email,
  String name,
  String role,
  bool disabled,
});

class AdminAccountsPage extends StatefulWidget {
  const AdminAccountsPage({super.key});

  @override
  State<AdminAccountsPage> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsPage> {
  static const _pageSize = 10;
  String _role = 'all';
  int _page = 0;
  int _total = 0;
  bool _loading = true;
  Object? _error;
  bool _hasMore = false;
  List<_AdminAccountRow> _rows = const [];
  final _busyIds = <String>{};
  final Map<int, DocumentSnapshot<Map<String, dynamic>>?> _cursors = {0: null};

  @override
  void initState() {
    super.initState();
    _loadPage(refreshCount: true);
  }

  Future<void> _loadPage({bool refreshCount = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = LocalAuth.instance;
      if (!auth.isCloudMode) {
        final all = auth.localAccounts
            .where((account) => _role == 'all' || account.role.name == _role)
            .toList();
        final lastPage = ListPagination.lastPage(all.length, _pageSize);
        _page = _page.clamp(0, lastPage);
        final pageRows = all.skip(_page * _pageSize).take(_pageSize);
        if (!mounted) return;
        setState(() {
          _total = all.length;
          _rows = [
            for (final account in pageRows)
              (
                id: account.email,
                email: account.email,
                name: account.role.label,
                role: account.role.name,
                disabled: account.disabled,
              ),
          ];
          _hasMore = (_page + 1) * _pageSize < _total;
          _loading = false;
        });
        return;
      }
      if (auth.role != AppRole.admin) {
        throw StateError('Đăng nhập bằng tài khoản quản trị để xem hồ sơ.');
      }
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'users',
      );
      if (_role != 'all') query = query.where('role', isEqualTo: _role);

      if (refreshCount) {
        final aggregate = await query.count().get();
        _total = aggregate.count ?? 0;
      }

      query = query.orderBy(FieldPath.documentId);
      final after = _cursors[_page];
      if (after != null) query = query.startAfterDocument(after);
      final snapshot = await query.limit(_pageSize).get();
      final rows = [
        for (final document in snapshot.docs)
          (
            id: document.id,
            email: document.data()['email'] as String? ?? '',
            name: document.data()['displayName'] as String? ?? document.id,
            role: document.data()['role'] as String? ?? 'unknown',
            disabled: document.data()['disabled'] == true,
          ),
      ];
      if (snapshot.docs.isNotEmpty) {
        _cursors[_page + 1] = snapshot.docs.last;
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _hasMore =
            snapshot.docs.length == _pageSize &&
            (_page + 1) * _pageSize < _total;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _selectRole(String role) {
    setState(() {
      _role = role;
      _page = 0;
      _total = 0;
      _cursors
        ..clear()
        ..[0] = null;
    });
    _loadPage(refreshCount: true);
  }

  Future<void> _goToPage(int page) async {
    if (page < 0 || page == _page) return;
    setState(() => _page = page);
    await _loadPage();
  }

  Future<void> _setDisabled(_AdminAccountRow account) async {
    if (!await adminConfirm(
      context,
      account.disabled ? 'Mở khóa tài khoản?' : 'Khóa tài khoản?',
      account.disabled
          ? 'Tài khoản này sẽ có thể đăng nhập và sử dụng ứng dụng.'
          : 'Tài khoản này sẽ tạm thời không thể truy cập ứng dụng.',
    )) {
      return;
    }
    setState(() => _busyIds.add(account.id));
    try {
      final auth = LocalAuth.instance;
      if (auth.isCloudMode) {
        if (auth.role != AppRole.admin ||
            auth.session == null ||
            account.id == auth.session!.uid) {
          throw StateError('Không thể thay đổi tài khoản quản trị hiện tại.');
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(account.id)
            .update({'disabled': !account.disabled});
      } else {
        final role = AppRole.values.firstWhere(
          (role) => role.name == account.role,
        );
        auth.setDisabled(role, !account.disabled);
      }
      await _loadPage();
      if (mounted) {
        adminMessage(
          context,
          account.disabled ? 'Đã mở khóa tài khoản.' : 'Đã khóa tài khoản.',
        );
      }
    } catch (error) {
      if (mounted) adminMessage(context, error.toString());
    } finally {
      if (mounted) setState(() => _busyIds.remove(account.id));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: LocalAuth.instance,
    builder: (context, _) => AdminFrame(
      title: 'Tài khoản người dùng',
      subtitle: 'Lọc theo vai trò và quản lý trạng thái truy cập. Mỗi lượt chỉ tải tối đa 10 tài khoản.',
      children: [
        const AdminSyncBar(),
        AdminPanel(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      (id: 'all', label: 'Tất cả vai trò'),
                      (id: 'admin', label: 'Quản trị'),
                      (id: 'landlord', label: 'Chủ trọ'),
                      (id: 'tenant', label: 'Người thuê'),
                    ]
                    .map(
                      (option) => ChoiceChip(
                        label: Text(option.label),
                        selected: _role == option.id,
                        onSelected: (_) => _selectRole(option.id),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 8),
        AdminSection(
          'Danh sách tài khoản',
          caption: '$_total tài khoản · tối đa $_pageSize dòng mỗi lần tải',
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          AdminPanel(
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: adminOrange,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  'Không thể tải danh sách: $_error',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => _loadPage(refreshCount: _total == 0),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          )
        else if (!_loading && _rows.isEmpty)
          const AdminPanel(child: Text('Không có tài khoản trong bộ lọc này.')),
        for (final account in _rows) _accountCard(account),
        if (_total > _pageSize || _page > 0)
          ListPagination(
            total: _total,
            page: _page,
            pageSize: _pageSize,
            onChanged: (value) {
              if (LocalAuth.instance.isCloudMode &&
                  value > _page &&
                  !_hasMore) {
                return;
              }
              _goToPage(value);
            },
          ),
      ],
    ),
  );

  Widget _accountCard(_AdminAccountRow account) {
    final role = AppRole.values
        .where((item) => item.name == account.role)
        .firstOrNull;
    final color = account.role == 'landlord'
        ? adminTeal
        : account.role == 'admin'
        ? adminPurple
        : adminBlue;
    final isSelf = LocalAuth.instance.session?.uid == account.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdminPanel(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .1),
              foregroundColor: color,
              child: Icon(role?.icon ?? Icons.person_outline_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      color: adminInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    account.email.isEmpty ? account.id : account.email,
                    style: const TextStyle(color: adminMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      AdminStatus(role?.label ?? account.role, color: color),
                      AdminStatus(
                        account.disabled ? 'Đã khóa' : 'Hoạt động',
                        color: account.disabled ? adminOrange : adminGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (account.role != 'admin')
              IconButton(
                tooltip: account.disabled
                    ? 'Mở khóa tài khoản'
                    : 'Khóa tài khoản',
                onPressed: isSelf || _busyIds.contains(account.id)
                    ? null
                    : () => _setDisabled(account),
                icon: _busyIds.contains(account.id)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        account.disabled
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        color: account.disabled ? adminGreen : adminOrange,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
