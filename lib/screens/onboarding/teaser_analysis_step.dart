import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../widgets/inputs/action_button.dart';
import '../../extensions/l10n_extension.dart';
import '../../widgets/common/mono_digits.dart';

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

    // The plan is revealed on a Styrian Forest field: the one place the
    // brand colour fills the screen, with the summit the days will climb to.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.styrianForestColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 120,
                    child: CustomPaint(painter: _SummitPainter()),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.planReady,
                          style: AppTypography.heading.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.basedOnProfile,
                          style: AppTypography.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const Spacer(),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            '${tempUser.dailyCalorieTarget.round()}',
                            style: AppTypography.hero(
                              size: 96,
                            ).copyWith(color: Colors.white),
                          ),
                        ),
                        Text(
                          l10n.kcalPerDayPlan,
                          style: AppTypography.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 10),
                        MonoDigits(
                          l10n.proteinPerDayPlan(
                            tempUser.dailyProteinTarget.round(),
                          ),
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.signUpToSave,
            style: AppTypography.secondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ActionButton(text: l10n.createAccount, onPressed: onNext),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// A ridge in a lighter green along the bottom of the plan field.
class _SummitPainter extends CustomPainter {
  const _SummitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final back = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.62)
      ..lineTo(w * 0.22, h * 0.38)
      ..lineTo(w * 0.36, h * 0.55)
      ..lineTo(w * 0.58, h * 0.12)
      ..lineTo(w * 0.74, h * 0.42)
      ..lineTo(w * 0.86, h * 0.3)
      ..lineTo(w, h * 0.5)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      back,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    final front = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.85)
      ..lineTo(w * 0.3, h * 0.6)
      ..lineTo(w * 0.48, h * 0.78)
      ..lineTo(w * 0.7, h * 0.52)
      ..lineTo(w, h * 0.8)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      front,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(_SummitPainter oldDelegate) => false;
}
