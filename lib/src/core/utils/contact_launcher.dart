import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactLauncher {
  const ContactLauncher._();

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static Future<bool> call(String phoneNumber) async {
    final String digits = digitsOnly(phoneNumber);
    if (digits.isEmpty) return false;
    return launchUrl(Uri(scheme: 'tel', path: digits), mode: LaunchMode.externalApplication);
  }

  static Future<bool> email(String emailAddress) async {
    final String email = emailAddress.trim();
    if (email.isEmpty || !email.contains('@')) return false;
    return launchUrl(Uri(scheme: 'mailto', path: email), mode: LaunchMode.externalApplication);
  }
}

class ContactTextButton extends StatelessWidget {
  const ContactTextButton.phone({
    super.key,
    required this.value,
    this.label,
    this.alignEnd = false,
  }) : _type = _ContactActionType.phone;

  const ContactTextButton.email({
    super.key,
    required this.value,
    this.label,
    this.alignEnd = false,
  }) : _type = _ContactActionType.email;

  final String value;
  final String? label;
  final bool alignEnd;
  final _ContactActionType _type;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String display = label ?? value;
    final IconData icon = _type == _ContactActionType.phone
        ? Icons.call_rounded
        : Icons.mail_outline_rounded;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () async {
        final bool opened = _type == _ContactActionType.phone
            ? await ContactLauncher.call(value)
            : await ContactLauncher.email(value);
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_type == _ContactActionType.phone ? 'Unable to open dialer.' : 'Unable to open email app.')),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 15, color: theme.colorScheme.primary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ContactActionType { phone, email }
