import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/data/local_auth.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/admin/admin_workspace_page.dart';
import 'package:quanlytro/pages/landlord/announcements/landlord_announcements_page.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/properties/landlord_verification_page.dart';
import 'package:quanlytro/pages/shared/announcements/announcement_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RentalPortfolio portfolio;
  final admin = AdminStore.instance;
  void submit(LandlordDemoStore store, DateTime at) {
    final snapshot = store.toMap();
    (snapshot['property'] as Map)['verificationSubmittedAt'] = at
        .toIso8601String();
    store.restore(snapshot);
  }

  setUp(() async {
    await LocalAuth.instance.initialize();
    await LocalAuth.instance.signIn('admin@tro.local', 'Tro@2026');
    portfolio = RentalPortfolio.seeded();
    RentalPortfolio.instance = portfolio;
    LandlordDemoStore.instance = portfolio.active;
    admin.restore({});
    AnnouncementStore.reset();
  });
  tearDown(() {
    admin.restore({});
    AnnouncementStore.reset();
    portfolio.dispose();
  });

  test('Supplement notification and read state survive reload; repeated request is unread', () {
    final store = portfolio.stores.first;
    final id = store.property.id;
    submit(store, DateTime(2026, 11, 23));
    admin.requestSupplement(id, 'Vui lòng chụp lại ảnh CCCD rõ nét.');
    final inbox = AnnouncementStore.forRental(store);
    final notice = inbox.inbox.singleWhere(
      (n) => n.id.startsWith('verification-review:'),
    );
    expect(notice.isRead, isFalse);
    expect(notice.content, contains('CCCD rõ nét'));
    inbox.markLandlordRead(notice.id);
    final savedInbox = jsonDecode(jsonEncode(inbox.toMap())) as Map;
    final snapshot = {'portfolio': portfolio.toMap(), 'admin': admin.toMap()};
    final docs = encodeCloudDocuments(
      snapshot,
      owners: {
        for (final store in portfolio.stores) store.property.id: 'owner',
      },
    );
    final restored = <String, dynamic>{};
    restoreCloudPropertyReviews(restored, docs.values);
    admin.restore(restored);
    inbox.restore(Map<String, dynamic>.from(savedInbox));
    expect(inbox.inbox.singleWhere((n) => n.id == notice.id).isRead, isTrue);
    expect(admin.pendingReviewNote(id), contains('CCCD'));

    submit(store, DateTime(2026, 11, 24));
    expect(admin.verificationResubmitted(id), isTrue);
    expect(admin.pendingReviewNote(id), isEmpty);
    final reopenedPortfolio = RentalPortfolio.fromMap(
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(portfolio.toMap())) as Map,
      ),
    );
    addTearDown(reopenedPortfolio.dispose);
    final reopenedAdmin = AdminStore(portfolio: reopenedPortfolio)
      ..restore(restored);
    addTearDown(reopenedAdmin.dispose);
    expect(reopenedAdmin.verificationResubmitted(id), isTrue);
    admin.requestSupplement(id, 'Vui lòng chụp lại ảnh CCCD rõ nét.');
    expect(admin.verificationResubmitted(id), isFalse);
    expect(
      inbox.inbox
          .singleWhere((n) => n.id.startsWith('verification-review:'))
          .isRead,
      isFalse,
    );
  });

  testWidgets(
    'Admin distinguishes waiting supplements from resubmitted files',
    (tester) async {
      final store = portfolio.stores.first;
      final id = store.property.id;
      submit(store, DateTime(2026, 11, 23));
      admin.requestSupplement(id, 'Vui lòng bổ sung ảnh giấy tờ.');
      submit(store, DateTime(2026, 11, 24));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminWorkspacePage(
              destination: RoleDestination(
                id: 'property_verification',
                label: 'Xác minh nhà trọ',
                icon: Icons.verified,
                group: 'admin',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Đã gửi lại hồ sơ'));
      await tester.pumpAndSettle();
      expect(find.text(store.property.name), findsOneWidget);
      expect(find.text('Đã gửi lại hồ sơ'), findsNWidgets(2));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Chờ bổ sung'));
      await tester.pumpAndSettle();
      expect(find.text('Không có nhà trọ phù hợp với bộ lọc.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Landlord can open a supplement request for another property', (
    tester,
  ) async {
    final store = portfolio.stores[1];
    admin.requestSupplement(
      store.property.id,
      'Vui lòng bổ sung giấy ủy quyền.',
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LandlordAnnouncementsPage())),
    );
    await tester.pumpAndSettle();
    final title = find.text(
      'Cần bổ sung hồ sơ xác minh · ${store.property.name}',
    );
    await tester.ensureVisible(title);
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LandlordVerificationPage>(
            find.byType(LandlordVerificationPage),
          )
          .store,
      same(store),
    );
    expect(
      find.textContaining('Vui lòng bổ sung giấy ủy quyền.'),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
