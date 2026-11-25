import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';
import 'package:quanlytro/pages/tenant/viewings/components/tenant_viewing_request_sheet.dart';
import 'package:quanlytro/pages/tenant/viewings/models/tenant_viewing_request.dart';

void main() {
  testWidgets(
    'Viewing date uses the Vietnamese calendar and stays separate from time and guests',
    (tester) async {
      DateTime? submittedAt;
      int? submittedAttendees;
      String? submittedNeeds;
      final room = TenantRoomListing(
        name: 'Phòng 101',
        address: 'Đường thử, TP. Hồ Chí Minh',
        price: 2500000,
        size: '25 m²',
        distance: '',
        roomType: 'Studio',
        city: 'TP. Hồ Chí Minh',
        ward: 'Phường 1',
        distanceMeters: 0,
        electricityPrice: 3500,
        waterType: 'Theo m³',
        waterPrice: 15000,
        variant: 0,
        rating: '—',
        tags: const [],
        listingId: 'room-101',
        ownerPropertyId: 'property-1',
        roomCode: '101',
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi', 'VN'),
          supportedLocales: const [Locale('vi', 'VN')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    final request =
                        await showModalBottomSheet<TenantViewingRequest>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => TenantViewingRequestSheet(
                            room: room,
                            initialName: 'Người thuê',
                            initialPhone: '0901234567',
                          ),
                        );
                    submittedAt = request?.startsAt;
                    submittedAttendees = request?.attendeeCount;
                    submittedNeeds = request?.personalNeeds;
                  },
                  child: const Text('Đặt lịch'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Đặt lịch'));
      await tester.pumpAndSettle();
      final initialDateText = tester
          .widget<Text>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(widget.data ?? ''),
            ),
          )
          .data;
      expect(initialDateText, isNotNull);
      expect(find.text('Ngày muốn xem'), findsOneWidget);
      expect(find.text('Giờ mong muốn'), findsOneWidget);
      expect(find.text('Số người cùng đến xem'), findsOneWidget);

      await tester.tap(find.text(initialDateText!));
      await tester.pumpAndSettle();
      expect(find.text('Chọn ngày muốn đến xem phòng'), findsOneWidget);
      final localizedMonth = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data?.toLowerCase().startsWith('tháng') == true,
      );
      final localizedCancelText = find.text('Huỷ');
      expect(localizedMonth, findsOneWidget);
      expect(localizedCancelText, findsOneWidget);
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      expect(find.text(initialDateText), findsOneWidget);

      final targetDate = DateTime.now().add(const Duration(days: 1));
      await tester.tap(find.text(initialDateText));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${targetDate.day}').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();
      final selectedDateText =
          '${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}';
      expect(find.text(selectedDateText), findsOneWidget);

      final attendeesField = find.byType(DropdownButtonFormField<int>);
      await tester.ensureVisible(attendeesField);
      await tester.tap(attendeesField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('3 người'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Cần chỗ để xe');
      await tester.ensureVisible(find.text('Gửi yêu cầu đặt lịch'));
      await tester.tap(find.text('Gửi yêu cầu đặt lịch'));
      await tester.pumpAndSettle();
      expect(submittedAt, isNotNull);
      expect(submittedAt!.year, targetDate.year);
      expect(submittedAt!.month, targetDate.month);
      expect(submittedAt!.day, targetDate.day);
      expect(submittedAt!.hour, 10);
      expect(submittedAttendees, 3);
      expect(submittedNeeds, 'Cần chỗ để xe');
      expect(submittedAt!.isAfter(DateTime.now()), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
