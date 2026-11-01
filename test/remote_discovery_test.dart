import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlytro/data/discovery_catalog.dart';
import 'package:quanlytro/pages/tenant/discovery/tenant_discovery_page.dart';
import 'package:quanlytro/pages/tenant/discovery/components/tenant_room_card.dart';
import 'package:quanlytro/pages/tenant/discovery/models/tenant_room_listing.dart';

class _Source implements TenantCatalogSource {
  final queries = <TenantCatalogQuery>[];
  final cursors = <Object?>[];
  final pending = <Completer<CatalogPage>>[];
  @override
  Future<CatalogPage> fetch(
    TenantCatalogQuery query, {
    Object? after,
    int limit = 8,
  }) {
    queries.add(query);
    cursors.add(after);
    final result = Completer<CatalogPage>();
    pending.add(result);
    return result.future;
  }
}

void main() {
  testWidgets('Online next page uses cursor, previous uses saved page', (
    tester,
  ) async {
    final source = _Source();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TenantDiscoveryPage(catalogSource: source)),
      ),
    );
    await tester.pump();
    expect(source.pending.length, 1);
    source.pending[0].complete(
      CatalogPage(
        items: [TenantRoomDemoData.listings[0]],
        nextCursor: 'cursor-1',
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Trang tiếp theo'));
    await tester.tap(find.byTooltip('Trang tiếp theo'));
    await tester.pump();
    expect(source.cursors, [null, 'cursor-1']);
    source.pending[1].complete(
      CatalogPage(items: [TenantRoomDemoData.listings[1]]),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TenantRoomCard>(find.byType(TenantRoomCard)).room.id,
      TenantRoomDemoData.listings[1].id,
    );
    await tester.ensureVisible(find.byTooltip('Trang trước'));
    await tester.tap(find.byTooltip('Trang trước'));
    await tester.pumpAndSettle();
    expect(source.pending.length, 2);
    expect(
      tester.widget<TenantRoomCard>(find.byType(TenantRoomCard)).room.id,
      TenantRoomDemoData.listings[0].id,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Late old response cannot replace new filter results', (
    tester,
  ) async {
    final source = _Source();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TenantDiscoveryPage(catalogSource: source)),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Studio');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(source.pending.length, 2);
    expect(source.queries.last.query, 'Studio');
    expect(source.cursors.last, isNull);
    source.pending[1].complete(
      CatalogPage(items: [TenantRoomDemoData.listings[1]]),
    );
    await tester.pumpAndSettle();
    source.pending[0].complete(
      CatalogPage(items: [TenantRoomDemoData.listings[0]]),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TenantRoomCard>(find.byType(TenantRoomCard)).room.id,
      TenantRoomDemoData.listings[1].id,
    );
    expect(tester.takeException(), isNull);
  });
}
