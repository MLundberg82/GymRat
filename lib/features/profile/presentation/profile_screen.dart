import 'package:flutter/material.dart';

import '../../../core/localization/app_language_store.dart';
import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String selected = AppLanguageStore.currentCode();

  Future<void> _change(String? value) async {
    if (value == null) return;
    await AppLanguageStore.setLanguage(value);
    if (mounted) setState(() => selected = value);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    return Scaffold(
      backgroundColor: GymRatColors.black,
      appBar: AppBar(
        backgroundColor: GymRatColors.black,
        foregroundColor: GymRatColors.textPrimary,
        title: Text(
          t.t('settings'),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            t.t('appLanguage'),
            style: const TextStyle(
              color: GymRatColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.t('languageHelp'),
            style: const TextStyle(
              color: GymRatColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: GymRatColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GymRatColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                dropdownColor: GymRatColors.surfaceElevated,
                iconEnabledColor: GymRatColors.textSecondary,
                style: const TextStyle(
                  color: GymRatColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'system',
                    child: Text(t.t('systemDefault')),
                  ),
                  DropdownMenuItem(value: 'en', child: Text(t.t('english'))),
                  DropdownMenuItem(value: 'sv', child: Text(t.t('swedish'))),
                  DropdownMenuItem(value: 'es', child: Text(t.t('spanish'))),
                  DropdownMenuItem(value: 'ru', child: Text(t.t('russian'))),
                  DropdownMenuItem(value: 'zh', child: Text(t.t('chinese'))),
                ],
                onChanged: _change,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
