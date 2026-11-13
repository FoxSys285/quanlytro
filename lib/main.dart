import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'layouts/admin_layout.dart';
import 'layouts/landlord_layout.dart';
import 'layouts/role_layout.dart';
import 'layouts/tenant_layout.dart';
import 'data/app_persistence.dart';
import 'data/local_database.dart';
import 'data/firestore_repository.dart';
import 'data/local_auth.dart';
import 'data/firebase_account_gateway.dart';
import 'data/scoped_firestore_repository.dart';
import 'data/discovery_catalog.dart';
import 'data/property_catalog.dart';
import 'pages/tenant/discovery/tenant_discovery_page.dart';
import 'pages/shared/rental/tenant_session.dart';
import 'pages/shared/auth/login_page.dart';
import 'pages/shared/notifications/app_notification_service.dart';
import 'pages/shared/profile/account_store.dart';
import 'pages/shared/widgets/app_brand.dart';

final _appNavigatorKey = GlobalKey<NavigatorState>();
final _noAppError = ValueNotifier<String?>(null);
final _noAppRefresh = ValueNotifier<bool>(false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Top-level unhandled error caught safely: $error\n$stack');
    return true;
  };
  runApp(
    const MaterialApp(
      title: appName,
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init: $e');
  }
  AppPersistence? persistence;
  try {
    TenantDiscoveryPage.activeCatalogSource = FirestoreTenantCatalogSource();
    TenantDiscoveryPage.activePropertyCatalogSource =
        FirestoreTenantPropertyCatalogSource();
    const cloudAuth = bool.fromEnvironment(
      'USE_FIREBASE_AUTH',
      defaultValue: true,
    );
    if (cloudAuth) {
      LocalAuth.instance.configureFirebase(
        gateway: FirebaseAccountGateway(),
        onSignedIn: (session) async {
          await AppPersistence.current?.dispose();
          persistence = null;
          TenantSession.authenticatedTenantId = session.tenantId;
          final remote = ScopedFirestoreRentalRepository(session: session);
          persistence = AppPersistence(remote, cloudMode: true);
          await persistence!.initializeAsync();
        },
        onSignedOut: () async {
          try {
            await AppNotificationService.instance.unregister();
          } finally {
            final signedOutPersistence = persistence;
            persistence = null;
            TenantSession.authenticatedTenantId = null;
            await signedOutPersistence?.dispose();
          }
        },
      );
      try {
        await LocalAuth.instance.restoreCloudSession();
      } catch (error) {
        debugPrint('Could not restore Firebase session: $error');
      }
      runApp(const MyApp(requireLogin: true));
      return;
    }
    final sqliteRepo = await SqliteRentalRepository.open();
    RentalRepository repository;
    try {
      repository = HybridRentalRepository(
        local: sqliteRepo,
        remote: FirestoreRentalRepository(),
      );
    } catch (e) {
      debugPrint('Firestore hybrid fallback: $e');
      repository = sqliteRepo;
    }
    persistence = AppPersistence(repository);
    await persistence.initialize();
    runApp(const MyApp(requireLogin: true));
  } catch (error) {
    await persistence?.dispose();
    runApp(
      MaterialApp(
        title: appName,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage_outlined, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Không thể mở dữ liệu trên thiết bị.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: main, child: const Text('Thử lại')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.requireLogin = false});
  final bool requireLogin;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _appNavigatorKey,
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16836F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          foregroundColor: Color(0xFF344252),
          iconTheme: IconThemeData(color: Color(0xFF344252)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE5EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDCE5EA)),
          ),
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(44, 44),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      builder: (context, child) => ListenableBuilder(
        listenable: LocalAuth.instance,
        builder: (context, _) {
          final persistence = AppPersistence.current;
          final activePersistence =
              persistence == null || persistence.isDisposed
              ? null
              : persistence;
          return ValueListenableBuilder<String?>(
            valueListenable: activePersistence?.error ?? _noAppError,
            builder: (context, error, _) => Column(
              children: [
                if (activePersistence != null && error != null)
                  Material(
                    color: const Color(0xFFFFE8D5),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(child: Text(error)),
                            TextButton(
                              onPressed: activePersistence.retrySync,
                              child: Text(
                                activePersistence.initialSyncFailed
                                    ? 'Thử tải lại'
                                    : activePersistence.hasPendingChanges
                                    ? 'Thử lưu lại'
                                    : 'Thử kết nối lại',
                              ),
                            ),
                            if (activePersistence.cloudMode)
                              TextButton(
                                onPressed: () async {
                                  final discard = await showDialog<bool>(
                                    context: _appNavigatorKey
                                        .currentState!
                                        .overlay!
                                        .context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Tải dữ liệu mới?'),
                                      content: const Text(
                                        'Bỏ thay đổi chưa lưu trên màn hình này và nhận bản mới từ Firebase.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Giữ chỉnh sửa'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Tải bản mới'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (discard == true) {
                                    await activePersistence.refresh(
                                      discardUnsaved: true,
                                    );
                                  }
                                },
                                child: const Text('Tải bản mới'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  // Keep the root Navigator mounted as the error banner changes.
                  key: const ValueKey('app-navigation-content'),
                  child: ValueListenableBuilder<bool>(
                    valueListenable:
                        activePersistence?.refreshing ?? _noAppRefresh,
                    builder: (context, busy, _) => Stack(
                      children: [
                        child!,
                        if (busy)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      home: requireLogin
          ? const _AuthenticatedApp()
          : const RoleLayoutPreview(),
    );
  }
}

class _AuthenticatedApp extends StatefulWidget {
  const _AuthenticatedApp();
  @override
  State<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<_AuthenticatedApp>
    with WidgetsBindingObserver {
  String? _permissionSessionUid;
  bool _permissionSetupPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocalAuth.instance.addListener(_syncSessionPermissions);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSessionPermissions();
    });
  }

  @override
  void dispose() {
    LocalAuth.instance.removeListener(_syncSessionPermissions);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    LocalAuth.instance.setForeground(state == AppLifecycleState.resumed);
    final persistence = AppPersistence.current;
    if (persistence == null) return;
    if (state != AppLifecycleState.resumed) {
      unawaited(persistence.flushInBackground());
    } else {
      unawaited(persistence.refresh());
    }
  }

  void _syncSessionPermissions() {
    final session = LocalAuth.instance.session;
    final role = LocalAuth.instance.role;
    if (session == null ||
        role == null ||
        (role != AppRole.landlord && role != AppRole.tenant) ||
        session.uid == _permissionSessionUid ||
        _permissionSetupPending) {
      if (session == null) _permissionSessionUid = null;
      return;
    }
    _permissionSetupPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        // Avoid opening the Android permission sheet during the first frame of
        // the newly authenticated screen and its registration route transition.
        await Future<void>.delayed(const Duration(seconds: 2));
        if (!mounted || LocalAuth.instance.session?.uid != session.uid) return;
        final enabled = AccountStore.instance.notificationsEnabled(role);
        // An OS permission denial is not a change to the user's saved
        // preference. Persisting it here caused an unrelated Firestore write
        // at every sign-in, which could block later room edits on a conflict.
        await AppNotificationService.instance.requestAndRegister(
          session,
          enabled: enabled,
        );
        _permissionSessionUid = session.uid;
      } catch (error) {
        debugPrint('Could not initialize session permissions: $error');
      } finally {
        _permissionSetupPending = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: LocalAuth.instance,
    builder: (context, _) => switch (LocalAuth.instance.role) {
      null => const LoginPage(),
      AppRole.landlord => LandlordLayout(onLogout: LocalAuth.instance.signOut),
      AppRole.tenant => TenantLayout(onLogout: LocalAuth.instance.signOut),
      AppRole.admin => AdminLayout(onLogout: LocalAuth.instance.signOut),
    },
  );
}

/// Preview harness for widget tests; cloud login is enabled with USE_FIREBASE_AUTH.
class RoleLayoutPreview extends StatefulWidget {
  const RoleLayoutPreview({super.key});

  @override
  State<RoleLayoutPreview> createState() => _RoleLayoutPreviewState();
}

class _RoleLayoutPreviewState extends State<RoleLayoutPreview> {
  AppRole _role = AppRole.tenant;

  @override
  Widget build(BuildContext context) {
    void selectRole(AppRole role) => setState(() => _role = role);

    switch (_role) {
      case AppRole.tenant:
        return TenantLayout(onPreviewRoleSelected: selectRole);
      case AppRole.landlord:
        return LandlordLayout(onPreviewRoleSelected: selectRole);
      case AppRole.admin:
        return AdminLayout(onPreviewRoleSelected: selectRole);
    }
  }
}
