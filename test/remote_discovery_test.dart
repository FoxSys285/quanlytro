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

class _SparseSource implements TenantCatalogSource {
  int calls = 0;
  final cursors = <Object?>[];

  @override
  Future<CatalogPage> fetch(
    TenantCatalogQuery query, {
    Object? after,
    int limit = 8,
  }) async {
    calls++;
    cursors.add(after);
    if (after == 'cursor-3') {
      return CatalogPage(items: [TenantRoomDemoData.listings[0]]);
    }
    final next = after == null
        ? 'cursor-1'
        : after == 'cursor-1'
        ? 'cursor-2'
        : 'cursor-3';
    return CatalogPage(items: const [], nextCursor: next);
  }
}

void main() {
  testWidgets('Online next page uses cursor, previous uses saved page', (
    tester,
  ) async {
    final source = _Source();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantDiscoveryPage(catalogSource: source, resultsOnly: true),
        ),
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

  testWidgets(
    'Sparse property groups pause within a read budget and resume explicitly',
    (tester) async {
      final source = _SparseSource();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TenantDiscoveryPage(catalogSource: source, resultsOnly: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(source.calls, 3);
      expect(find.text('Tiếp tục tìm'), findsOneWidget);
      expect(find.text('Chưa tìm thấy phòng phù hợp'), findsNothing);

      await tester.ensureVisible(find.text('Tiếp tục tìm'));
      await tester.tap(find.text('Tiếp tục tìm'));
      await tester.pumpAndSettle();
      expect(source.calls, 4);
      expect(source.cursors, [null, 'cursor-1', 'cursor-2', 'cursor-3']);
      expect(find.byType(TenantRoomCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Late old response cannot replace new filter results', (
    tester,
  ) async {
    final source = _Source();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TenantDiscoveryPage(catalogSource: source, resultsOnly: true),
        ),
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
