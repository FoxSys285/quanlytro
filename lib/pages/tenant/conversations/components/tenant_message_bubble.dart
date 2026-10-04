import 'package:flutter/material.dart';

import '../models/tenant_conversation_message.dart';
import '../../tenant_ui.dart';

class TenantMessageBubble extends StatelessWidget {
  const TenantMessageBubble({required this.message});
  final TenantConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final isTenant = message.fromTenant;
    return Align(
      alignment: isTenant ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 7),
        decoration: BoxDecoration(
          color: isTenant ? tenantGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isTenant ? 16 : 4),
            bottomRight: Radius.circular(isTenant ? 4 : 16),
          ),
          border: isTenant ? null : Border.all(color: tenantLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isTenant ? Colors.white : tenantInk,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              message.time,
              style: TextStyle(
                color: isTenant ? Colors.white70 : tenantMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
