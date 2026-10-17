import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/layouts/landlord_layout.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/pages/shared/help/help_content.dart';
import 'package:quanlytro/pages/shared/help/help_page.dart';

void main() {
  for (final role in [AppRole.tenant, AppRole.landlord]) {
    for (final width in [390.0, 1280.0]) {
      testWidgets('Help navigation, guides and search for $role at $width', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          MaterialApp(
            home: role == AppRole.tenant
                ? const TenantLayout()
                : const LandlordLayout(),
          ),
        );
        await tester.tap(find.byTooltip('Mở danh mục chức năng'));
        await tester.pumpAndSettle();
        final support = find.widgetWithText(ListTile, 'Trợ giúp');
        await tester.ensureVisible(support);
        await tester.tap(support);
        await tester.pumpAndSettle();
        expect(find.byType(HelpPage), findsOneWidget);
        expect(
          find.text('DÀNH CHO ${role.label.toUpperCase()}'),
          findsOneWidget,
        );

        await tester.tap(find.text('Xem hướng dẫn từng bước').first);
        await tester.pumpAndSettle();
        final guide = helpArticlesFor(role).first;
        expect(find.text(guide.answer), findsOneWidget);
        await tester.ensureVisible(find.text('Đã hiểu'));
        await tester.tap(find.text('Đã hiểu'));
        await tester.pumpAndSettle();
        expect(find.text(guide.answer), findsNothing);

        await tester.enterText(find.byType(TextField), 'ho so ca nhan');
        await tester.pumpAndSettle();
        expect(find.byType(ExpansionTile), findsOneWidget);
        final profileQuestion = find.text('Chỉnh sửa hồ sơ cá nhân ở đâu?');
        await tester.ensureVisible(profileQuestion);
        await tester.tap(profileQuestion);
        await tester.pumpAndSettle();
        expect(find.textContaining('Mở Tài khoản → Cài đặt'), findsOneWidget);

        // A category and search must both match; resetting restores all articles.
        final category = role == AppRole.tenant ? 'Tìm phòng' : 'Quản lý nhà';
        final chip = find.widgetWithText(ChoiceChip, category);
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(find.text('Chưa tìm thấy hướng dẫn phù hợp'), findsOneWidget);
        final reset = find.text('Xem tất cả câu hỏi');
        await tester.ensureVisible(reset);
        await tester.tap(reset);
        await tester.pumpAndSettle();
        expect(
          find.byType(ExpansionTile),
          findsNWidgets(helpArticlesFor(role).length),
        );

        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(find.byType(ExpansionTile), findsOneWidget);
        expect(find.text(guide.question), findsOneWidget);

        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final copy = find.text('Sao chép mẫu mô tả');
        await tester.ensureVisible(copy);
        await tester.tap(copy);
        await tester.pumpAndSettle();
        expect(copied, contains('Vai trò: ${role.label}'));
        expect(copied, contains('Màn hình gặp vấn đề:'));
        expect(find.text('Đã sao chép mẫu mô tả vấn đề.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
