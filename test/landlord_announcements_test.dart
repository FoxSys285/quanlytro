import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/pages/landlord/announcements/components/landlord_announcement_card.dart';
import 'package:quanlytro/pages/landlord/announcements/components/landlord_announcement_composer.dart';
import 'package:quanlytro/pages/landlord/announcements/data/landlord_announcement_demo_data.dart';
import 'package:quanlytro/pages/landlord/announcements/landlord_announcements_page.dart';
import 'package:quanlytro/pages/landlord/announcements/models/landlord_announcement.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';

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
      expect(find.text('Tất cả nhà trọ'), findsNothing);
      expect(find.text('Nhà Nâu'), findsNothing);
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
                    builder: (_) => LandlordAnnouncementComposer(
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
          find
              .text(audience == 'floor' ? 'Theo tầng' : 'Chọn nhiều phòng')
              .last,
        );
        await tester.pumpAndSettle();
        if (audience == 'floor') {
          await tester.tap(find.byType(DropdownButtonFormField<String>).last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Tầng 2').last);
        } else {
          await tester.tap(find.widgetWithText(FilterChip, 'Phòng 102'));
        }
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
            ? LandlordDemoStore.rooms.keys.toList()
            : audience == 'floor'
            ? ['201', '202']
            : ['102'],
      );
      expect(result?.propertyId, 'may');
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [390.0, 1280.0]) {
    testWidgets(
      'Choose exact rooms across floors, deselect and validate at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
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
                      builder: (_) => LandlordAnnouncementComposer(
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
        await tester.tap(find.text('Tất cả các phòng trong nhà trọ'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chọn nhiều phòng').last);
        await tester.pumpAndSettle();
        expect(find.text('Nhận thông báo: 0 phòng'), findsOneWidget);
        final fields = find.byType(TextFormField);
        await tester.ensureVisible(fields.at(0));
        await tester.enterText(fields.at(0), 'Kiểm tra điện');
        await tester.ensureVisible(fields.at(1));
        await tester.enterText(
          fields.at(1),
          'Chủ trọ kiểm tra điện vào chiều mai.',
        );
        await tester.tap(find.text('Gửi thử'));
        await tester.pumpAndSettle();
        expect(result, isNull);
        expect(
          find.text('Chọn ít nhất một phòng nhận thông báo.'),
          findsOneWidget,
        );

        Future<void> choose(String code) async {
          final chip = find.widgetWithText(FilterChip, 'Phòng $code');
          await tester.ensureVisible(chip);
          await tester.tap(chip);
          await tester.pumpAndSettle();
        }

        await choose('101');
        await choose('201');
        expect(
          find.text('Nhận thông báo: 2 phòng\nPhòng 101, 201'),
          findsOneWidget,
        );
        await choose('101');
        await choose('102');
        expect(
          find.text('Nhận thông báo: 2 phòng\nPhòng 102, 201'),
          findsOneWidget,
        );

        // A new audience mode must not retain hidden selections.
        await tester.ensureVisible(find.text('Chọn nhiều phòng'));
        await tester.tap(find.text('Chọn nhiều phòng'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Theo tầng').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tầng 2').last);
        await tester.pumpAndSettle();
        expect(
          find.text('Nhận thông báo: 2 phòng\nPhòng 201, 202'),
          findsOneWidget,
        );
        await tester.tap(find.text('Theo tầng'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chọn nhiều phòng').last);
        await tester.pumpAndSettle();
        expect(find.text('Nhận thông báo: 0 phòng'), findsOneWidget);
        await choose('102');
        await choose('201');
        await tester.tap(find.text('Gửi thử'));
        await tester.pumpAndSettle();
        expect(result!.recipients, ['102', '201']);
        expect(result!.propertyId, 'may');
        expect(result!.audienceLabel, 'Các phòng được chọn (2)');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
