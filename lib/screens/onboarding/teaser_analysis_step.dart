import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../widgets/inputs/action_button.dart';
import '../../extensions/l10n_extension.dart';

class TeaserAnalysisStep extends StatelessWidget {
  final int age;
  final int genderIndex;
  final double height;
  final double weight;
  final int activityLevelIndex;
  final int goalIndex;
  final VoidCallback onNext;

  const TeaserAnalysisStep({
    super.key,
    required this.age,
    required this.genderIndex,
    required this.height,
    required this.weight,
    required this.activityLevelIndex,
    required this.goalIndex,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    
    // Create a temporary user model just to calculate targets
    final tempUser = UserModel(
      name: "Guest",
      birthdate: DateTime(DateTime.now().year - age, 1, 1),
      height: height,
      weight: weight,
      gender: genderIndex,
      activityLevel: activityLevelIndex,
      goal: goalIndex,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.styrianForest, size: 80),
          const SizedBox(height: 24),
          Text(l10n.planReady, style: AppTypography.displayMedium, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(l10n.basedOnProfile, textAlign: TextAlign.center, style: AppTypography.bodyLarge),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.styrianForest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.styrianForest.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Text(
                  "${tempUser.dailyCalorieTarget.round()} kcal",
                  style: AppTypography.heroNumber.copyWith(color: AppColors.styrianForest, fontSize: 48),
                ),
                Text(l10n.dailyCalorieTarget, style: AppTypography.labelLarge.copyWith(color: AppColors.styrianForest)),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(l10n.signUpToSave, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
          const Spacer(),
          ActionButton(
            text: l10n.createAccount,
            onPressed: onNext,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
