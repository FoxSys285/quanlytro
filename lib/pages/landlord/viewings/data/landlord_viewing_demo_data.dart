import '../../../shared/viewings/viewing_store.dart';
import '../../landlord_demo_store.dart';
import '../models/landlord_viewing.dart';

class LandlordViewingDemoData {
  static List<LandlordViewing> create({DateTime? referenceDate}) {
    final property = LandlordDemoStore.instance.property;
    final store = ViewingStore.demo(
      referenceDate: referenceDate,
      propertyName: property.name,
      address: property.address,
    );
    final records = store.records;
    store.dispose();
    return records;
  }
}
