/// In-memory favorites for the tenant UI preview.
///
/// This deliberately stays local to the app session; it is not connected to a
/// backend or persistent storage.
class TenantFavoritesStore {
  TenantFavoritesStore._();

  static final Set<String> roomNames = <String>{};

  static bool contains(String roomName) => roomNames.contains(roomName);

  static void toggle(String roomName) {
    if (!roomNames.add(roomName)) roomNames.remove(roomName);
  }
}
