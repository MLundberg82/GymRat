import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const supportEmail = String.fromEnvironment(
    'GYMRAT_SUPPORT_EMAIL',
    defaultValue: 'support@gymrat.app',
  );

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr.t('supportEmailCopied'))));
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
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded),
                label: Text(context.tr.t('copyEmail')),
                style: FilledButton.styleFrom(
                  backgroundColor: GymRatColors.green,
                  foregroundColor: GymRatColors.black,
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
