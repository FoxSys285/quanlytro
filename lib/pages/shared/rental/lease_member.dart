enum LeaseMemberStatus { pending, active, rejected }

class LeaseMember {
  LeaseMember({
    required this.id,
    required this.leaseId,
    required this.tenantId,
    required this.name,
    required this.phone,
    required this.joinedAt,
    this.isRepresentative = false,
    this.status = LeaseMemberStatus.active,
    this.rejectionReason,
  });

  final String id;
  final String leaseId;
  final String tenantId;
  String name;
  String phone;
  DateTime joinedAt;
  final bool isRepresentative;
  LeaseMemberStatus status;
  String? rejectionReason;
}
