import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/data/rental_cloud_codec.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/landlord/landlord_theme.dart';
import 'package:quanlytro/pages/landlord/properties/landlord_verification_list_page.dart';
import 'package:quanlytro/pages/landlord/properties/landlord_verification_page.dart';

void main() {
  late RentalPortfolio portfolio;

  setUp(() {
    portfolio = RentalPortfolio.seeded();
    RentalPortfolio.instance = portfolio;
    AdminStore.instance.restore({});
  });

  tearDown(() {
    AdminStore.instance.restore({});
    portfolio.dispose();
  });

  testWidgets(
    'Verification search and status filters narrow the property list',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: landlordTheme(dark: false),
          home: const Scaffold(body: LandlordVerificationListPage()),
        ),
      );
      final property = portfolio.stores[1].property;
      await tester.enterText(find.byType(TextField), property.name);
      await tester.pumpAndSettle();
      final propertyTitle = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == property.name,
      );
      expect(propertyTitle, findsOneWidget);
      expect(find.text(portfolio.stores.first.property.name), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Đã xác minh'));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy nhà trọ'), findsOneWidget);
      expect(propertyTitle, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Verification list opens the tapped property, not the active one',
    (tester) async {
      final selected = portfolio.stores[1];
      expect(portfolio.active.property.id, isNot(selected.property.id));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LandlordVerificationListPage())),
      );
      await tester.ensureVisible(find.text(selected.property.name));
      await tester.tap(find.text(selected.property.name));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LandlordVerificationPage>(
              find.byType(LandlordVerificationPage),
            )
            .store,
        same(selected),
      );
      expect(
        find.text('Tên nhà trọ: ${selected.property.name}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Submitted application shows pending output then admin feedback',
    (tester) async {
      final store = portfolio.stores.first;
      final saved = store.toMap();
      (saved['property'] as Map)['verificationSubmittedAt'] = DateTime(
        2026,
        11,
        22,
      ).toIso8601String();
      store.restore(saved);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordVerificationPage(store: store)),
        ),
      );
      expect(find.text('Phản hồi từ Admin'), findsOneWidget);
      expect(
        find.text('Đã tiếp nhận hồ sơ. Đang chờ Admin xét duyệt và phản hồi.'),
        findsOneWidget,
      );
      const note = 'Vui lòng cung cấp ảnh CCCD mặt sau rõ nét.';
      AdminStore.instance.restore({
        'reviewNotes': {store.property.id: note},
      });
      await tester.pump();
      expect(find.text(note), findsOneWidget);
      expect(find.text('Cần bổ sung hồ sơ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Submitting complete documents creates a pending application for that property',
    (tester) async {
      final store = portfolio.stores[1];
      final saved = store.toMap();
      final property = saved['property'] as Map;
      property['verificationSubmittedAt'] = null;
      property['verificationDocuments'] = [
        for (final id in ['portrait', 'identity', 'ownership'])
          {
            'id': id,
            'files': [
              {
                'name': '$id.png',
                'bytes': [1, 2, 3],
              },
            ],
          },
      ];
      store.restore(saved);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandlordVerificationPage(store: store)),
        ),
      );
      final consent = find.byType(CheckboxListTile);
      await tester.ensureVisible(consent);
      await tester.tap(consent);
      await tester.pump();
      final submit = find.widgetWithText(FilledButton, 'Gửi hồ sơ xác minh');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(store.property.verificationSubmittedAt, isNotNull);
      expect(store.property.verificationDocuments.length, 3);
      expect(AdminStore.instance.isVerified(store.property.id), isFalse);
      expect(find.text('Phản hồi từ Admin'), findsOneWidget);
      expect(
        find.text('Đã tiếp nhận hồ sơ. Đang chờ Admin xét duyệt và phản hồi.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('Admin feedback stays private, survives cloud restore and clears on approval', () {
    final id = portfolio.stores.first.property.id;
    final snapshot = {
      'portfolio': portfolio.toMap(),
      'admin': <String, dynamic>{
        'reviewNotes': {id: 'Bổ sung giấy ủy quyền cho thuê.'},
      },
    };
    Map<String, Map<String, dynamic>> encode() => encodeCloudDocuments(
      snapshot,
      owners: {for (final s in portfolio.stores) s.property.id: 'owner-a'},
    );
    final docs = encode();
    final review = docs.values.firstWhere(
      (row) => row['kind'] == 'verificationReview' && row['propertyId'] == id,
    );
    expect(review['tenantIds'], isEmpty);
    final restored = <String, dynamic>{};
    restoreCloudPropertyReviews(restored, docs.values);
    expect(restored['reviewNotes'][id], 'Bổ sung giấy ủy quyền cho thuê.');
    for (final row in docs.entries.where(
      (e) => !e.key.startsWith('rental_records/'),
    )) {
      expect(row.value.toString(), isNot(contains('Bổ sung giấy ủy quyền')));
    }
    snapshot['admin'] = {'reviewNotes': <String, String>{}};
    restoreCloudPropertyReviews(restored, encode().values);
    expect(restored['reviewNotes'][id], isEmpty);
  });
}
