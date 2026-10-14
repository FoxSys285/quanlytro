/// Identity used by the role preview until authentication is implemented.
/// All tenant features must scope records by this ID, never by name or room.
class TenantSession {
  static const tenantId = 'tenant-demo';
  static const name = 'Minh Anh';
  static const phone = '0901 234 567';
}
