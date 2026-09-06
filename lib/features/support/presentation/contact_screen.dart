import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const supportEmail = String.fromEnvironment(
    'GYMRAT_SUPPORT_EMAIL',
    defaultValue: 'hello@getgymrat.com',
  );

  static final Uri websiteUri = Uri.parse('https://getgymrat.com');
  static final Uri privacyUri = Uri.parse('https://getgymrat.com/privacy');
  static final Uri termsUri = Uri.parse('https://getgymrat.com/terms');

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr.t('supportEmailCopied'))));
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr.t('openLinkFailed'))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: GymRatColors.black,
    appBar: AppBar(
      backgroundColor: GymRatColors.black,
      foregroundColor: GymRatColors.textPrimary,
      title: Text(
        context.tr.t('contactSupport'),
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF12291D), GymRatColors.surface],
            ),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: GymRatColors.greenDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: GymRatColors.green,
                size: 34,
              ),
              const SizedBox(height: 15),
              Text(
                context.tr.t('supportTitle'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                context.tr.t('supportHelp'),
                style: const TextStyle(
                  color: GymRatColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SelectableText(
                supportEmail,
                style: const TextStyle(
                  color: GymRatColors.green,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _open(
                  context,
                  Uri(
                    scheme: 'mailto',
                    path: supportEmail,
                    queryParameters: const {'subject': 'GymRat support'},
                  ),
                ),
                icon: const Icon(Icons.mail_outline_rounded),
                label: Text(context.tr.t('emailSupport')),
                style: FilledButton.styleFrom(
                  backgroundColor: GymRatColors.green,
                  foregroundColor: GymRatColors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded),
                label: Text(context.tr.t('copyEmail')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SupportLink(
          icon: Icons.language_rounded,
          label: context.tr.t('openWebsite'),
          onTap: () => _open(context, websiteUri),
        ),
        const SizedBox(height: 9),
        _SupportLink(
          icon: Icons.privacy_tip_outlined,
          label: context.tr.t('privacyPolicy'),
          onTap: () => _open(context, privacyUri),
        ),
        const SizedBox(height: 9),
        _SupportLink(
          icon: Icons.gavel_rounded,
          label: context.tr.t('termsOfUse'),
          onTap: () => _open(context, termsUri),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: GymRatColors.surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: GymRatColors.gold.withValues(alpha: .4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.health_and_safety_outlined,
                    color: GymRatColors.gold,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr.t('healthDisclaimerTitle'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                context.tr.t('healthDisclaimerBody'),
                style: const TextStyle(
                  color: GymRatColors.textSecondary,
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr.t('dataHandlingSummary'),
                style: const TextStyle(
                  color: GymRatColors.textMuted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr.t('supportResponseNote'),
          style: const TextStyle(
            color: GymRatColors.textMuted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _SupportLink extends StatelessWidget {
  const _SupportLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: GymRatColors.surface,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: GymRatColors.green, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              color: GymRatColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}
