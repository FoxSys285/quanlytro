import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/landlord_page_router.dart';
import 'package:quanlytro/pages/landlord/staff/landlord_staff_page.dart';
import 'package:quanlytro/pages/landlord/staff/landlord_staff_store.dart';
import 'package:quanlytro/pages/shared/notifications/notification_settings_page.dart';
import 'package:quanlytro/pages/shared/profile/account_profile_page.dart';
import 'package:quanlytro/pages/shared/profile/account_store.dart';
import 'package:quanlytro/pages/shared/profile/contact_details.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/tenant/tenant_page_router.dart';
import 'package:quanlytro/pages/shared/settings/account_settings_page.dart';
import 'package:quanlytro/pages/tenant/announcements/tenant_announcements_page.dart';
import 'package:quanlytro/pages/landlord/announcements/landlord_announcements_page.dart';

void main() {
  testWidgets(
    'Settings contain account options and bells open housing announcements',
    (tester) async {
      for (final role in [AppRole.tenant, AppRole.landlord]) {
        AccountStore.instance.setNotificationsEnabled(role, true);
        addTearDown(
          () => AccountStore.instance.setNotificationsEnabled(role, true),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: role == AppRole.tenant
                ? const TenantLayout()
                : const LandlordLayout(),
          ),
        );
        await tester.tap(find.byTooltip('Mở danh mục chức năng'));
        await tester.pumpAndSettle();
        expect(find.text('Hồ sơ cá nhân'), findsNothing);
        expect(find.text('Thông báo ứng dụng'), findsNothing);
        final settingsTile = find.widgetWithText(ListTile, 'Cài đặt');
        await tester.ensureVisible(settingsTile);
        await tester.tap(settingsTile);
        await tester.pumpAndSettle();
        expect(find.byType(AccountSettingsPage), findsOneWidget);
        await tester.tap(find.text('Hồ sơ cá nhân'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountProfilePage), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(AccountSettingsPage), findsOneWidget);
        await tester.tap(find.text('Thông báo ứng dụng'));
        await tester.pumpAndSettle();
        expect(find.byType(NotificationSettingsPage), findsOneWidget);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(AccountStore.instance.notificationsEnabled(role), isFalse);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Tài khoản'));
        await tester.pumpAndSettle();
        expect(find.text('Hồ sơ'), findsNothing);
        await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Cài đặt'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byTooltip('Thông báo'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(
            role == AppRole.tenant
                ? TenantAnnouncementsPage
                : LandlordAnnouncementsPage,
          ),
          findsOneWidget,
        );
        expect(find.byType(NotificationSettingsPage), findsNothing);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.notifications_off_outlined),
          ),
          findsNothing,
        );
        if (role == AppRole.landlord) {
          await tester.tap(find.text('Tổng quan').last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Thông báo').last);
          await tester.pumpAndSettle();
          expect(find.byType(LandlordAnnouncementsPage), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
  test('Profiles and notification preferences belong to the correct role', () {
    final rental = LandlordDemoStore.demo();
    final accounts = AccountStore(rental: rental);
    addTearDown(rental.dispose);
    addTearDown(accounts.dispose);
    final tenantBefore = accounts.profile(AppRole.tenant);
    final propertyBefore = rental.property;
    accounts.saveProfile(
      AppRole.landlord,
      const ContactDetails(
        name: 'Chủ trọ mới',
        phone: '0912345678',
        email: 'owner@example.com',
        address: 'Địa chỉ chủ trọ',
      ),
    );
    expect(rental.property.ownerName, 'Chủ trọ mới');
    expect(rental.property.phone, '0912345678');
    expect(rental.property.address, propertyBefore.address);
    expect(accounts.profile(AppRole.tenant).name, tenantBefore.name);
    accounts.saveProfile(
      AppRole.tenant,
      const ContactDetails(
        name: 'Người thuê mới',
        phone: '0987654321',
        email: 'tenant@example.com',
        address: 'Địa chỉ người thuê',
      ),
    );
    expect(accounts.profile(AppRole.tenant).name, 'Người thuê mới');
    expect(
      rental.members
          .where((member) => member.tenantId == TenantSession.tenantId)
          .every(
            (member) =>
                member.name == 'Người thuê mới' && member.phone == '0987654321',
          ),
      isTrue,
    );
    expect(rental.property.ownerName, 'Chủ trọ mới');
    accounts.setNotificationsEnabled(AppRole.tenant, false);
    expect(accounts.notificationsEnabled(AppRole.tenant), isFalse);
    expect(accounts.notificationsEnabled(AppRole.landlord), isTrue);
  });

  testWidgets(
    'Both routers resolve profile and notification settings; landlord resolves staff',
    (tester) async {
      for (final role in [AppRole.tenant, AppRole.landlord]) {
        for (final id in [
          'profile',
          'notifications',
          if (role == AppRole.landlord) 'staff',
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    final destination = RoleDestination(
                      id: id,
                      label: id,
                      icon: Icons.home,
                      group: 'Tài khoản',
                    );
                    return role == AppRole.tenant
                        ? buildTenantPage(context, destination)
                        : buildLandlordPage(context, destination);
                  },
                ),
              ),
            ),
          );
          expect(
            find.byType(
              id == 'profile'
                  ? AccountProfilePage
                  : id == 'staff'
                  ? LandlordStaffPage
                  : NotificationSettingsPage,
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  for (final width in [390.0, 1280.0]) {
    for (final role in [AppRole.tenant, AppRole.landlord]) {
      testWidgets(
        'Edit profile, cancel and keep notification toggle for $role at $width',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final rental = LandlordDemoStore.demo();
          final accounts = AccountStore(rental: rental);
          addTearDown(rental.dispose);
          addTearDown(accounts.dispose);
          final before = accounts.profile(role).name;
          Future<void> profile() => tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AccountProfilePage(role: role, store: accounts),
              ),
            ),
          );
          await profile();
          await tester.ensureVisible(find.text('Chỉnh sửa hồ sơ'));
          await tester.tap(find.text('Chỉnh sửa hồ sơ'));
          await tester.pumpAndSettle();
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'Hồ sơ đã sửa');
          await tester.enterText(fields.at(2), 'email-sai');
          await tester.tap(find.text('Lưu thay đổi'));
          await tester.pumpAndSettle();
          expect(find.text('Email không hợp lệ.'), findsOneWidget);
          expect(accounts.profile(role).name, before);
          await tester.enterText(fields.at(2), 'new@example.com');
          await tester.tap(find.text('Lưu thay đổi'));
          await tester.pumpAndSettle();
          expect(accounts.profile(role).name, 'Hồ sơ đã sửa');
          await tester.ensureVisible(find.text('Chỉnh sửa hồ sơ'));
          await tester.tap(find.text('Chỉnh sửa hồ sơ'));
          await tester.pumpAndSettle();
          await tester.enterText(fields.at(0), 'Không lưu');
          await tester.tap(find.text('Hủy'));
          await tester.pumpAndSettle();
          expect(accounts.profile(role).name, 'Hồ sơ đã sửa');
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: NotificationSettingsPage(role: role, store: accounts),
              ),
            ),
          );
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
          expect(accounts.notificationsEnabled(role), isFalse);
          await profile();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: NotificationSettingsPage(role: role, store: accounts),
              ),
            ),
          );
          expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
          expect(accounts.notificationsEnabled(role), isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('Staff add, edit, delete and cancel at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final staff = LandlordStaffStore.demo();
      addTearDown(staff.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordStaffPage(store: staff)),
        ),
      );
      expect(staff.staff.length, 3);
      await tester.tap(find.text('Thêm nhân viên'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      for (final entry in [
        'Nhân viên mới',
        'abc',
        'worker@example.com',
        'Quản lý tầng 2',
      ].asMap().entries) {
        await tester.ensureVisible(fields.at(entry.key));
        await tester.enterText(fields.at(entry.key), entry.value);
      }
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text('Số điện thoại không hợp lệ.'), findsOneWidget);
      await tester.ensureVisible(fields.at(1));
      await tester.enterText(fields.at(1), '0901234567');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(staff.staff.length, 4);
      final id = staff.staff.last.id;
      final card = find.byKey(ValueKey(id));
      final edit = find.descendant(of: card, matching: find.text('Sửa'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(0), 'Nhân viên đổi tên');
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(staff.staff.last.contact.name, 'Nhân viên đổi tên');
      final delete = find.descendant(of: card, matching: find.text('Xóa'));
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(staff.staff.length, 4);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
      await tester.pumpAndSettle();
      expect(staff.staff.length, 3);
      expect(staff.staff.any((member) => member.id == id), isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
