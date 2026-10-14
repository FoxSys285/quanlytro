class TenantRoomMember {
  const TenantRoomMember({
    required this.name,
    required this.initials,
    required this.phone,
    required this.joinedAt,
    this.isRepresentative = false,
    this.isCurrentUser = false,
  });

  final String name;
  final String initials;
  final String phone;
  final String joinedAt;
  final bool isRepresentative;
  final bool isCurrentUser;
}
