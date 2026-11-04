import 'package:flutter/foundation.dart';

import 'models/tenant_room_listing.dart';

class TenantFavoritesStore {
  TenantFavoritesStore._();

  static final Set<String> roomNames = <String>{};
  static final changes = ValueNotifier<int>(0);
  static final Map<String, TenantRoomListing> _knownRooms = {};

  static bool contains(String roomName) => roomNames.contains(roomName);

  static List<TenantRoomListing> get savedListings => _knownRooms.values
      .where((room) => contains(room.id))
      .toList(growable: false);

  static void remember(TenantRoomListing room) {
    _knownRooms[room.id] = room;
  }

  static void toggle(String roomName) {
    if (!roomNames.add(roomName)) roomNames.remove(roomName);
    changes.value++;
  }
}
