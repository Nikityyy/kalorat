import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';

import '../extensions/l10n_extension.dart';
import '../models/meal_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/inputs/action_button.dart';

class MealDetailScreen extends StatefulWidget {
  final MealModel meal;
  final bool
  isNewEntry; // If true, we show "Discard" instead of "Delete" logic potentially, or just handled by caller

  const MealDetailScreen({
    super.key,
    required this.meal,
    this.isNewEntry = false,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late MealModel _meal;
  late double _portionMultiplier;

  @override
  void initState() {
    super.initState();
    _portionMultiplier = widget.meal.portionMultiplier;

    // If the meal was saved with a multiplier (e.g. 2x), the stored calories
    // are already 2x. We need to divide by the multiplier to get the "base"
    // values for the editing session, so that the UI can re-multiply them consistently.
    if (_portionMultiplier != 1.0 && _portionMultiplier > 0) {
      _meal = widget.meal.copyWith(
        calories: widget.meal.calories / _portionMultiplier,
        protein: widget.meal.protein / _portionMultiplier,
        carbs: widget.meal.carbs / _portionMultiplier,
        fats: widget.meal.fats / _portionMultiplier,
      );
    } else {
      _meal = widget.meal;
    }
  }

  void _updatePortion(double change) {
    setState(() {
      _portionMultiplier += change;
      if (_portionMultiplier < 1.0) _portionMultiplier = 1.0;
    });
  }

  void _saveMeal() {
    final provider = context.read<AppProvider>();

    // Adjust values by portion multiplier before saving
    final finalMeal = _meal.copyWith(
      calories: _meal.calories * _portionMultiplier,
      protein: _meal.protein * _portionMultiplier,
      carbs: _meal.carbs * _portionMultiplier,
      fats: _meal.fats * _portionMultiplier,
      portionMultiplier: _portionMultiplier,
    );

    // saveMeal handles both create and update
    provider.saveMeal(finalMeal);

    Navigator.of(context).pop(); // Return to previous screen
  }

  void _showEditMealNameDialog() {
    final controller = TextEditingController(text: _meal.mealName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glacialWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: Text(
          context.l10n.editMealName,
          style: AppTypography.displayMedium.copyWith(fontSize: 24),
        ),
        content: TextField(
          controller: controller,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.styrianForest),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(color: AppColors.slate),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _meal = _meal.copyWith(mealName: controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: Text(
              context.l10n.save,
              style: const TextStyle(
                color: AppColors.styrianForest,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCaloriesDialog() {
    final currentCal = (_meal.calories * _portionMultiplier).toInt();
    final controller = TextEditingController(text: currentCal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glacialWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: Text(
          context.l10n.editCalories,
          style: AppTypography.displayMedium.copyWith(fontSize: 24),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            suffixText: 'kcal',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.styrianForest),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(color: AppColors.slate),
            ),
          ),
          TextButton(
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null) {
                setState(() {
                  // Calculate new base calories
                  final newBase = newValue / _portionMultiplier;
                  _meal = _meal.copyWith(
                    calories: newBase,
                    isCalorieOverride: true, // Force manual mode
                  );
                });
                Navigator.pop(context);
              }
            },
            child: Text(
              context.l10n.save,
              style: const TextStyle(
                color: AppColors.styrianForest,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditMacroDialog(
    String label,
    double currentValue,
    Function(double) onSave,
  ) {
    final controller = TextEditingController(
      text: currentValue.toInt().toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glacialWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: Text(
          '${context.l10n.edit} $label',
          style: AppTypography.displayMedium.copyWith(fontSize: 24),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            suffixText: 'g',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.styrianForest),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(color: AppColors.slate),
            ),
          ),
          TextButton(
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null) {
                onSave(newValue);
                Navigator.pop(context);
              }
            },
            child: Text(
              context.l10n.save,
              style: const TextStyle(
                color: AppColors.styrianForest,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenHeight = MediaQuery.of(context).size.height;
    final isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(
      context,
    );

    return Scaffold(
      backgroundColor: AppColors.glacialWhite,
      body: Stack(
        children: [
          // 1. Background Image (Featured photo)
          if (_meal.photoPaths.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.35,
              child: Image.file(
                File(_meal.photoPaths.first),
                fit: BoxFit.cover,
              ),
            ),

          // 2. Back Button (Overlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black26,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. Content Sheet
          Positioned(
            top: screenHeight * 0.3,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.glacialWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 160),
                      child: Column(
                        children: [
                          // Meal Name
                          GestureDetector(
                            onTap: _showEditMealNameDialog,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    _meal.mealName,
                                    style: AppTypography.displayMedium.copyWith(
                                      fontSize: 32,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: AppColors.styrianForest.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Portion Control
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.glacialWhite,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.borderGrey,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: _portionMultiplier > 1.0
                                          ? () => _updatePortion(-1.0)
                                          : null,
                                      icon: Icon(
                                        Icons.remove,
                                        color: _portionMultiplier > 1.0
                                            ? AppColors.styrianForest
                                            : AppColors.borderGrey,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${_portionMultiplier}x',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.styrianForest,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      onPressed: () => _updatePortion(1.0),
                                      icon: const Icon(
                                        Icons.add,
                                        color: AppColors.styrianForest,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Calories Card
                          GestureDetector(
                            onTap: _showEditCaloriesDialog,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              decoration: BoxDecoration(
                                color: AppColors.styrianForest,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadius,
                                ),
                                border: Border.all(
                                  color: AppColors.borderGrey,
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Column(
                                      children: [
                                        Text(
                                          '${(_meal.calories * _portionMultiplier).toInt()}',
                                          style: AppTypography.heroNumber
                                              .copyWith(
                                                color: AppColors.glacialWhite,
                                                fontSize: 64,
                                              ),
                                        ),
                                        Text(
                                          l10n.calories.toUpperCase(),
                                          style: AppTypography.labelLarge
                                              .copyWith(
                                                color: AppColors.glacialWhite
                                                    .withValues(alpha: 0.7),
                                                letterSpacing: 2,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: 16,
                                    top: 0,
                                    child: Icon(
                                      _meal.isCalorieOverride
                                          ? Icons.lock_open
                                          : Icons.lock,
                                      color: AppColors.glacialWhite.withValues(
                                        alpha: 0.3,
                                      ),
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Macros Row
                          Row(
                            children: [
                              _MacroCard(
                                label: l10n.protein,
                                value:
                                    '${(_meal.protein * _portionMultiplier).toInt()}g',
                                color: AppColors.styrianForest,
                                onEdit: () => _showEditMacroDialog(
                                  l10n.protein,
                                  _meal.protein * _portionMultiplier,
                                  (val) {
                                    setState(() {
                                      final newProtein =
                                          val / _portionMultiplier;
                                      final newCalories =
                                          _meal.isCalorieOverride
                                          ? _meal.calories
                                          : (newProtein * 4) +
                                                (_meal.carbs * 4) +
                                                (_meal.fats * 9);
                                      _meal = _meal.copyWith(
                                        protein: newProtein,
                                        calories: newCalories,
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              _MacroCard(
                                label: l10n.carbs,
                                value:
                                    '${(_meal.carbs * _portionMultiplier).toInt()}g',
                                color: AppColors.styrianForest,
                                onEdit: () => _showEditMacroDialog(
                                  l10n.carbs,
                                  _meal.carbs * _portionMultiplier,
                                  (val) {
                                    setState(() {
                                      final newCarbs = val / _portionMultiplier;
                                      final newCalories =
                                          _meal.isCalorieOverride
                                          ? _meal.calories
                                          : (_meal.protein * 4) +
                                                (newCarbs * 4) +
                                                (_meal.fats * 9);
                                      _meal = _meal.copyWith(
                                        carbs: newCarbs,
                                        calories: newCalories,
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              _MacroCard(
                                label: l10n.fats,
                                value:
                                    '${(_meal.fats * _portionMultiplier).toInt()}g',
                                color: AppColors.styrianForest,
                                onEdit: () => _showEditMacroDialog(
                                  l10n.fats,
                                  _meal.fats * _portionMultiplier,
                                  (val) {
                                    setState(() {
                                      final newFats = val / _portionMultiplier;
                                      final newCalories =
                                          _meal.isCalorieOverride
                                          ? _meal.calories
                                          : (_meal.protein * 4) +
                                                (_meal.carbs * 4) +
                                                (newFats * 9);
                                      _meal = _meal.copyWith(
                                        fats: newFats,
                                        calories: newCalories,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Sticky Bottom Bar
          if (!isKeyboardVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  color: AppColors.glacialWhite,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.borderGrey.withValues(alpha: 0.5),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cancel Button (Small icon/text)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.slate,
                        size: 24,
                      ),
                      tooltip: l10n.discard,
                    ),
                    const SizedBox(width: 16),
                    // Log Entry Button (Expanded)
                    Expanded(
                      child: ActionButton(
                        text: widget.isNewEntry
                            ? l10n.saveMeal
                            : l10n.saveChanges,
                        onPressed: _saveMeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onEdit;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.color,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.steel,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: AppTypography.titleLarge.copyWith(
                      color: color,
                      fontSize: 24,
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: color.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    fontSize: 10,
                    color: AppColors.frost.withValues(alpha: 0.5),
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
