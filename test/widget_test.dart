import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/main.dart';
import 'package:quanlytro/layouts/tenant_layout.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_discovery_page.dart';

void main() {
  testWidgets('App opens the tenant discovery page by default', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(TenantLayout), findsOneWidget);
    expect(find.byType(TenantDiscoveryPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
