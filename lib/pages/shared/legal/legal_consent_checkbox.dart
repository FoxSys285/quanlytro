import 'package:flutter/material.dart';

import '../auth/auth_flow_widgets.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

class LegalConsentCheckbox extends StatelessWidget {
  const LegalConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Checkbox.adaptive(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: authGreen,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 1,
            runSpacing: 0,
            children: [
              const Text(
                'Tôi đã đọc và đồng ý với ',
                style: TextStyle(color: authMuted, fontSize: 12, height: 1.6),
              ),
              _link(context, 'Điều khoản sử dụng', const TermsOfServicePage()),
              const Text(
                ' và ',
                style: TextStyle(color: authMuted, fontSize: 12, height: 1.6),
              ),
              _link(context, 'Chính sách bảo mật', const PrivacyPolicyPage()),
              const Text(
                '.',
                style: TextStyle(color: authMuted, fontSize: 12, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _link(BuildContext context, String label, Widget page) => TextButton(
    onPressed: enabled
        ? () async {
            await Navigator.of(context)
                .push<void>(MaterialPageRoute(builder: (_) => page));
          }
        : null,
    style: TextButton.styleFrom(
      foregroundColor: authGreen,
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 30),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(
        fontSize: 12,
        height: 1.5,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
      ),
    ),
    child: Text(label),
  );
}
