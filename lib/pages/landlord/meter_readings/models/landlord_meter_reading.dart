class LandlordMeterReading {
  LandlordMeterReading({
    required this.room,
    required this.oldElectric,
    required this.oldWater,
    this.newElectric,
    this.newWater,
  });

  final String room;
  final int oldElectric;
  final int oldWater;
  int? newElectric;
  int? newWater;

  bool get isDone {
    if (newElectric != null && newWater != null) {
      return true;
    } else {
      return false;
    }
  }

  int get electricUsage {
    if (newElectric != null) {
      return newElectric! - oldElectric;
    } else {
      return 0;
    }
  }

  int get waterUsage {
    if (newWater != null) {
      return newWater! - oldWater;
    } else {
      return 0;
    }
  }
}
