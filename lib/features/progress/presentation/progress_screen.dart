import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: AppBar(
        backgroundColor: GymRatColors.black,
        foregroundColor: GymRatColors.textPrimary,
        title: Text(
          context.tr.t('progressTitle'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.show_chart_rounded,
                color: GymRatColors.info,
                size: 42,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr.t('progressTitle'),
                style: const TextStyle(
                  color: GymRatColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.t('progressComingSoon'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GymRatColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
