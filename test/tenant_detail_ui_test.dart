import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// The default method-channel test implementation predates ground overlays.
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/auth/change_password_page.dart';
import 'package:quanlytro/pages/shared/notifications/notification_settings_page.dart';
import 'package:quanlytro/pages/shared/profile/account_profile_page.dart';
import 'package:quanlytro/pages/shared/profile/account_store.dart';
import 'package:quanlytro/pages/shared/settings/account_settings_page.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_area_picker_page.dart';
import 'package:quanlytro/pages/tenant/discovery/services/tenant_location_service.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_discovery_page.dart';
import 'package:quanlytro/pages/tenant/incidents/tenant_baosuco_page.dart';
import 'package:quanlytro/pages/tenant/invoices/tenant_invoices_page.dart';
import 'package:quanlytro/pages/tenant/leases/tenant_lease_contract_page.dart';
import 'package:quanlytro/pages/tenant/tenant_detail_ui.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Tenant detail pages fit and account actions work at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rental = LandlordDemoStore.demo();
      final accounts = AccountStore(rental: rental);
      addTearDown(rental.dispose);
      addTearDown(accounts.dispose);
      final boundaryKey = GlobalKey();
      final capture = Platform.environment['CAPTURE_TENANT_UI'] == 'true';
      if (capture) {
        await tester.runAsync(() async {
          final font = FontLoader('PreviewFont')
            ..addFont(
              Future.value(
                ByteData.sublistView(
                  await File('C:/Windows/Fonts/arial.ttf').readAsBytes(),
                ),
              ),
            );
          await font.load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
      }
      final pages = <String, Widget>{
        'contract': TenantLeaseContractPage(store: rental),
        'payments': TenantInvoicesPage(store: rental),
        'incidents': TenantBaoSuCoPage(store: rental),
        'settings': const AccountSettingsPage(role: AppRole.tenant),
        'password': const ChangePasswordPage(role: AppRole.tenant),
        'profile': AccountProfilePage(role: AppRole.tenant, store: accounts),
        'notifications': NotificationSettingsPage(
          role: AppRole.tenant,
          store: accounts,
        ),
      };
      for (final entry in pages.entries) {
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: capture ? 'PreviewFont' : null,
              ),
              home: TenantSubpageScaffold(
                title: 'Chi tiết',
                child: entry.value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: entry.key);
        if (capture && width == 390) {
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('.dart_tool/previews').create(recursive: true);
            await File('.dart_tool/previews/tenant_${entry.key}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        if (entry.key == 'profile') {
          await tester.ensureVisible(find.text('Chỉnh sửa hồ sơ'));
          await tester.tap(find.text('Chỉnh sửa hồ sơ'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField).first,
            'Nguyễn Minh Anh',
          );
          await tester.tap(find.text('Lưu thay đổi'));
          await tester.pumpAndSettle();
          expect(accounts.profile(AppRole.tenant).name, 'Nguyễn Minh Anh');
        }
        if (entry.key == 'notifications') {
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
          expect(accounts.notificationsEnabled(AppRole.tenant), isFalse);
        }
        if (entry.key == 'password') {
          final fields = find.byType(TextField);
          await tester.enterText(fields.at(1), 'NewPass123');
          await tester.enterText(fields.at(2), 'Mismatch123');
          await tester.ensureVisible(find.text('Lưu mật khẩu'));
          await tester.tap(find.text('Lưu mật khẩu'));
          await tester.pumpAndSettle();
          expect(find.text('Mật khẩu nhập lại không khớp.'), findsOneWidget);
        }
        if (entry.key == 'incidents') {
          await tester.tap(find.text('Tạo yêu cầu mới'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Gửi yêu cầu'));
          await tester.tap(find.text('Gửi yêu cầu'));
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
          await tester.ensureVisible(find.byType(TextFormField).first);
          await tester.enterText(
            find.byType(TextFormField).first,
            'Đèn phòng bị hỏng',
          );
          await tester.enterText(
            find.byType(TextFormField).last,
            'Đèn không sáng khi bật công tắc.',
          );
          await tester.ensureVisible(find.text('Gửi yêu cầu'));
          await tester.tap(find.text('Gửi yêu cầu'));
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsNothing);
          expect(
            rental.incidents.any((i) => i.title == 'Đèn phòng bị hỏng'),
            isTrue,
          );
        }
        expect(tester.takeException(), isNull, reason: '${entry.key} actions');
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });
  }

  group('Discovery location preview', () {
    const locationChannel = MethodChannel('flutter.baseflow.com/geolocator');
    var permitted = true;
    late GoogleMapsFlutterPlatform originalMaps;
    setUp(() {
      originalMaps = GoogleMapsFlutterPlatform.instance;
      GoogleMapsFlutterPlatform.instance = _TestMaps();
      permitted = true;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        locationChannel,
        (call) async => switch (call.method) {
          'isLocationServiceEnabled' => true,
          'checkPermission' || 'requestPermission' => permitted ? 3 : 1,
          'getCurrentPosition' => {
            'latitude': 10.762622,
            'longitude': 106.660172,
            'timestamp': 1,
            'accuracy': 5.0,
            'altitude': 0.0,
            'heading': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'altitude_accuracy': 0.0,
            'heading_accuracy': 0.0,
          },
          _ => null,
        },
      );
      messenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        (call) async => call.method == 'create' ? 1 : null,
      );
      for (var i = 0; i < 20; i++) {
        messenger.setMockMethodCallHandler(
          MethodChannel('plugins.flutter.io/google_maps_$i'),
          (_) async => null,
        );
      }
    });
    tearDown(() {
      GoogleMapsFlutterPlatform.instance = originalMaps;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(locationChannel, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
      for (var i = 0; i < 20; i++) {
        messenger.setMockMethodCallHandler(
          MethodChannel('plugins.flutter.io/google_maps_$i'),
          null,
        );
      }
    });

    testWidgets('Discovery location heading has no see-all action', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TenantDiscoveryPage(locationService: _TestLocationService()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heading = find.ancestor(
        of: find.text('Vị trí').last,
        matching: find.byType(Row),
      );
      expect(heading, findsOneWidget);
      expect(
        find.descendant(of: heading, matching: find.text('Xem tất cả')),
        findsNothing,
      );
      expect(find.text('Xem tất cả'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Shows real coordinates and opens a separate map for selecting a point',
      (tester) async {
        TenantAreaSelection? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 410,
                child: TenantAreaPickerPage(
                  locationService: const _TestLocationService(),
                  embedded: true,
                  onSelected: (value) => selected = value,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('10.762622, 106.660172'), findsOneWidget);
        expect(find.text('Chọn điểm này'), findsNothing);
        expect(find.text('Xem tất cả'), findsNothing);
        final preview = tester.widget<GoogleMap>(find.byType(GoogleMap));
        expect(
          preview.markers.single.position,
          const LatLng(10.762622, 106.660172),
        );
        expect(preview.onTap, isNotNull);
        expect(preview.onLongPress, isNotNull);
        expect(preview.scrollGesturesEnabled, isTrue);
        await tester.tap(
          find.byKey(const ValueKey('current-location-map-preview')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Chọn vị trí'), findsOneWidget);
        final map = tester.widget<GoogleMap>(find.byType(GoogleMap).last);
        expect(map.onTap, isNotNull);
        map.onTap!(const LatLng(10.8, 106.7));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<GoogleMap>(find.byType(GoogleMap).last)
              .markers
              .single
              .position,
          const LatLng(10.8, 106.7),
        );
        Navigator.of(tester.element(find.text('Chọn vị trí'))).pop(
          const TenantAreaSelection(
            city: 'Hồ Chí Minh',
            ward: null,
            latitude: 10.8,
            longitude: 106.7,
          ),
        );
        await tester.pumpAndSettle();
        expect(selected?.latitude, 10.8);
        expect(find.text('10.800000, 106.700000'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Permission denial does not show a fallback as the current position',
      (tester) async {
        permitted = false;
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 410,
                child: TenantAreaPickerPage(
                  embedded: true,
                  locationService: _TestLocationService(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<GoogleMap>(find.byType(GoogleMap)).markers,
          isEmpty,
        );
        expect(find.textContaining('Chưa cấp quyền vị trí'), findsOneWidget);
        expect(find.byTooltip('Lấy vị trí hiện tại'), findsOneWidget);
        permitted = true;
        await tester.tap(find.byTooltip('Lấy vị trí hiện tại'));
        await tester.pumpAndSettle();
        expect(find.text('10.762622, 106.660172'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  testWidgets('Settings opens each tenant account page and returns correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TenantSubpageScaffold(
          title: 'Cài đặt',
          child: AccountSettingsPage(role: AppRole.tenant),
        ),
      ),
    );
    for (final (label, type) in [
      ('Đổi mật khẩu', ChangePasswordPage),
      ('Hồ sơ cá nhân', AccountProfilePage),
      ('Thông báo ứng dụng', NotificationSettingsPage),
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(type), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại').last);
      await tester.pumpAndSettle();
      expect(find.byType(AccountSettingsPage), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}

class _TestMaps extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox.expand();
}

class _TestLocationService extends TenantLocationService {
  const _TestLocationService();
  @override
  Future<TenantAreaSelection> areaAt(double latitude, double longitude) async =>
      TenantAreaSelection(
        city: 'Hồ Chí Minh',
        ward: 'Phường 25',
        latitude: latitude,
        longitude: longitude,
      );
}
