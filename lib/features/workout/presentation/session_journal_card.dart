import 'package:flutter/material.dart';

import '../../../core/localization/gymrat_localizations.dart';
import '../../../core/theme/gymrat_colors.dart';

class SessionJournalCard extends StatelessWidget {
  const SessionJournalCard({
    super.key,
    required this.noteController,
    required this.effortRating,
    required this.onEffortChanged,
    required this.onChanged,
  });

  final TextEditingController noteController;
  final int? effortRating;
  final ValueChanged<int?> onEffortChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: GymRatColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GymRatColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              size: 18,
              color: GymRatColors.gold,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr.t('sessionJournal'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          context.tr.t('effortRating'),
          style: const TextStyle(
            color: GymRatColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          children: [
            for (var value = 1; value <= 5; value++)
              ChoiceChip(
                label: Text('$value'),
                selected: effortRating == value,
                onSelected: (selected) {
                  onEffortChanged(selected ? value : null);
                  onChanged();
                },
                showCheckmark: false,
                selectedColor: value >= 4
                    ? GymRatColors.gold
                    : GymRatColors.green,
                backgroundColor: GymRatColors.surfaceElevated,
                labelStyle: TextStyle(
                  color: effortRating == value
                      ? GymRatColors.black
                      : GymRatColors.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: noteController,
          minLines: 1,
          maxLines: 3,
          maxLength: 240,
          onChanged: (_) => onChanged(),
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: context.tr.t('sessionNoteHint'),
            counterText: '',
            filled: true,
            fillColor: GymRatColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr.t('effortRatingHelp'),
          style: const TextStyle(
            color: GymRatColors.textMuted,
            fontSize: 9,
            height: 1.35,
          ),
        ),
      ],
    ),
  );
}
