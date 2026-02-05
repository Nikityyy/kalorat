import 'package:flutter/material.dart';
import '../../extensions/l10n_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class BmiIndicator extends StatelessWidget {
  final double bmi;
  final String category;

  const BmiIndicator({super.key, required this.bmi, required this.category});

  Color get _color {
    switch (category.toLowerCase()) {
      case 'underweight':
        return AppColors.amber;
      case 'normal':
        return AppColors.glacierMint;
      case 'overweight':
      case 'obese':
        return AppColors.kaiserRed;
      default:
        return AppColors.frost;
    }
  }

  String _getLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (category.toLowerCase()) {
      case 'underweight':
        return l10n.bmiUnderweight;
      case 'normal':
        return l10n.bmiNormal;
      case 'overweight':
        return l10n.bmiOverweight;
      case 'obese':
        return l10n.bmiObese;
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glacialWhite,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.borderGrey, width: 1),
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
                _getLabel(context),
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.frost,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
