import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';
import '../../armory/presentation/armory_screen.dart';
import 'premium_access_unlock.dart';

Future<void> showPremiumPaywall(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _PremiumPaywallSheet(),
  );
}

class _PremiumPaywallSheet extends StatelessWidget {
  const _PremiumPaywallSheet();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3C2167), Color(0xFF181020), GymRatColors.surface],
      ),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .24),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: context.tr.t('notNow'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 25),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .10),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Icon(
            Icons.workspace_premium_rounded,
            color: GymRatColors.premium,
            size: 46,
          ),
          const SizedBox(height: 13),
          Text(
            context.tr.t('premiumPaywallTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr.t('premiumPaywallHelp'),
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _PaywallBenefit(
            icon: Icons.bolt_rounded,
            title: context.tr.t('premiumXpBoost'),
            detail: context.tr.t('premiumXpBoostHelp'),
          ),
          _PaywallBenefit(
            icon: Icons.restaurant_menu_rounded,
            title: context.tr.t('nutritionCommandCenter'),
            detail: context.tr.t('premiumBenefitNutrition'),
          ),
          _PaywallBenefit(
            icon: Icons.insights_rounded,
            title: context.tr.t('premiumResultsTitle'),
            detail: context.tr.t('premiumBenefitHistory'),
          ),
          _PaywallBenefit(
            icon: Icons.psychology_rounded,
            title: context.tr.t('premiumCoach'),
            detail: context.tr.t('premiumBenefitCoach'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ArmoryScreen(initialTab: 1),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: GymRatColors.premium,
                foregroundColor: GymRatColors.black,
              ),
              child: Text(
                context.tr.t('viewPremium'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: .40)),
              ),
              child: Text(
                context.tr.t('notNow'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const PremiumAccessUnlock(compact: true),
        ],
      ),
    ),
  );
}

class _PaywallBenefit extends StatelessWidget {
  const _PaywallBenefit({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: GymRatColors.premium.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: GymRatColors.premium, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: GymRatColors.textSecondary,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
