import 'package:flutter/material.dart';

import '../../tenant_ui.dart';
import '../models/tenant_cuoctrochuyen.dart';

class TenantConversationCard extends StatelessWidget {
  const TenantConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final TenantConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unread > 0;
    final messages = conversation.messages;
    final last = messages.isEmpty ? null : messages.last;
    final preview = last == null
        ? 'Chưa có tin nhắn'
        : '${last.fromTenant ? 'Bạn: ' : ''}${last.text}';
    return TenantSurface(
      padding: EdgeInsets.zero,
      child: Ink(
        decoration: BoxDecoration(
          color: unread ? const Color(0xFFF3FBF6) : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TenantProfileAvatar(
                  name: conversation.landlordName,
                  radius: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.landlordName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tenantInk,
                                fontSize: 14,
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (last != null) ...[
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 65),
                              child: Text(
                                last.time,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: unread ? tenantGreenDark : tenantMuted,
                                  fontSize: 10,
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        conversation.contextLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: tenantMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unread ? tenantInk : tenantMuted,
                                fontSize: 12,
                                height: 1.5,
                                fontWeight: unread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 10),
                            Semantics(
                              label: '${conversation.unread} tin nhắn chưa đọc',
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 22),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: tenantGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  conversation.unread > 99
                                      ? '99+'
                                      : '${conversation.unread}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
