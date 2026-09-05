import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../data/premium_local_access.dart';

class PremiumAccessUnlock extends StatelessWidget {
  const PremiumAccessUnlock({super.key, this.compact = false});

  final bool compact;

  Future<void> _enterCode(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr.t('premiumAccessCode')),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: context.tr.t('premiumAccessCode'),
          ),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(context.tr.t('unlockPremium')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || !context.mounted) return;
    final unlocked = await PremiumLocalAccess.unlockWithCode(code);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr.t(unlocked ? 'localPremiumEnabled' : 'invalidPremiumCode'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode && !PremiumLocalAccess.codeUnlockConfigured) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: PremiumLocalAccess.active,
      builder: (context, active, _) => Container(
        padding: EdgeInsets.all(compact ? 13 : 17),
        decoration: BoxDecoration(
          color: GymRatColors.premium.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: GymRatColors.premium.withValues(alpha: .36),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  active ? Icons.verified_rounded : Icons.key_rounded,
                  color: GymRatColors.premium,
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    context.tr.t('localPremiumAccess'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 7),
              Text(
                context.tr.t('localPremiumAccessHelp'),
                style: const TextStyle(
                  color: GymRatColors.textMuted,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 11),
            if (active)
              OutlinedButton(
                onPressed: PremiumLocalAccess.revoke,
                child: Text(context.tr.t('disableLocalPremium')),
              )
            else ...[
              if (PremiumLocalAccess.codeUnlockConfigured)
                OutlinedButton.icon(
                  onPressed: () => _enterCode(context),
                  icon: const Icon(Icons.password_rounded),
                  label: Text(context.tr.t('enterAccessCode')),
                ),
              if (kDebugMode) ...[
                if (PremiumLocalAccess.codeUnlockConfigured)
                  const SizedBox(height: 7),
                OutlinedButton.icon(
                  onPressed: PremiumLocalAccess.enableDebugAccess,
                  icon: const Icon(Icons.bug_report_outlined),
                  label: Text(context.tr.t('enableDebugPremium')),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
