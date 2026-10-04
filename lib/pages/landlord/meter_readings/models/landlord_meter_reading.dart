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

  bool get isDone => newElectric != null && newWater != null;
  int get electricUsage => (newElectric ?? oldElectric) - oldElectric;
  int get waterUsage => (newWater ?? oldWater) - oldWater;
}
