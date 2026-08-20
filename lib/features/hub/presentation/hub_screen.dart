import 'package:flutter/material.dart';

import '../../../core/theme/gymrat_colors.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const SizedBox(height: 24),
          const _LevelSection(),
          const SizedBox(height: 22),
          const Expanded(
            child: _CharacterPlaceholder(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.fitness_center_rounded,
                size: 22,
              ),
              label: const Text(
                'START WORKOUT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: GymRatColors.green,
                foregroundColor: GymRatColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'GYM',
                style: TextStyle(
                  color: GymRatColors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: 'RAT',
                style: TextStyle(
                  color: GymRatColors.green,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu_rounded),
          color: GymRatColors.textSecondary,
          tooltip: 'Menu',
        ),
      ],
    );
  }
}

class _LevelSection extends StatelessWidget {
  const _LevelSection();

  @override
  Widget build(BuildContext context) {
    const currentXp = 7650.0;
    const requiredXp = 9000.0;
    const progress = currentXp / requiredXp;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'LVL 23',
          style: TextStyle(
            color: GymRatColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: GymRatColors.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    GymRatColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                '7 650 / 9 000 XP',
                style: TextStyle(
                  color: GymRatColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CharacterPlaceholder extends StatelessWidget {
  const _CharacterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GymRatColors.surface,
            GymRatColors.black,
          ],
        ),
        border: Border.all(
          color: GymRatColors.border,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 20,
            left: 20,
            child: _StatBadge(
              icon: Icons.local_fire_department_rounded,
              value: '12',
              label: 'DAY STREAK',
            ),
          ),
          const Positioned(
            top: 20,
            right: 20,
            child: _StatBadge(
              icon: Icons.check_circle_outline_rounded,
              value: '3/3',
              label: 'DAILY GOAL',
            ),
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets_rounded,
                size: 106,
                color: GymRatColors.textMuted,
              ),
              SizedBox(height: 16),
              Text(
                'YOUR GYMRAT',
                style: TextStyle(
                  color: GymRatColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Character & gym environment coming next',
                style: TextStyle(
                  color: GymRatColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 19,
          color: GymRatColors.textSecondary,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: GymRatColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: GymRatColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}