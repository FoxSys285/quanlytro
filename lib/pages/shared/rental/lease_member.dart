enum LeaseMemberStatus { pending, active, rejected, left }

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
    this.requestedBy,
    this.requestedAt,
    this.identityFrontPath,
    this.identityBackPath,
    this.portraitPath,
    this.leaveReason,
    this.leaveRequestedAt,
    this.leaveEffectiveAt,
    this.leaveAcknowledgedAt,
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
  String? identityFrontPath;
  String? identityBackPath;
  String? portraitPath;
  String? leaveReason;
  DateTime? leaveRequestedAt;
  DateTime? leaveEffectiveAt;
  DateTime? leaveAcknowledgedAt;

  bool get hasIdentityDocuments =>
      (identityFrontPath ?? '').isNotEmpty &&
      (identityBackPath ?? '').isNotEmpty &&
      (portraitPath ?? '').isNotEmpty;

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
    'requestedBy': requestedBy,
    'requestedAt': requestedAt?.toIso8601String(),
    'identityFrontPath': identityFrontPath,
    'identityBackPath': identityBackPath,
    'portraitPath': portraitPath,
    'leaveReason': leaveReason,
    'leaveRequestedAt': leaveRequestedAt?.toIso8601String(),
    'leaveEffectiveAt': leaveEffectiveAt?.toIso8601String(),
    'leaveAcknowledgedAt': leaveAcknowledgedAt?.toIso8601String(),
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
    requestedBy: map['requestedBy'] as String?,
    requestedAt: map['requestedAt'] == null
        ? null
        : DateTime.parse(map['requestedAt'] as String),
    identityFrontPath: map['identityFrontPath'] as String?,
    identityBackPath: map['identityBackPath'] as String?,
    portraitPath: map['portraitPath'] as String?,
    leaveReason: map['leaveReason'] as String?,
    leaveRequestedAt: map['leaveRequestedAt'] == null
        ? null
        : DateTime.parse(map['leaveRequestedAt'] as String),
    leaveEffectiveAt: map['leaveEffectiveAt'] == null
        ? null
        : DateTime.parse(map['leaveEffectiveAt'] as String),
    leaveAcknowledgedAt: map['leaveAcknowledgedAt'] == null
        ? null
        : DateTime.parse(map['leaveAcknowledgedAt'] as String),
  );
  final String? requestedBy;
  final DateTime? requestedAt;
}
