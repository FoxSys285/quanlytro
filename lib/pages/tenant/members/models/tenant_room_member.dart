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

class TenantRoomMembersDemoData {
  static const propertyName = 'Mây House';
  static const roomName = 'A.302';
  static const capacity = 4;
  static const members = [
    TenantRoomMember(
      name: 'Nguyễn Minh Anh',
      initials: 'MA',
      phone: '0900000001',
      joinedAt: '01/06/2026',
      isRepresentative: true,
      isCurrentUser: true,
    ),
    TenantRoomMember(
      name: 'Trần Thảo Linh',
      initials: 'TL',
      phone: '0900000007',
      joinedAt: '10/06/2026',
    ),
  ];
}
