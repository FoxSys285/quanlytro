import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/pages/landlord/announcements/components/landlord_announcement_card.dart';
import 'package:quanlytro/pages/landlord/announcements/components/landlord_announcement_composer.dart';
import 'package:quanlytro/pages/landlord/announcements/data/landlord_announcement_demo_data.dart';
import 'package:quanlytro/pages/landlord/announcements/landlord_announcements_page.dart';
import 'package:quanlytro/pages/landlord/announcements/models/landlord_announcement.dart';

void main() {
  test('Relative time distinguishes yesterday and earlier dates', () {
    final now = DateTime(2026, 10, 4, 9);
    expect(
      announcementTimeLabel(now.subtract(const Duration(minutes: 10)), now),
      '10 phút trước',
    );
    expect(
      announcementTimeLabel(DateTime(2026, 10, 3, 14, 30), now),
      'Hôm qua, 14:30',
    );
    expect(
      announcementTimeLabel(DateTime(2026, 9, 30, 14, 30), now),
      '30/09/2026, 14:30',
    );
  });

  testWidgets('Landlord menu opens announcement inbox', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandlordLayout()));
    await tester.tap(find.byTooltip('Mở danh mục chức năng'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Gửi thông báo'),
      250,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Gửi thông báo'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordAnnouncementsPage), findsOneWidget);
    expect(find.byType(LandlordAnnouncementCard), findsNWidgets(8));
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('Inbox filters and read state at width $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LandlordAnnouncementsPage())),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Chưa đọc'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordAnnouncementCard), findsNWidgets(5));
      final first = find.byType(LandlordAnnouncementCard).first;
      await tester.ensureVisible(first);
      await tester.tap(first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.byType(LandlordAnnouncementCard), findsNWidgets(4));
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Tất cả'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<AnnouncementCategory>),
      );
      await tester.tap(
        find.byType(DropdownButtonFormField<AnnouncementCategory>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Báo cáo sự cố').last);
      await tester.pumpAndSettle();
      expect(find.byType(LandlordAnnouncementCard), findsNWidgets(2));
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhà Nâu').last);
      await tester.pumpAndSettle();
      expect(find.byType(LandlordAnnouncementCard), findsOneWidget);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'khong-co-thong-bao');
      await tester.pumpAndSettle();
      expect(find.text('Không có thông báo phù hợp.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final audience in ['all', 'floor', 'room']) {
    testWidgets('Compose announcement for $audience recipients', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      LandlordAnnouncement? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<LandlordAnnouncement>(
                    context: context,
                    builder: (_) => const LandlordAnnouncementComposer(
                      properties: LandlordAnnouncementDemoData.properties,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      if (audience != 'all') {
        await tester.tap(find.text('Tất cả các phòng trong nhà trọ'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(audience == 'floor' ? 'Theo tầng' : 'Phòng cụ thể').last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>).last);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(audience == 'floor' ? 'Tầng 2' : 'Phòng 102').last,
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Gửi thử'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      final title = find.byType(TextFormField).at(0);
      final content = find.byType(TextFormField).at(1);
      await tester.ensureVisible(title);
      await tester.enterText(title, 'Thông báo cúp điện');
      await tester.ensureVisible(content);
      await tester.enterText(content, 'Cúp điện từ 09:00 đến 10:00 ngày mai.');
      await tester.tap(find.text('Gửi thử'));
      await tester.pumpAndSettle();
      expect(result?.title, 'Thông báo cúp điện');
      expect(
        result?.recipients,
        audience == 'all'
            ? ['101', '102', '201', '202']
            : audience == 'floor'
            ? ['201', '202']
            : ['102'],
      );
      expect(result?.propertyId, 'may');
      expect(tester.takeException(), isNull);
    });
  }
}
