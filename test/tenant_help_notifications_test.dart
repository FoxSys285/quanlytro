import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/admin_store.dart';
import 'package:quanlytro/layouts/role_layout.dart';
import 'package:quanlytro/pages/landlord/announcements/models/landlord_announcement.dart';
import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';
import 'package:quanlytro/pages/shared/announcements/announcement_store.dart';
import 'package:quanlytro/pages/shared/help/help_page.dart';
import 'package:quanlytro/pages/shared/help/support_tickets_page.dart';
import 'package:quanlytro/pages/shared/rental/tenant_session.dart';
import 'package:quanlytro/pages/shared/viewings/viewing_store.dart';
import 'package:quanlytro/pages/tenant/announcements/tenant_announcements_page.dart';
import 'package:quanlytro/pages/tenant/tenant_detail_ui.dart';
import 'package:quanlytro/pages/tenant/tenant_navigation_bar.dart';

import 'tenant_feature_ui_test.dart' show capture, loadPreviewFonts;

void main() {
  testWidgets(
    'Appbar bell opens the tenant inbox and unread dot updates after reading',
    (tester) async {
      final rental = LandlordDemoStore.demo();
      final viewings = ViewingStore([]);
      final inbox = AnnouncementStore(rental: rental, viewings: viewings);
      addTearDown(inbox.dispose);
      addTearDown(viewings.dispose);
      addTearDown(rental.dispose);
      for (final item in inbox.forTenant(TenantSession.tenantId)) {
        inbox.markTenantRead(item.id, TenantSession.tenantId);
      }
      inbox.send(
        LandlordAnnouncement(
          id: 'draft',
          title: 'Kiểm tra thông báo từ thanh công cụ',
          content: 'Thông tin nhà trọ dành cho người thuê hiện tại.',
          category: AnnouncementCategory.operations,
          createdAt: DateTime.now(),
          propertyId: rental.property.id,
          recipients: [
            rental.currentLeaseForTenant(TenantSession.tenantId)!.room,
          ],
        ),
      );
      Widget app(String tenant) => MaterialApp(
        home: Scaffold(
          appBar: TenantNavigationBar(
            title: 'Cài đặt',
            onBack: () {},
            notifications: inbox,
            tenantId: tenant,
          ),
          body: const Text('Trang đang xem'),
        ),
      );
      await tester.pumpWidget(app('tenant-unknown'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('tenant-appbar-notification-dot')),
        findsNothing,
      );
      await tester.pumpWidget(app(TenantSession.tenantId));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('tenant-appbar-notification-dot')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('tenant-appbar-notifications')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TenantAnnouncementsPage), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tenant-appbar-notifications')),
        findsNothing,
        reason: 'The notification inbox does not open another copy of itself',
      );
      final title = find.text('Kiểm tra thông báo từ thanh công cụ');
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(
            'Thông tin nhà trọ dành cho người thuê hiện tại.',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Trang đang xem'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tenant-appbar-notification-dot')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets(
      'Help and support requests fit and submit above keyboard at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetViewInsets);
        final previous = Map<String, dynamic>.from(
          jsonDecode(jsonEncode(AdminStore.instance.toMap())) as Map,
        );
        addTearDown(() => AdminStore.instance.restore(previous));
        final preview =
            Platform.environment['CAPTURE_TENANT_HELP'] == 'true' &&
            width == 390;
        if (preview) await loadPreviewFonts(tester);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: preview ? 'PreviewFont' : null,
              ),
              home: const TenantSubpageScaffold(
                title: 'Trợ giúp',
                child: HelpPage(role: AppRole.tenant),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('tenant-appbar-notifications')),
          findsOneWidget,
        );
        expect(find.text('Bạn cần trợ giúp gì?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (preview) await capture(tester, boundary, 'help');
        await tester.ensureVisible(find.text('Yêu cầu và phản hồi hỗ trợ'));
        await tester.tap(find.text('Yêu cầu và phản hồi hỗ trợ'));
        await tester.pumpAndSettle();
        expect(find.byType(SupportTicketsPage), findsOneWidget);
        expect(
          find.byKey(const ValueKey('tenant-appbar-notifications')),
          findsOneWidget,
        );
        if (preview) await capture(tester, boundary, 'support_tickets');
        await tester.tap(find.text('Gửi yêu cầu hỗ trợ'));
        await tester.pumpAndSettle();
        if (preview) await capture(tester, boundary, 'support_form');
        await tester.tap(find.text('Gửi yêu cầu'));
        await tester.pumpAndSettle();
        expect(
          find.text('Tiêu đề cần ít nhất 5 ký tự, nội dung ít nhất 10 ký tự.'),
          findsOneWidget,
        );
        final fields = find.byType(TextField);
        await tester.ensureVisible(fields.first);
        await tester.enterText(fields.first, 'Cần hỗ trợ kiểm tra hóa đơn');
        await tester.ensureVisible(fields.last);
        await tester.enterText(
          fields.last,
          'Tôi đang xem hóa đơn và cần được hướng dẫn đối chiếu thông tin.',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Gửi yêu cầu'));
        await tester.tap(find.text('Gửi yêu cầu'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(
          AdminStore.instance.tickets.first.title,
          'Cần hỗ trợ kiểm tra hóa đơn',
        );
        expect(AdminStore.instance.tickets.first.role, AppRole.tenant);
        expect(find.text('Cần hỗ trợ kiểm tra hóa đơn'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
