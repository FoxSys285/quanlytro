import '../models/landlord_announcement.dart';
import '../../landlord_demo_store.dart';
import '../../../shared/announcements/announcement_store.dart';

class LandlordAnnouncementDemoData {
  static List<AnnouncementProperty> get properties => [
    AnnouncementProperty(
      id: LandlordDemoStore.instance.property.id,
      name: LandlordDemoStore.instance.property.name,
      rooms: LandlordDemoStore.rooms,
    ),
  ];
  static List<LandlordAnnouncement> inbox(DateTime now) =>
      AnnouncementStore.instance.inbox;
}
