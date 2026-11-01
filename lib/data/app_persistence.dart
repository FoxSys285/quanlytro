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

class AppPersistence {
  AppPersistence(this.repository);
  final RentalRepository repository;
  static AppPersistence? current;
  final error = ValueNotifier<String?>(null);
  Future<void> _pending = Future.value();
  bool _scheduled = false;
  bool _disposed = false;
  final _subscriptions = <Listenable>{};

  Future<void> initialize() async {
    final data = await repository.readAll();
    await LocalAuth.instance.initialize(data['auth']);
    if (data['admin'] != null) AdminStore.instance.restore(data['admin']!);
    final saved = data['portfolio'];
    RentalPortfolio.instance = saved == null
        ? RentalPortfolio.seeded()
        : RentalPortfolio.fromMap(saved);
    LandlordDemoStore.instance =
        RentalPortfolio.instance.byId('may') ??
        RentalPortfolio.instance.stores.first;
    ConversationStore.instance.dispose();
    AccountStore.instance.dispose();
    ViewingStore.instance.dispose();
    ConversationStore.instance = ConversationStore.demo();
    AccountStore.instance = AccountStore(rental: LandlordDemoStore.instance);
    ViewingStore.instance = ViewingStore.demo(
      rental: LandlordDemoStore.instance,
    );
    AnnouncementStore.reset();
    final conversations = ConversationStore.instance;
    final viewings = ViewingStore.instance;
    if (data['viewings'] == null) {
      viewings.seedPortfolio(RentalPortfolio.instance);
    }
    final accounts = AccountStore.instance;
    final staff = LandlordStaffStore.instance;
    if (data['conversations'] != null) {
      conversations.restore(data['conversations']!);
    }
    if (data['viewings'] != null) viewings.restore(data['viewings']!);
    if (data['accounts'] != null) accounts.restore(data['accounts']!);
    if (data['staff'] != null) staff.restore(data['staff']!);
    TenantFavoritesStore.roomNames
      ..clear()
      ..addAll(List<String>.from(data['favorites']?['ids'] as List? ?? []));
    for (final store in RentalPortfolio.instance.stores) {
      final announcements = AnnouncementStore.forRental(store);
      final stored = data['announcements:${store.property.id}'];
      if (stored != null) announcements.restore(stored);
    }
    await repository.saveAll(_snapshot());
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
        try {
          await repository.saveAll(snapshot);
          error.value = null;
        } catch (_) {
          error.value =
              'Chưa lưu được dữ liệu trên thiết bị. Vui lòng thử lại.';
        }
      });
    });
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
    if (current == this) current = null;
  }
}
