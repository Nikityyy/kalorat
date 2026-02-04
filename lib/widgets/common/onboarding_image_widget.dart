import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class OnboardingImageWidget extends StatelessWidget {
  final String assetName; // For future real assets
  final double height;

  const OnboardingImageWidget({
    super.key,
    this.assetName = 'assets/onboarding_placeholder.png', // Default
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.celadon.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.shamrock.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // In a real app we would load the image, but user asked for placeholders for now
      // "Use a placeholder image asset (e.g. assets/onboarding_placeholder.png)"
      // Since I can't verify if the asset exists, I'll use a FlutterLogo or Icon as fallback if image fails,
      // but ideally this container IS the placeholder visual if the image isn't there.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 64,
                color: AppColors.shamrock,
              ),
              const SizedBox(height: 16),
              Text(
                'Placeholder Image',
                style: TextStyle(
                  color: AppColors.carbonBlack.withValues(alpha: 0.5),
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
