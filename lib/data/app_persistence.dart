import 'dart:async';

import 'package:flutter/foundation.dart';

import '../pages/landlord/landlord_demo_store.dart';
import '../pages/landlord/staff/landlord_staff_store.dart';
import '../pages/shared/announcements/announcement_store.dart';
import '../pages/shared/conversations/conversation_store.dart';
import '../pages/shared/profile/account_store.dart';
import '../pages/shared/viewings/viewing_store.dart';
import '../pages/tenant/discovery/tenant_favorites_store.dart';
import 'local_database.dart';
import 'local_auth.dart';
import 'admin_store.dart';
import 'firestore_repository.dart';
import '../layouts/role_layout.dart';

class AppPersistence {
  AppPersistence(this.repository, {this.cloudMode = false});
  final RentalRepository repository;
  final bool cloudMode;
  static AppPersistence? current;
  final error = ValueNotifier<String?>(null);
  bool cloudConfirmed = false;
  final saveStatus = ValueNotifier<String>(
    'Chỉnh sửa trực tiếp dữ liệu đang dùng',
  );
  Future<void> _pending = Future.value();
  bool _scheduled = false;
  bool _disposed = false;
  final _subscriptions = <Listenable>{};
  Future<void> initialize() async {
    final data = await repository.readAll();
    final saved = data['portfolio'];
    if (saved == null || (!cloudMode && data['auth'] == null)) {
      throw StateError(
        'Chưa tải được dữ liệu đã lưu. Kiểm tra Firebase hoặc bản lưu trên máy rồi mở lại ứng dụng.',
      );
    }
    await LocalAuth.instance.initialize(data['auth']);
    AdminStore.instance.restore(
      data['admin'] ??
          {
            'verified': <String, bool>{},
            'hidden': <String>[],
            'tickets': <dynamic>[],
            'logs': <dynamic>[],
            'acceptingViewings': true,
          },
    );
    RentalPortfolio.instance = RentalPortfolio.fromMap(saved);
    LandlordDemoStore.instance = cloudMode
        ? RentalPortfolio.instance.active
        : RentalPortfolio.instance.byId('may') ??
              RentalPortfolio.instance.stores.first;
    ConversationStore.instance.dispose();
    AccountStore.instance.dispose();
    ViewingStore.instance.dispose();
    ConversationStore.instance = ConversationStore();
    AccountStore.instance = AccountStore(rental: LandlordDemoStore.instance);
    ViewingStore.instance = ViewingStore(
      [],
      rental: LandlordDemoStore.instance,
    );
    AnnouncementStore.reset();
    final conversations = ConversationStore.instance;
    final viewings = ViewingStore.instance;
    final accounts = AccountStore.instance;
    final staff = LandlordStaffStore.instance;
    if (data['conversations'] != null) {
      conversations.restore(data['conversations']!);
    }
    if (data['viewings'] != null) viewings.restore(data['viewings']!);
    if (data['accounts'] != null) accounts.restore(data['accounts']!);
    staff.restore(data['staff'] ?? {'nextId': 1, 'staff': <dynamic>[]});
    TenantFavoritesStore.roomNames
      ..clear()
      ..addAll(List<String>.from(data['favorites']?['ids'] as List? ?? []));
    for (final store in RentalPortfolio.instance.stores) {
      final announcements = AnnouncementStore.forRental(store);
      final stored = data['announcements:${store.property.id}'];
      announcements.restore(
        stored ??
            {
              'sent': <dynamic>[],
              'recipients': <String, dynamic>{},
              'readByTenant': <String, dynamic>{},
              'landlordRead': <String>[],
              'nextId': 1,
            },
      );
    }
    if (!cloudMode) await repository.saveAll(_snapshot());
    for (final store in RentalPortfolio.instance.stores) {
      _listen(AnnouncementStore.forRental(store));
    }
    _listen(RentalPortfolio.instance);
    _listen(conversations);
    _listen(viewings);
    _listen(accounts);
    _listen(staff);
    _listen(TenantFavoritesStore.changes);
    _listen(LocalAuth.instance);
    _listen(AdminStore.instance);
    current = this;
  }

  void _listen(Listenable source) {
    if (_subscriptions.add(source)) source.addListener(save);
  }

  Map<String, Map<String, dynamic>> _snapshot() => {
    'portfolio': RentalPortfolio.instance.toMap(),
    'conversations': ConversationStore.instance.toMap(),
    'viewings': ViewingStore.instance.toMap(),
    'accounts': AccountStore.instance.toMap(),
    'staff': LandlordStaffStore.instance.toMap(),
    'favorites': {'ids': TenantFavoritesStore.roomNames.toList()},
    'auth': LocalAuth.instance.toMap(),
    'admin': AdminStore.instance.toMap(),
    for (final store in RentalPortfolio.instance.stores)
      'announcements:${store.property.id}': AnnouncementStore.forRental(store)
          .toMap(),
  };

  void save() {
    if (_disposed || _scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (_disposed) return;
      for (final store in RentalPortfolio.instance.stores) {
        _listen(AnnouncementStore.forRental(store));
      }
      final snapshot = _snapshot();
      _pending = _pending.then((_) async {
        cloudConfirmed = false;
        saveStatus.value = 'Đang lưu dữ liệu…';
        try {
          final target = repository;
          if (target is HybridRentalRepository) {
            await target.saveAll(
              snapshot,
              requireRemote: LocalAuth.instance.role == AppRole.admin,
            );
          } else {
            await target.saveAll(snapshot);
          }
          error.value = null;
          cloudConfirmed =
              cloudMode ||
              (target is HybridRentalRepository &&
                  target.lastSaveReachedRemote);
          saveStatus.value = cloudConfirmed
              ? 'Đã lưu dữ liệu lên Firebase'
              : 'Đã lưu trên máy · Firebase chưa kết nối';
        } catch (_) {
          error.value = 'Chưa hoàn tất lưu dữ liệu. Kiểm tra kết nối/quyền Firebase rồi thử lại.';
          saveStatus.value = error.value!;
        }
      });
    });
  }

  Future<void> saveAdminChanges() async {
    if (_disposed || LocalAuth.instance.role != AppRole.admin) {
      throw ArgumentError('Chỉ quản trị viên được lưu thay đổi này.');
    }
    save();
    await flush();
    if (error.value != null) throw StateError(error.value!);
    if (repository is! HybridRentalRepository && !cloudMode) {
      throw StateError('Đã lưu trên máy nhưng chưa có kết nối Firebase.');
    }
  }

  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
    await _pending;
  }

  Future<void> dispose() async {
    await flush();
    _disposed = true;
    for (final source in _subscriptions) {
      source.removeListener(save);
    }
    _subscriptions.clear();
    await repository.close();
    error.dispose();
    saveStatus.dispose();
    if (current == this) current = null;
  }
}
