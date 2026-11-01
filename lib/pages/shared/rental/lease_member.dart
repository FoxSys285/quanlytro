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

  Map<String, dynamic> toMap() => {
    'id': id,
    'leaseId': leaseId,
    'tenantId': tenantId,
    'name': name,
    'phone': phone,
    'joinedAt': joinedAt.toIso8601String(),
    'isRepresentative': isRepresentative,
    'status': status.name,
    'rejectionReason': rejectionReason,
  };

  factory LeaseMember.fromMap(Map<String, dynamic> map) => LeaseMember(
    id: map['id'] as String,
    leaseId: map['leaseId'] as String,
    tenantId: map['tenantId'] as String,
    name: map['name'] as String,
    phone: map['phone'] as String,
    joinedAt: DateTime.parse(map['joinedAt'] as String),
    isRepresentative: map['isRepresentative'] as bool,
    status: LeaseMemberStatus.values.byName(map['status'] as String),
    rejectionReason: map['rejectionReason'] as String?,
  );
}
