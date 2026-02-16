import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class OnboardingImageWidget extends StatelessWidget {
  final String assetName;
  final double height;

  const OnboardingImageWidget({
    super.key,
    this.assetName = 'assets/onboarding_placeholder.webp',
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.steel,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.borderGrey, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 64,
                color: AppColors.styrianForest,
              ),
              const SizedBox(height: 16),
              Text(
                'Placeholder Image',
                style: TextStyle(
                  color: AppColors.frost.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
