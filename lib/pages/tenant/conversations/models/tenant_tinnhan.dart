class TenantConversationMessage {
  const TenantConversationMessage({
    required this.text,
    required this.time,
    required this.fromTenant,
  });

  final String text;
  final String time;
  final bool fromTenant;
}
