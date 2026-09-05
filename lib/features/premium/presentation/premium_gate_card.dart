import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../armory/presentation/armory_screen.dart';

class PremiumGateCard extends StatelessWidget {
  const PremiumGateCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 16 : 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(21),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF30204F), GymRatColors.surface, Color(0xFF0B0A0E)],
      ),
      border: Border.all(color: GymRatColors.premium.withValues(alpha: .55)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: GymRatColors.premium,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr.t('premiumBlueprint'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Benefit(text: context.tr.t('premiumBenefitHistory')),
        _Benefit(text: context.tr.t('premiumBenefitCoach')),
        _Benefit(text: context.tr.t('premiumBenefitInsights')),
        _Benefit(text: context.tr.t('premiumBenefitNutrition')),
        if (!compact) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ArmoryScreen(initialTab: 1),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: GymRatColors.premium,
                foregroundColor: GymRatColors.black,
              ),
              child: Text(context.tr.t('viewPremium')),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_rounded,
            color: GymRatColors.premium,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}
