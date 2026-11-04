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
import 'pages/tenant/discovery/tenant_discovery_page.dart';
import 'pages/shared/rental/tenant_session.dart';
import 'pages/shared/auth/login_page.dart';
import 'pages/shared/widgets/app_brand.dart';

final _appNavigatorKey = GlobalKey<NavigatorState>();

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
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init: $e');
  }
  runApp(
    const MaterialApp(
      title: appName,
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  );
  AppPersistence? persistence;
  try {
    TenantDiscoveryPage.activeCatalogSource = FirestoreTenantCatalogSource();
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
          final RentalRepository repository;
          if (kIsWeb) {
            repository = remote;
          } else {
            final local = await SqliteRentalRepository.open(
              filename: 'quanlytro_${Uri.encodeComponent(session.uid)}.db',
            );
            repository = HybridRentalRepository(
              local: local,
              remote: remote,
              strictRemote: true,
            );
          }
          persistence = AppPersistence(repository, cloudMode: true);
          await persistence!.initialize();
        },
        onSignedOut: () async {
          await persistence?.dispose();
          persistence = null;
          TenantSession.authenticatedTenantId = null;
        },
      );
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
          if (persistence == null || persistence.isDisposed) return child!;
          return ValueListenableBuilder<String?>(
            valueListenable: persistence.error,
            builder: (context, error, _) => Column(
              children: [
                if (error != null)
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
                              onPressed: persistence.save,
                              child: const Text('Thử lưu lại'),
                            ),
                            if (persistence.cloudMode)
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
                                    await persistence.refresh(
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
                  child: persistence.isDisposed
                      ? child!
                      : ValueListenableBuilder<bool>(
                          valueListenable: persistence.refreshing,
                          builder: (context, busy, _) => Stack(
                      children: [
                        AbsorbPointer(absorbing: busy, child: child!),
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    LocalAuth.instance.setForeground(state == AppLifecycleState.resumed);
    if (state != AppLifecycleState.resumed) AppPersistence.current?.flush();
    if (state == AppLifecycleState.resumed) AppPersistence.current?.refresh();
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
