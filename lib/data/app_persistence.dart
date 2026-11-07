import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

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
import 'scoped_firestore_repository.dart';
import 'rental_cloud_codec.dart';
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
  bool _restoring = false;
  bool _dirty = false;
  bool _remoteChanged = false;
  bool _initialSyncCompleted = false;
  bool _initialSyncFailed = false;
  Timer? _refreshTimer;
  StreamSubscription<void>? _remoteSubscription;
  final refreshing = ValueNotifier<bool>(false);
  String? _remoteFingerprint;
  final _subscriptions = <Listenable>{};
  bool get isDisposed => _disposed;
  bool get initialSyncCompleted => _initialSyncCompleted;
  bool get initialSyncFailed => _initialSyncFailed;

  /// Khởi tạo nhanh (bất đồng bộ) cho phiên đăng nhập Cloud để vào giao diện ngay lập tức,
  /// sau đó tải và đồng bộ dữ liệu từ Firestore trong nền mà không làm treo hoặc văng ứng dụng.
  Future<void> initializeAsync() async {
    _restoring = true;
    _initialSyncCompleted = false;
    _initialSyncFailed = false;
    refreshing.value = true;
    try {
      await LocalAuth.instance.initialize(null);
      AdminStore.instance.restore({
        'verified': <String, bool>{},
        'hidden': <String>[],
        'tickets': <dynamic>[],
        'logs': <dynamic>[],
        'acceptingViewings': true,
      });
      LandlordDemoStore.instance = LandlordDemoStore.empty();
      RentalPortfolio.instance = RentalPortfolio([]);
      LandlordDemoStore.instance = RentalPortfolio.instance.active;
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
      LandlordStaffStore.instance.restore({'nextId': 1, 'staff': <dynamic>[]});
      TenantFavoritesStore.roomNames.clear();
      for (final store in RentalPortfolio.instance.stores) {
        final announcements = AnnouncementStore.forRental(store);
        announcements.restore({
          'sent': <dynamic>[],
          'recipients': <String, dynamic>{},
          'readByTenant': <String, dynamic>{},
          'landlordRead': <String>[],
          'nextId': 1,
        });
        _listen(announcements);
      }
      _listen(RentalPortfolio.instance);
      _listen(ConversationStore.instance);
      _listen(ViewingStore.instance);
      _listen(AccountStore.instance);
      _listen(LandlordStaffStore.instance);
      _listen(TenantFavoritesStore.changes);
      if (!cloudMode) _listen(LocalAuth.instance);
      _listen(AdminStore.instance);
      current = this;
      error.value = null;
      saveStatus.value = 'Đang đồng bộ dữ liệu từ Firebase…';
    } finally {
      _restoring = false;
    }
    unawaited(_syncFromCloudInBackground());
  }

  Future<void> _syncFromCloudInBackground() async {
    if (_disposed) return;
    refreshing.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_disposed) return;
      final data = await repository.readAll();
      if (_disposed) return;
      await Future<void>.delayed(Duration.zero);
      if (_disposed) return;
      _restoring = true;
      try {
        if (data['portfolio'] != null) {
          RentalPortfolio.instance.restore(data['portfolio']!);
          if (!RentalPortfolio.instance.stores.contains(
            LandlordDemoStore.instance,
          )) {
            LandlordDemoStore.instance = RentalPortfolio.instance.active;
          }
          AccountStore.instance.rebindRental(LandlordDemoStore.instance);
        }
        if (data['admin'] != null) {
          AdminStore.instance.restore(data['admin']!);
        }
        if (data['conversations'] != null) {
          ConversationStore.instance.restore(data['conversations']!);
        }
        if (data['viewings'] != null) {
          ViewingStore.instance.restore(data['viewings']!);
        }
        AccountStore.instance.restore(
          data['accounts'] ?? {'contacts': {}, 'notifications': {}},
        );
        if (data['staff'] != null) {
          LandlordStaffStore.instance.restore(data['staff']!);
        }
        TenantFavoritesStore.roomNames
          ..clear()
          ..addAll(List<String>.from(data['favorites']?['ids'] as List? ?? []));
        TenantFavoritesStore.changes.value++;
        for (final store in RentalPortfolio.instance.stores) {
          final announcements = AnnouncementStore.forRental(store);
          final stored = data['announcements:${store.property.id}'];
          if (stored != null) {
            announcements.restore(stored);
          }
          _listen(announcements);
        }
        _dirty = false;
        _initialSyncCompleted = true;
        _initialSyncFailed = false;
        cloudConfirmed = true;
        error.value = null;
        saveStatus.value = 'Đã đồng bộ dữ liệu từ Firebase';
      } finally {
        _restoring = false;
      }
      if (!_disposed && cloudMode && repository is RentalChangeSource) {
        await _remoteSubscription?.cancel();
        _remoteSubscription = (repository as RentalChangeSource).changes.listen(
          (_) => _scheduleRefresh(),
          onError: (Object failure) {
            _closeRevokedSession(failure);
            error.value = 'Không thể nhận dữ liệu mới từ Firebase. Kiểm tra kết nối và quyền tài khoản.';
          },
        );
      }
      final scopedRepository = repository;
      if (!_disposed &&
          scopedRepository is ScopedFirestoreRentalRepository &&
          scopedRepository.needsSchemaMigration &&
          LocalAuth.instance.role == AppRole.landlord) {
        save();
      }
    } catch (failure, stackTrace) {
      debugPrint('Background cloud sync warning: $failure\n$stackTrace');
      if (!_disposed) {
        _closeRevokedSession(failure);
        _initialSyncCompleted = false;
        _initialSyncFailed = true;
        error.value = null;
        saveStatus.value = 'Chưa tải được dữ liệu Firebase · Thử kết nối lại';
      }
    } finally {
      if (!_disposed) {
        refreshing.value = false;
      }
    }
  }

  Future<void> retryInitialSync() async {
    if (_disposed || _initialSyncCompleted) return;
    _initialSyncFailed = false;
    refreshing.value = true;
    saveStatus.value = 'Đang thử đồng bộ lại dữ liệu Firebase…';
    await _syncFromCloudInBackground();
  }

  Future<void> initialize() async {
    final data = await repository.readAll();
    _remoteFingerprint = cloudFingerprint(data);
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
    TenantFavoritesStore.changes.value++;
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
    if (!cloudMode) _listen(LocalAuth.instance);
    _listen(AdminStore.instance);
    _initialSyncCompleted = true;
    current = this;
    if (cloudMode) {
      cloudConfirmed = true;
      saveStatus.value = 'Đã đồng bộ dữ liệu từ Firebase';
    }
    if (cloudMode && repository is RentalChangeSource) {
      _remoteSubscription = (repository as RentalChangeSource).changes.listen(
        (_) => _scheduleRefresh(),
        onError: (Object failure) {
          _closeRevokedSession(failure);
          error.value = 'Không thể nhận dữ liệu mới từ Firebase. Kiểm tra kết nối/quyền tài khoản.';
        },
      );
    }
    final scopedRepository = repository;
    if (scopedRepository is ScopedFirestoreRentalRepository &&
        scopedRepository.needsSchemaMigration &&
        LocalAuth.instance.role == AppRole.landlord) {
      // Save the normalized model through the signed-in owner's normal
      // Firestore permissions; unrelated users and Firebase collections are
      // left untouched.
      save();
    }
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
    if (_disposed || _restoring || (cloudMode && !_initialSyncCompleted)) {
      return;
    }
    _dirty = true;
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (_disposed || (cloudMode && !_initialSyncCompleted)) return;
      for (final store in RentalPortfolio.instance.stores) {
        _listen(AnnouncementStore.forRental(store));
      }
      final snapshot = _snapshot();
      _pending = _pending.then((_) async {
        if (_disposed) return;
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
          if (_disposed) return;
          error.value = null;
          cloudConfirmed =
              cloudMode ||
              (target is HybridRentalRepository &&
                  target.lastSaveReachedRemote);
          saveStatus.value = cloudConfirmed
              ? 'Đã lưu dữ liệu lên Firebase'
              : 'Đã lưu trên máy · Firebase chưa kết nối';
          _dirty = false;
          if (_remoteChanged) _scheduleRefresh();
        } catch (failure) {
          if (_disposed) return;
          _closeRevokedSession(failure);
          error.value = 'Chưa hoàn tất lưu dữ liệu. Kiểm tra kết nối/quyền Firebase rồi thử lại.';
          saveStatus.value = error.value!;
        }
      });
    });
  }

  /// Waits for the queued local and Firebase write, so editors can report a
  /// remote failure before closing and losing the user's draft context.
  Future<void> flush() async {
    if (_disposed) throw StateError('Phiên lưu dữ liệu đã đóng.');
    if (cloudMode && !_initialSyncCompleted) {
      throw StateError(
        'Đang tải dữ liệu Firebase. Vui lòng lưu lại sau ít phút.',
      );
    }
    if (_dirty && !_scheduled) save();
    if (_scheduled) await Future<void>.delayed(Duration.zero);
    await _pending;
    if (error.value != null) throw StateError(error.value!);
    if (_dirty || _scheduled) {
      throw StateError('Dữ liệu chưa được lưu. Vui lòng thử lại.');
    }
  }

  void _scheduleRefresh() {
    if (_disposed) return;
    _remoteChanged = true;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(refresh());
    });
  }

  /// Không thay bản chỉnh sửa chưa lưu bằng dữ liệu thiết bị khác.
  Future<void> refresh({bool discardUnsaved = false}) async {
    if (_disposed || !cloudMode || !_initialSyncCompleted || refreshing.value) {
      return;
    }
    _pending = _pending.then((_) async {
      if (_disposed || _scheduled || (_dirty && !discardUnsaved)) return;
      if (discardUnsaved) _remoteFingerprint = null;
      refreshing.value = true;
      _remoteChanged = false;
      try {
        final data = await repository.readAll();
        if (_disposed) return;
        final fingerprint = cloudFingerprint(data);
        if (fingerprint == _remoteFingerprint) return;
        _restoring = true;
        try {
          RentalPortfolio.instance.restore(data['portfolio']!);
          if (!RentalPortfolio.instance.stores.contains(
            LandlordDemoStore.instance,
          )) {
            LandlordDemoStore.instance = RentalPortfolio.instance.active;
          }
          AccountStore.instance.rebindRental(LandlordDemoStore.instance);
          AdminStore.instance.restore(data['admin']!);
          ConversationStore.instance.restore(data['conversations']!);
          ViewingStore.instance.restore(data['viewings']!);
          AccountStore.instance.restore(
            data['accounts'] ?? {'contacts': {}, 'notifications': {}},
          );
          LandlordStaffStore.instance.restore(data['staff']!);
          TenantFavoritesStore.roomNames
            ..clear()
            ..addAll(
              List<String>.from(data['favorites']?['ids'] as List? ?? []),
            );
          for (final store in RentalPortfolio.instance.stores) {
            final announcements = AnnouncementStore.forRental(store);
            announcements.restore(data['announcements:${store.property.id}']!);
            _listen(announcements);
          }
          _remoteFingerprint = fingerprint;
          _dirty = false;
          error.value = null;
          saveStatus.value = 'Đã nhận dữ liệu mới từ Firebase';
        } finally {
          _restoring = false;
        }
      } catch (failure) {
        if (_disposed) return;
        _closeRevokedSession(failure);
        _remoteChanged = true;
        error.value = 'Chưa tải được dữ liệu mới. Kiểm tra kết nối/quyền Firebase rồi thử lại.';
      } finally {
        if (!_disposed) {
          refreshing.value = false;
        }
      }
    });
    await _pending;
  }

  void _closeRevokedSession(Object failure) {
    if (cloudMode &&
        LocalAuth.instance.isCloudMode &&
        failure is FirebaseException &&
        ['unauthenticated', 'permission-denied'].contains(failure.code)) {
      // A revoked or denied profile must not keep showing private cached data.
      scheduleMicrotask(() => unawaited(LocalAuth.instance.signOut()));
    }
  }

  Future<void> saveAdminChanges() async {
    if (_disposed || LocalAuth.instance.role != AppRole.admin) {
      throw ArgumentError('Chỉ quản trị viên được lưu thay đổi này.');
    }
    if (cloudMode && !_initialSyncCompleted) {
      throw StateError('Chưa tải xong dữ liệu Firebase. Vui lòng thử lại.');
    }
    if (cloudMode && !_dirty) {
      await refresh(discardUnsaved: true);
      if (error.value != null) throw StateError(error.value!);
      return;
    }
    save();
    await flush();
    if (error.value != null) throw StateError(error.value!);
    if (repository is! HybridRentalRepository && !cloudMode) {
      throw StateError('Đã lưu trên máy nhưng chưa có kết nối Firebase.');
    }
  }

  Future<void> saveChanges() async {
    if (_disposed || (cloudMode && !_initialSyncCompleted)) {
      throw StateError('Chưa tải xong dữ liệu Firebase. Vui lòng thử lại.');
    }
    save();
    await flush();
    if (error.value != null) throw StateError(error.value!);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _refreshTimer?.cancel();
    final canFlush = !cloudMode || _initialSyncCompleted;
    // Stop an in-flight initial read from restoring data into the next role's
    // stores. No cloud edits can have been queued before initial sync finishes.
    if (!canFlush) _disposed = true;
    try {
      await _remoteSubscription?.cancel();
      _remoteSubscription = null;
      if (canFlush) await flush();
    } finally {
      _disposed = true;
      await _remoteSubscription?.cancel();
      _remoteSubscription = null;
      for (final source in _subscriptions) {
        source.removeListener(save);
      }
      _subscriptions.clear();
      if (current == this) current = null;
      await repository.close();
      scheduleMicrotask(() {
        error.dispose();
        saveStatus.dispose();
        refreshing.dispose();
      });
    }
  }
}
