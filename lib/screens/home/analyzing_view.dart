import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/live_thought_panel.dart';

/// Shown while a meal is being analysed: the first photo above a sheet with
/// the model's live reasoning.
class AnalyzingView extends StatelessWidget {
  final ImageProvider? heroImage;
  final String thoughtText;

  const AnalyzingView({
    super.key,
    required this.heroImage,
    required this.thoughtText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // 1. Background Image (Actual captured photo); a meal described in
        // words has none.
        if (heroImage == null)
          Positioned.fill(
            child: ColoredBox(color: AppColors.styrianForest),
          )
        else
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.35,
            child: Image(
              image: heroImage!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),

        // 2. Content Sheet
        Positioned(
          top: screenHeight * 0.3,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glacialWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: Column(
                children: [
                  // Header Text (Analyzing...)
                  Text(
                    l10n.analyzing,
                    style: AppTypography.displayMedium.copyWith(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Live Thought Summary Panel - Focused solely on reasoning stream
                  LiveThoughtPanel(
                    thoughtText: thoughtText,
                    titleLabel: l10n.aiThinkingTitle,
                    thinkingLabel: l10n.aiThinkingLabel,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
