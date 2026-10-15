import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/main.dart';
import 'package:quanlytro/pages/landlord/dashboard/landlord_tongquan_page.dart';
import 'package:quanlytro/pages/landlord/room_types/landlord_room_types_page.dart';

void main() {
  testWidgets('App opens the synchronized landlord dashboard and room types', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(LandlordTongQuanPage), findsOneWidget);
    expect(find.text('Tình hình nhà trọ Mây House hôm nay.'), findsOneWidget);
    expect(find.text('Danh sách nhà trọ'), findsNothing);
    await tester.tap(find.byTooltip('Mở danh mục chức năng'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Loại phòng'));
    await tester.tap(find.text('Loại phòng'));
    await tester.pumpAndSettle();
    expect(find.byType(LandlordRoomTypesPage), findsOneWidget);
    expect(find.text('Phòng có ban công'), findsOneWidget);
    expect(find.byTooltip('Xóa Phòng có ban công'), findsOneWidget);
    expect(find.text('Xem phòng'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
