import 'package:quanlytro/pages/landlord/landlord_demo_store.dart';

LandlordDemoStore landlordRedesignFixture() {
  final store = LandlordDemoStore.demo();
  final data = store.toMap();
  final now = DateTime.now();
  final period = DateTime(now.year, now.month).toIso8601String();
  for (final lease in data['leases'] as List) {
    lease['startDate'] = DateTime(2000).toIso8601String();
    lease['endDate'] = DateTime(2100).toIso8601String();
  }
  for (final invoice in data['invoices'] as List) {
    invoice['period'] = period;
    invoice['dueDate'] = DateTime(now.year, now.month, 10).toIso8601String();
  }
  store.restore(data);
  return store;
}
