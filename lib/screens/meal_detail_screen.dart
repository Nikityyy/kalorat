import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import '../utils/platform_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';

import '../services/gemini_service.dart';
import '../extensions/l10n_extension.dart';
import '../models/meal_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/nutrition_units.dart';
import '../widgets/inputs/action_button.dart';
import '../widgets/live_thought_panel.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

class MealDetailScreen extends StatefulWidget {
  final MealModel meal;
  final bool isNewEntry;
  final String? initialMealContext;

  const MealDetailScreen({
    super.key,
    required this.meal,
    this.isNewEntry = false,
    this.initialMealContext,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late MealModel _meal;
  late double _portionMultiplier;
  bool _isAnalyzing = false;
  String _liveThoughtText = '';
  AnalysisPhase _analysisPhase = AnalysisPhase.drafting;
  String? _mealContext;

  // FocusNode for retry context sheet — avoids autofocus keyboard-jump bug
  final FocusNode _contextFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _portionMultiplier = widget.meal.portionMultiplier;
    _mealContext = widget.initialMealContext;

    // If the meal was saved with a multiplier (e.g. 2x), the stored calories
    // are already 2x. We need to divide by the multiplier to get the "base"
    // values for the editing session, so that the UI can re-multiply them consistently.
    if (!widget.isNewEntry &&
        _portionMultiplier != 1.0 &&
        _portionMultiplier > 0) {
      _meal = widget.meal.copyWith(
        calories: baseValueFromScaled(
          scaledValue: widget.meal.calories,
          portionMultiplier: _portionMultiplier,
        ),
        protein: baseValueFromScaled(
          scaledValue: widget.meal.protein,
          portionMultiplier: _portionMultiplier,
        ),
        carbs: baseValueFromScaled(
          scaledValue: widget.meal.carbs,
          portionMultiplier: _portionMultiplier,
        ),
        fats: baseValueFromScaled(
          scaledValue: widget.meal.fats,
          portionMultiplier: _portionMultiplier,
        ),
      );
    } else {
      _meal = widget.meal;
    }
  }

  @override
  void dispose() {
    _contextFocusNode.dispose();
    super.dispose();
  }

  void _updatePortion(double change) {
    setState(() {
      _portionMultiplier += change;
      if (_portionMultiplier < 0.1) _portionMultiplier = 0.1;
    });
  }

  void _updatePortionByValue(double newValue) {
    setState(() {
      if (_meal.portionUnit == 'serving') {
        _portionMultiplier = newValue;
      } else {
        // For grams/ml, the user enters e.g., 250.
        // Multiplier = 250 / 100
        _portionMultiplier = newValue / _meal.quantityPerUnit;
      }
      if (_portionMultiplier < 0.1) _portionMultiplier = 0.1;
    });
  }

  Future<void> _saveToGallery() async {
    final l10n = context.l10n;
    if (_meal.photoPaths.isEmpty) return;
    final path = _meal.photoPaths.first;

    try {
      if (kIsWeb) {
        // On web: share/download the base64 image via share_plus
        final bytes = base64Decode(path);
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                bytes,
                mimeType: 'image/jpeg',
                name: 'kalorat_meal.jpg',
              ),
            ],
          ),
        );
      } else {
        // On mobile: save the file path directly to device gallery (camera roll)
        await Gal.putImage(path, album: 'Kalorat');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveToGallerySuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveToGalleryError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Shows a context bottom sheet pre-filled with the previous context,
  /// then re-runs analysis with the updated context.
  Future<void> _showContextAndRetry() async {
    final provider = context.read<AppProvider>();
    final apiKey = provider.apiKey;
    if (apiKey.isEmpty) return;

    final contextController = TextEditingController(text: _mealContext);
    bool shouldRetry = false;
    String? submittedContext;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.glacialWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Analyse wiederholen',
                style: AppTypography.displayMedium.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                'Kontext bearbeiten oder direkt neu analysieren',
                style: AppTypography.bodySmall.copyWith(color: AppColors.slate),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contextController,
                focusNode: _contextFocusNode,
                maxLines: 3,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'z.B. 2 Portionen, extra Sauce ...',
                  filled: true,
                  fillColor: AppColors.pebble,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.pebble),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Abbrechen',
                        style: TextStyle(color: AppColors.slate),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final text = contextController.text.trim();
                        submittedContext = text.isNotEmpty ? text : null;
                        shouldRetry = true;
                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.styrianForest,
                        foregroundColor: AppColors.glacialWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Neu analysieren',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Request focus AFTER sheet is displayed to avoid layout jump
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _contextFocusNode.requestFocus();
    });

    if (!shouldRetry || !mounted) return;

    setState(() {
      _mealContext = submittedContext;
      _isAnalyzing = true;
      _liveThoughtText = '';
      _analysisPhase = AnalysisPhase.drafting;
    });

    Map<String, dynamic>? result;

    try {
      final language = provider.language;
      final gemini = GeminiService(apiKey: apiKey, language: language);
      final stream = gemini.analyzeMealStream(
        _meal.photoPaths,
        useGrams: provider.user?.useGramsByDefault ?? false,
        mealContext: submittedContext,
        useAccurateMode: provider.user?.useAccurateMode ?? false,
        allowEstimateVariation: true,
        previousAnalysis: _currentAnalysisSnapshot(),
      );

      await for (final event in stream) {
        if (!mounted) break;
        if (event is AnalysisPhaseChanged) {
          setState(() {
            _analysisPhase = event.phase;
            if (event.phase == AnalysisPhase.verifying &&
                !_liveThoughtText.contains(context.l10n.verifyingEstimate)) {
              _liveThoughtText =
                  '${_liveThoughtText.trimRight()}\n\n## ${context.l10n.verifyingEstimate}\n\n';
            }
          });
        } else if (event is ThoughtChunk) {
          setState(() {
            _liveThoughtText += event.text;
          });
        } else if (event is AnalysisResult) {
          result = event.data;
        }
      }

      final analysis = result;
      if (analysis != null) {
        if (analysis.containsKey('error') &&
            analysis['error'] == 'no_food_detected') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.noFoodDetected)),
            );
          }
          return;
        }

        final detectedPortion = normalizeDetectedPortion(analysis);
        final detectedQty = detectedPortion.quantity;
        final detectedUnit = detectedPortion.unit;
        final baseQuantityPerUnit = quantityPerUnitFor(detectedUnit);
        double detectedMultiplier = (detectedUnit == 'serving')
            ? detectedQty
            : (detectedQty / baseQuantityPerUnit);
        if (detectedMultiplier <= 0) detectedMultiplier = 1.0;

        setState(() {
          _meal = _meal.copyWith(
            mealName: analysis['meal_name'] ?? '',
            calories: nutritionBaseValue(
              analysis,
              unit: detectedUnit,
              valueKey: 'calories',
              referenceKey: 'calories_per_100g',
            ),
            protein: nutritionBaseValue(
              analysis,
              unit: detectedUnit,
              valueKey: 'protein',
              referenceKey: 'protein_per_100g',
            ),
            carbs: nutritionBaseValue(
              analysis,
              unit: detectedUnit,
              valueKey: 'carbs',
              referenceKey: 'carbs_per_100g',
            ),
            fats: nutritionBaseValue(
              analysis,
              unit: detectedUnit,
              valueKey: 'fats',
              referenceKey: 'fats_per_100g',
            ),
            caloriesPer100g: (analysis['calories_per_100g'] as num?)
                ?.toDouble(),
            proteinPer100g: (analysis['protein_per_100g'] as num?)?.toDouble(),
            carbsPer100g: (analysis['carbs_per_100g'] as num?)?.toDouble(),
            fatsPer100g: (analysis['fats_per_100g'] as num?)?.toDouble(),
            vitamins: analysis['vitamins'] != null
                ? Map<String, double>.from(
                    (analysis['vitamins'] as Map).map(
                      (k, v) => MapEntry(k.toString(), (v ?? 0).toDouble()),
                    ),
                  )
                : null,
            minerals: analysis['minerals'] != null
                ? Map<String, double>.from(
                    (analysis['minerals'] as Map).map(
                      (k, v) => MapEntry(k.toString(), (v ?? 0).toDouble()),
                    ),
                  )
                : null,
            portionUnit: detectedUnit,
            quantityPerUnit: baseQuantityPerUnit,
          );
          _portionMultiplier = detectedMultiplier;
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Analysis updated!')));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.analysisError('No result received.')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Retry failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _liveThoughtText = '';
        });
      }
    }
  }

  Map<String, dynamic> _currentAnalysisSnapshot() {
    return {
      'meal_name': _meal.mealName,
      'calories': _meal.calories,
      'protein': _meal.protein,
      'carbs': _meal.carbs,
      'fats': _meal.fats,
      'detected_quantity': _meal.portionUnit == 'serving'
          ? _portionMultiplier
          : _portionMultiplier * _meal.quantityPerUnit,
      'detected_unit': _meal.portionUnit,
      'calories_per_100g': _meal.caloriesPer100g,
      'protein_per_100g': _meal.proteinPer100g,
      'carbs_per_100g': _meal.carbsPer100g,
      'fats_per_100g': _meal.fatsPer100g,
    };
  }

  void _showEditPortionDialog() {
    double currentValue = (_meal.portionUnit == 'serving')
        ? _portionMultiplier
        : (_portionMultiplier * _meal.quantityPerUnit);

    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glacialWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: Text(
          _meal.portionUnit == 'serving' ? 'Portion' : 'Menge',
          style: AppTypography.displayMedium.copyWith(fontSize: 24),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            suffixText: _meal.portionUnit == 'serving'
                ? 'x'
                : displayUnitFor(_meal.portionUnit),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null) {
                _updatePortionByValue(val);
                Navigator.pop(context);
              }
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeal() async {
    final provider = context.read<AppProvider>();

    // Adjust values by portion multiplier before saving
    final finalMeal = _meal.copyWith(
      calories: scaledValueFromBase(
        baseValue: _meal.calories,
        portionMultiplier: _portionMultiplier,
      ),
      protein: scaledValueFromBase(
        baseValue: _meal.protein,
        portionMultiplier: _portionMultiplier,
      ),
      carbs: scaledValueFromBase(
        baseValue: _meal.carbs,
        portionMultiplier: _portionMultiplier,
      ),
      fats: scaledValueFromBase(
        baseValue: _meal.fats,
        portionMultiplier: _portionMultiplier,
      ),
      portionMultiplier: _portionMultiplier,
    );

    // saveMeal handles both create and update
    await provider.saveMeal(finalMeal);

    if (mounted) {
      Navigator.of(context).pop(finalMeal); // Return to previous screen
    }
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
                  final newBase = baseValueFromScaled(
                    scaledValue: newValue,
                    portionMultiplier: _portionMultiplier,
                  );
                  _meal = _meal.copyWith(
                    calories: newBase,
                    caloriesPer100g: isPer100Unit(_meal.portionUnit)
                        ? newBase
                        : _meal.caloriesPer100g,
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
      text: currentValue.toStringAsFixed(1),
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              final newValue = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
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

  Widget _buildAnalyzingView() {
    final l10n = context.l10n;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        if (_meal.photoPaths.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.35,
            child: PlatformUtils.isWeb
                ? Image.memory(
                    base64Decode(_meal.photoPaths.first),
                    fit: BoxFit.cover,
                  )
                : Image.file(File(_meal.photoPaths.first), fit: BoxFit.cover),
          ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: Column(
                children: [
                  Text(
                    l10n.analyzing,
                    style: AppTypography.displayMedium.copyWith(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  LiveThoughtPanel(
                    thoughtText: _liveThoughtText,
                    titleLabel: l10n.aiThinkingTitle,
                    thinkingLabel: l10n.aiThinkingLabel,
                  ),
                  const SizedBox(height: 24),
                  AnalysisPhaseIndicator(
                    phase: _analysisPhase,
                    draftingLabel: l10n.analyzingMeal,
                    verifyingLabel: l10n.verifyingEstimate,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenHeight = MediaQuery.of(context).size.height;
    final isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(
      context,
    );

    if (_isAnalyzing) {
      return Scaffold(
        backgroundColor: AppColors.glacialWhite,
        body: _buildAnalyzingView(),
      );
    }

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
              child: PlatformUtils.isWeb
                  ? Image.memory(
                      base64Decode(_meal.photoPaths.first),
                      fit: BoxFit.cover,
                    )
                  : Image.file(File(_meal.photoPaths.first), fit: BoxFit.cover),
            ),

          // 2. Back Button (Overlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Row(
                  children: [
                    if (_meal.photoPaths.isNotEmpty)
                      CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: IconButton(
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: _saveToGallery,
                          tooltip: context.l10n.saveToGallery,
                        ),
                      ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _showContextAndRetry,
                        tooltip: 'Analyse neu starten',
                      ),
                    ),
                  ],
                ),
              ],
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
                                      onPressed: _portionMultiplier > 0.1
                                          ? () {
                                              if (_meal.portionUnit ==
                                                  'serving') {
                                                _updatePortion(-0.5);
                                              } else {
                                                _updatePortion(
                                                  -50.0 / _meal.quantityPerUnit,
                                                );
                                              }
                                            }
                                          : null,
                                      icon: Icon(
                                        Icons.remove,
                                        color: _portionMultiplier > 0.1
                                            ? AppColors.styrianForest
                                            : AppColors.borderGrey,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _showEditPortionDialog,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          _meal.portionUnit == 'serving'
                                              ? '${_portionMultiplier.toStringAsFixed(1)}x'
                                              : '${(_portionMultiplier * _meal.quantityPerUnit).toInt()} ${displayUnitFor(_meal.portionUnit)}',
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.styrianForest,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        if (_meal.portionUnit == 'serving') {
                                          _updatePortion(0.5);
                                        } else {
                                          _updatePortion(
                                            50.0 / _meal.quantityPerUnit,
                                          );
                                        }
                                      },
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

                          _buildNutritionOverview(),

                          if (_hasPer100Reference() ||
                              _canEditPer100Reference()) ...[
                            const SizedBox(height: 16),
                            _buildPer100Reference(),
                          ],
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

  bool _hasPer100Reference() {
    return _meal.caloriesPer100g != null ||
        _meal.proteinPer100g != null ||
        _meal.carbsPer100g != null ||
        _meal.fatsPer100g != null;
  }

  Widget _buildNutritionOverview() {
    final l10n = context.l10n;
    final caloriesValue = _meal.calories * _portionMultiplier;

    final protein = _meal.protein * _portionMultiplier;
    final carbs = _meal.carbs * _portionMultiplier;
    final fats = _meal.fats * _portionMultiplier;
    final proteinCalories = protein * 4;
    final carbsCalories = carbs * 4;
    final fatCalories = fats * 9;
    final macroCalories = proteinCalories + carbsCalories + fatCalories;

    int percent(double value) {
      if (macroCalories <= 0) return 0;
      return ((value / macroCalories) * 100).round();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.subtleAsh, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showEditCaloriesDialog,
            child: _CalorieRing(
              calories: caloriesValue.round(),
              isOverride: _meal.isCalorieOverride,
              proteinCalories: proteinCalories,
              carbsCalories: carbsCalories,
              fatCalories: fatCalories,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                _MacroSummaryRow(
                  label: l10n.protein,
                  value: '${protein.toStringAsFixed(1)}g',
                  percent: percent(proteinCalories),
                  color: const Color(0xFF2F73D9),
                  onTap: _editProtein,
                ),
                const SizedBox(height: 12),
                _MacroSummaryRow(
                  label: l10n.carbs,
                  value: '${carbs.toStringAsFixed(1)}g',
                  percent: percent(carbsCalories),
                  color: const Color(0xFFFF8A00),
                  onTap: _editCarbs,
                ),
                const SizedBox(height: 12),
                _MacroSummaryRow(
                  label: l10n.fats,
                  value: '${fats.toStringAsFixed(1)}g',
                  percent: percent(fatCalories),
                  color: const Color(0xFFFF5A5F),
                  onTap: _editFats,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editProtein() {
    _showEditMacroDialog(
      context.l10n.protein,
      _meal.protein * _portionMultiplier,
      (val) {
        setState(() {
          final newProtein = baseValueFromScaled(
            scaledValue: val,
            portionMultiplier: _portionMultiplier,
          );
          final newCalories = _meal.isCalorieOverride
              ? _meal.calories
              : (newProtein * 4) + (_meal.carbs * 4) + (_meal.fats * 9);
          _meal = _meal.copyWith(
            protein: newProtein,
            calories: newCalories,
            proteinPer100g: isPer100Unit(_meal.portionUnit)
                ? newProtein
                : _meal.proteinPer100g,
            caloriesPer100g:
                isPer100Unit(_meal.portionUnit) && !_meal.isCalorieOverride
                ? newCalories
                : _meal.caloriesPer100g,
          );
        });
      },
    );
  }

  void _editCarbs() {
    _showEditMacroDialog(context.l10n.carbs, _meal.carbs * _portionMultiplier, (
      val,
    ) {
      setState(() {
        final newCarbs = baseValueFromScaled(
          scaledValue: val,
          portionMultiplier: _portionMultiplier,
        );
        final newCalories = _meal.isCalorieOverride
            ? _meal.calories
            : (_meal.protein * 4) + (newCarbs * 4) + (_meal.fats * 9);
        _meal = _meal.copyWith(
          carbs: newCarbs,
          calories: newCalories,
          carbsPer100g: isPer100Unit(_meal.portionUnit)
              ? newCarbs
              : _meal.carbsPer100g,
          caloriesPer100g:
              isPer100Unit(_meal.portionUnit) && !_meal.isCalorieOverride
              ? newCalories
              : _meal.caloriesPer100g,
        );
      });
    });
  }

  void _editFats() {
    _showEditMacroDialog(context.l10n.fats, _meal.fats * _portionMultiplier, (
      val,
    ) {
      setState(() {
        final newFats = baseValueFromScaled(
          scaledValue: val,
          portionMultiplier: _portionMultiplier,
        );
        final newCalories = _meal.isCalorieOverride
            ? _meal.calories
            : (_meal.protein * 4) + (_meal.carbs * 4) + (newFats * 9);
        _meal = _meal.copyWith(
          fats: newFats,
          calories: newCalories,
          fatsPer100g: isPer100Unit(_meal.portionUnit)
              ? newFats
              : _meal.fatsPer100g,
          caloriesPer100g:
              isPer100Unit(_meal.portionUnit) && !_meal.isCalorieOverride
              ? newCalories
              : _meal.caloriesPer100g,
        );
      });
    });
  }

  bool _canEditPer100Reference() {
    return isPer100Unit(_meal.portionUnit);
  }

  void _showEditPer100ReferenceDialog() {
    if (!_canEditPer100Reference()) return;

    final caloriesController = TextEditingController(
      text: _meal.caloriesPer100g?.toStringAsFixed(0) ?? '',
    );
    final proteinController = TextEditingController(
      text: _meal.proteinPer100g?.toStringAsFixed(1) ?? '',
    );
    final carbsController = TextEditingController(
      text: _meal.carbsPer100g?.toStringAsFixed(1) ?? '',
    );
    final fatsController = TextEditingController(
      text: _meal.fatsPer100g?.toStringAsFixed(1) ?? '',
    );

    double? readNumber(TextEditingController controller) {
      return double.tryParse(controller.text.trim().replaceAll(',', '.'));
    }

    Widget field({
      required TextEditingController controller,
      required String label,
      required String suffix,
    }) {
      return TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.styrianForest),
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.glacialWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: Text(
          '${context.l10n.edit} ${context.l10n.reference}',
          style: AppTypography.displayMedium.copyWith(fontSize: 24),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(
                controller: caloriesController,
                label: context.l10n.kcal.toUpperCase(),
                suffix: 'kcal',
              ),
              const SizedBox(height: 12),
              field(
                controller: proteinController,
                label: context.l10n.proteinShort.toUpperCase(),
                suffix: 'g',
              ),
              const SizedBox(height: 12),
              field(
                controller: carbsController,
                label: context.l10n.carbsShort.toUpperCase(),
                suffix: 'g',
              ),
              const SizedBox(height: 12),
              field(
                controller: fatsController,
                label: context.l10n.fatsShort.toUpperCase(),
                suffix: 'g',
              ),
            ],
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
              final calories = readNumber(caloriesController);
              final protein = readNumber(proteinController);
              final carbs = readNumber(carbsController);
              final fats = readNumber(fatsController);

              setState(() {
                _meal = _meal.copyWith(
                  caloriesPer100g: calories,
                  proteinPer100g: protein,
                  carbsPer100g: carbs,
                  fatsPer100g: fats,
                  calories: per100ReferenceFor(
                    unit: _meal.portionUnit,
                    baseValue: _meal.calories,
                    explicitReference: calories,
                  ),
                  protein: per100ReferenceFor(
                    unit: _meal.portionUnit,
                    baseValue: _meal.protein,
                    explicitReference: protein,
                  ),
                  carbs: per100ReferenceFor(
                    unit: _meal.portionUnit,
                    baseValue: _meal.carbs,
                    explicitReference: carbs,
                  ),
                  fats: per100ReferenceFor(
                    unit: _meal.portionUnit,
                    baseValue: _meal.fats,
                    explicitReference: fats,
                  ),
                );
              });
              Navigator.pop(context);
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

  Widget _buildPer100Reference() {
    final l10n = context.l10n;
    final unit = _meal.portionUnit == 'ml' ? '100ml' : '100g';
    final canEdit = _canEditPer100Reference();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.subtleAsh, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.reference} / $unit',
                  style: AppTypography.dataLabel.copyWith(
                    fontSize: 11,
                    color: AppColors.styrianForest,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (canEdit)
                InkWell(
                  onTap: _showEditPer100ReferenceDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: AppColors.styrianForest.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Per100Value(
                label: l10n.kcal.toUpperCase(),
                value: _meal.caloriesPer100g?.toStringAsFixed(0) ?? '-',
              ),
              _Per100Value(
                label: l10n.proteinShort.toUpperCase(),
                value: _formatPer100Macro(_meal.proteinPer100g),
              ),
              _Per100Value(
                label: l10n.carbsShort.toUpperCase(),
                value: _formatPer100Macro(_meal.carbsPer100g),
              ),
              _Per100Value(
                label: l10n.fatsShort.toUpperCase(),
                value: _formatPer100Macro(_meal.fatsPer100g),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPer100Macro(double? value) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(1)}g';
  }
}

class _CalorieRing extends StatelessWidget {
  final int calories;
  final bool isOverride;
  final double proteinCalories;
  final double carbsCalories;
  final double fatCalories;

  const _CalorieRing({
    required this.calories,
    required this.isOverride,
    required this.proteinCalories,
    required this.carbsCalories,
    required this.fatCalories,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: _MacroCalorieRingPainter(
                proteinCalories: proteinCalories,
                carbsCalories: carbsCalories,
                fatCalories: fatCalories,
                strokeWidth: 8,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$calories',
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 26,
                      color: AppColors.deepSpaceBlack,
                    ),
                  ),
                  if (isOverride) ...[
                    const SizedBox(width: 3),
                    const Icon(Icons.lock_open, size: 12),
                  ],
                ],
              ),
              Text(
                'kcal',
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 11,
                  color: AppColors.deepSpaceBlack,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCalorieRingPainter extends CustomPainter {
  final double proteinCalories;
  final double carbsCalories;
  final double fatCalories;
  final double strokeWidth;

  const _MacroCalorieRingPainter({
    required this.proteinCalories,
    required this.carbsCalories,
    required this.fatCalories,
    required this.strokeWidth,
  });

  static const _proteinColor = Color(0xFF2F73D9);
  static const _carbsColor = Color(0xFFFF8A00);
  static const _fatColor = Color(0xFFFF5A5F);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = proteinCalories + carbsCalories + fatCalories;

    final trackPaint = Paint()
      ..color = AppColors.subtleAsh.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (total <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    var startAngle = -math.pi / 2;
    const gap = 0.035;
    final segments = [
      MapEntry(proteinCalories, _proteinColor),
      MapEntry(carbsCalories, _carbsColor),
      MapEntry(fatCalories, _fatColor),
    ];

    for (final segment in segments) {
      final calories = segment.key;
      if (calories <= 0) continue;
      final sweep = (calories / total) * math.pi * 2;
      paint.color = segment.value;
      canvas.drawArc(
        rect,
        startAngle,
        (sweep - gap).clamp(0.0, math.pi * 2).toDouble(),
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroCalorieRingPainter oldDelegate) {
    return proteinCalories != oldDelegate.proteinCalories ||
        carbsCalories != oldDelegate.carbsCalories ||
        fatCalories != oldDelegate.fatCalories ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

class _MacroSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final int percent;
  final Color color;
  final VoidCallback onTap;

  const _MacroSummaryRow({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 12,
                  color: AppColors.deepSpaceBlack,
                  letterSpacing: 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              value,
              style: AppTypography.labelLarge.copyWith(
                fontSize: 12,
                color: AppColors.deepSpaceBlack,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 34,
              child: Text(
                '$percent%',
                textAlign: TextAlign.right,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 12,
                  color: AppColors.slate,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Per100Value extends StatelessWidget {
  final String label;
  final String value;

  const _Per100Value({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.dataMedium.copyWith(
              fontSize: 16,
              color: AppColors.deepSpaceBlack,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.dataLabel.copyWith(
              fontSize: 10,
              color: AppColors.deepSpaceBlack.withValues(alpha: 0.45),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
