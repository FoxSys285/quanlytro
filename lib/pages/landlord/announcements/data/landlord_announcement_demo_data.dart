import '../models/landlord_announcement.dart';
import '../../landlord_demo_store.dart';
import '../../../shared/announcements/announcement_store.dart';

class LandlordAnnouncementDemoData {
  static List<AnnouncementProperty> get properties => [
    AnnouncementProperty(
      id: LandlordDemoStore.activeInstance.property.id,
      name: LandlordDemoStore.activeInstance.property.name,
      rooms: LandlordDemoStore.activeInstance.roomFloors,
    ),
  ];
  static List<LandlordAnnouncement> inbox(DateTime now) =>
      AnnouncementStore.forRental(LandlordDemoStore.activeInstance).inbox;
}
