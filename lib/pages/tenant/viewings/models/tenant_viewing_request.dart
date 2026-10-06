class TenantViewingRequest {
  const TenantViewingRequest({
    required this.customerName,
    required this.phone,
    required this.startsAt,
    required this.attendeeCount,
    required this.personalNeeds,
  });

  final String customerName;
  final String phone;
  final DateTime startsAt;
  final int attendeeCount;
  final String personalNeeds;
}
