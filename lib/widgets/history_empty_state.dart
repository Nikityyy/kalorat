import 'package:flutter/material.dart';

import '../extensions/l10n_extension.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'meal_card.dart';

/// What the history is for, shown while nothing is logged yet, with an example
/// of how a logged meal looks. The example is only drawn here, never saved.
class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final example = MealModel(
      id: 'example',
      timestamp: DateTime.now(),
      photoPaths: const [],
      mealName: l10n.sampleMealName,
      calories: 380,
      protein: 12,
      carbs: 62,
      fats: 8,
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.restaurant_menu,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.historyEmptyTitle,
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.historyEmptyBody,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.historyExampleLabel,
                  style: AppTypography.bodySmall,
                ),
              ),
              const SizedBox(height: 4),
              // Not a real entry: it takes no taps and says so to screen readers.
              ExcludeSemantics(
                child: IgnorePointer(
                  child: Opacity(opacity: 0.7, child: MealCard(meal: example)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
