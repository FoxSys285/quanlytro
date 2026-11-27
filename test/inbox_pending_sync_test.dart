import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/app_persistence.dart';
import 'package:quanlytro/data/local_database.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/conversations/landlord_danhsachtinnhan_page.dart';
import 'package:quanlytro/pages/landlord/conversations/landlord_tinnhan_page.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/announcements/announcement_store.dart';
import 'package:quanlytro/pages/shared/conversations/conversation_store.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/tenant/announcements/components/tenant_announcement_card.dart';
import 'package:quanlytro/pages/tenant/announcements/tenant_announcements_page.dart';
import 'package:quanlytro/pages/tenant/conversations/tenant_danhsachtinnhan_page.dart';
import 'package:quanlytro/pages/tenant/conversations/tenant_tinnhan_page.dart';
import 'package:quanlytro/pages/tenant/conversations/models/tenant_cuoctrochuyen.dart';

class _Repository implements RentalRepository {
  @override
  Future<Map<String, Map<String, dynamic>>> readAll() async => {};
  @override
  Future<void> saveAll(Map<String, Map<String, dynamic>> documents) async {}
  @override
  Future<void> close() async {}
}

class _PendingPersistence extends AppPersistence {
  _PendingPersistence() : super(_Repository());
  final pending = Completer<void>();
  int backgroundSaves = 0;
  @override
  bool get hasPendingChanges => true;
  @override
  Future<void> flush() => pending.future;
  @override
  Future<void> flushInBackground() {
    backgroundSaves++;
    return pending.future;
  }
}

void main() {
  late _PendingPersistence persistence;
  setUp(() {
    final previous = AppPersistence.current;
    persistence = _PendingPersistence();
    AppPersistence.current = persistence;
    addTearDown(() {
      AppPersistence.current = previous;
      persistence.pending.complete();
    });
  });

  testWidgets('Tenant chat opens while saving is pending', (tester) async {
    final conversation = TenantConversation.demoConversations.first;
    final unread = conversation.unread;
    addTearDown(() => conversation.unread = unread);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TenantDanhSachTinNhanPage())),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(conversation.landlordName).first);
    await tester.tap(find.text(conversation.landlordName).first);
    await tester.pumpAndSettle();
    expect(find.byType(TenantTinNhanPage), findsOneWidget);
    expect(conversation.unread, 0);
    expect(persistence.backgroundSaves, greaterThan(0));
  });

  testWidgets('Landlord chat opens while saving is pending', (tester) async {
    final conversation = ConversationStore.instance
        .forProperty(LandlordDemoStore.activeInstance.property.id)
        .first;
    final unread = conversation.unread;
    addTearDown(() => conversation.unread = unread);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LandlordDanhSachTinNhanPage())),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(conversation.tenantName).first);
    await tester.tap(find.text(conversation.tenantName).first);
    await tester.pumpAndSettle();
    expect(find.byType(LandlordTinNhanPage), findsOneWidget);
    expect(conversation.unread, 0);
    expect(persistence.backgroundSaves, greaterThan(0));
  });

  testWidgets('Announcement opens while saving is pending', (tester) async {
    final store = AnnouncementStore.instance;
    final snapshot = store.toMap();
    addTearDown(() => store.restore(snapshot));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TenantAnnouncementsPage())),
    );
    await tester.pumpAndSettle();
    final card = find.byType(TenantAnnouncementCard).first;
    final item = tester.widget<TenantAnnouncementCard>(card).announcement;
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(item.content),
      ),
      findsOneWidget,
    );
    expect(store.isRead(item.id, TenantSession.currentTenantId), isTrue);
    expect(persistence.backgroundSaves, greaterThan(0));
  });

  testWidgets('Logout allows staying or leaving when saving stalls', (
    tester,
  ) async {
    var logouts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RoleLayoutShell(
          role: AppRole.tenant,
          displayName: 'Tenant',
          contextLabel: 'Rental',
          accentColor: Colors.green,
          initialDestinationId: 'home',
          destinations: const [
            RoleDestination(
              id: 'home',
              label: 'Home',
              icon: Icons.home,
              group: 'Tenant',
            ),
          ],
          tabs: const [
            RoleTab(
              label: 'Home',
              icon: Icons.home,
              selectedIcon: Icons.home,
              destinationId: 'home',
            ),
          ],
          pageBuilder: (_, _) => const SizedBox(),
          onLogout: () => logouts++,
        ),
      ),
    );

    Future<void> logout() async {
      tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đăng xuất').last);
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    }

    await logout();
    expect(find.text('Thay đổi chưa được đồng bộ'), findsOneWidget);
    expect(logouts, 0);
    await tester.tap(find.text('Ở lại và thử lại'));
    await tester.pumpAndSettle();
    expect(logouts, 0);
    await logout();
    await tester.tap(find.text('Đăng xuất và bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(logouts, 1);
  });
}
