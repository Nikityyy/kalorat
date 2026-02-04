import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
        return Colors.blue;
      case 'normal':
        return AppColors.emerald; // Success color
      case 'overweight':
        return AppColors.warning;
      case 'obese':
        return AppColors.error;
      default:
        return Colors.grey;
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
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _color,
                ),
              ),
              Text(
                _label,
                style: TextStyle(
                  fontSize: 14,
                  color: _color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
