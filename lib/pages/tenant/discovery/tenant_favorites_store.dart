import 'package:flutter/foundation.dart';

class TenantFavoritesStore {
  TenantFavoritesStore._();

  static final Set<String> roomNames = <String>{};
  static final changes = ValueNotifier<int>(0);

  static bool contains(String roomName) => roomNames.contains(roomName);

  static void toggle(String roomName) {
    if (!roomNames.add(roomName)) roomNames.remove(roomName);
    changes.value++;
  }
}
