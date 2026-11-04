import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/tenant_tinnhan.dart';
import '../../tenant_ui.dart';

class TenantMessageBubble extends StatelessWidget {
  const TenantMessageBubble({super.key, required this.message});

  final TenantConversationMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromTenant;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: math.min(constraints.maxWidth * 0.84, 560),
          ),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 9),
          decoration: BoxDecoration(
            color: mine ? tenantGreen : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 5),
              bottomRight: Radius.circular(mine ? 5 : 18),
            ),
            border: mine ? null : Border.all(color: tenantLine),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06102B1B),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SelectableText(
                message.text,
                style: TextStyle(
                  color: mine ? Colors.white : tenantInk,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message.time,
                style: TextStyle(
                  color: mine ? const Color(0xE6FFFFFF) : tenantMuted,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef TenantBongBongTinNhan = TenantMessageBubble;
