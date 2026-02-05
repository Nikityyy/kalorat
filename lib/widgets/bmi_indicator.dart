import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class BmiIndicator extends StatelessWidget {
  final double bmi;
  final String category;
  final String language;

  const BmiIndicator({
    super.key,
    required this.bmi,
    required this.category,
    this.language = 'de',
  });

  Color get _color {
    switch (category) {
      case 'underweight':
        return AppColors.pebble;
      case 'normal':
        return AppColors.glacierMint;
      case 'overweight':
      case 'obese':
        return AppColors.kaiserRed;
      default:
        return AppColors.slate;
    }
  }

  String get _label {
    if (language == 'de') {
      switch (category) {
        case 'underweight':
          return 'Untergewicht';
        case 'normal':
          return 'Normalgewicht';
        case 'overweight':
          return 'Übergewicht';
        case 'obese':
          return 'Adipositas';
        default:
          return '';
      }
    } else {
      switch (category) {
        case 'underweight':
          return 'Underweight';
        case 'normal':
          return 'Normal weight';
        case 'overweight':
          return 'Overweight';
        case 'obese':
          return 'Obese';
        default:
          return '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BMI: ${bmi.toStringAsFixed(1)}',
                style: AppTypography.dataMedium.copyWith(
                  fontSize: 18,
                  color: AppColors.styrianForest,
                ),
              ),
              Text(
                _label,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
