import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';

import '../services/barcode/food_product.dart';
import '../services/photo_store.dart';
import '../utils/haptics.dart';
import '../utils/meal_components.dart';
import '../utils/meal_correction.dart';
import '../services/gemini_service.dart';
import '../extensions/l10n_extension.dart';
import '../extensions/validation_l10n.dart';
import '../models/meal_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/nutrition_units.dart';
import '../widgets/common/adaptive.dart';
import 'home/analyzing_view.dart';
import 'home/photo_viewer.dart';
import 'meal_detail/components_section.dart';
import 'meal_detail/retry_sheet.dart';
import '../utils/analysis_parser.dart';
import '../widgets/inputs/action_button.dart';
import '../utils/analysis_tracker.dart';
import '../widgets/app_toast.dart';
import '../utils/analysis_error_message.dart';
import '../utils/save_photo.dart';
import '../widgets/common/meal_mark.dart';
import '../widgets/common/mono_digits.dart';
import '../widgets/common/thin_bar.dart';

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

  /// The calories before any one-tap correction, so it can be undone.
  late double _originalCalories;
  bool _isAnalyzing = false;
  int _photoIndex = 0;
  final _photoPages = PageController();
  final AnalysisTracker _tracker = AnalysisTracker();
  String? _mealContext;
  ImageProvider? _analysisHeroImageProvider;

  // FocusNode for retry context sheet — avoids autofocus keyboard-jump bug

  @override
  void initState() {
    super.initState();
    _portionMultiplier = widget.meal.portionMultiplier;
    _mealContext = widget.initialMealContext ?? widget.meal.mealContext;

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
    _originalCalories = _meal.calories;
  }

  @override
  void dispose() {
    _tracker.dispose();
    _photoPages.dispose();
    super.dispose();
  }

  // Full screen width in device pixels: the photos never show larger, and a
  // 1600 px original decoded at full size costs memory and upload time.
  ImageProvider _mealPhotoImageProvider(String photo) =>
      PhotoStore.instance.imageProvider(
        photo,
        cacheWidth:
            (MediaQuery.sizeOf(context).width *
                    MediaQuery.devicePixelRatioOf(context))
                .round(),
      );

  void _updatePortion(double change) {
    setState(() {
      _portionMultiplier += change;
      if (_portionMultiplier < 0.1) _portionMultiplier = 0.1;
    });
  }

  Future<void> _editTimestamp() async {
    final picked = await pickDate(
      context,
      initial: _meal.timestamp,
      first: DateTime(2000),
      last: DateTime.now(),
      withTime: true,
    );
    if (picked == null || !mounted) return;
    final time = TimeOfDay.fromDateTime(picked);
    final date = picked;
    setState(() {
      _meal = _meal.copyWith(
        timestamp: DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
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

  /// Opens the photos full screen at the one shown, and keeps showing the
  /// one the viewer was closed on.
  Future<void> _openPhotos(int index) async {
    final photos = _meal.photoPaths;
    final shown = await showPhotoViewer(
      context,
      images: [for (final p in photos) PhotoStore.instance.imageProvider(p)],
      initialIndex: index,
      heroTag: (i) => _photoHeroTag(i),
      onSave: _saveToGallery,
    );
    if (shown != null && shown != _photoIndex && _photoPages.hasClients) {
      _photoPages.jumpToPage(shown);
    }
  }

  Object _photoHeroTag(int i) => 'meal-photo-${_meal.id}-$i';

  /// Saves the photo at [index], by default the one shown.
  Future<void> _saveToGallery([int? index]) async {
    final photos = _meal.photoPaths;
    if (photos.isEmpty) return;
    await savePhotoToGallery(
      context,
      photos[(index ?? _photoIndex).clamp(0, photos.length - 1)],
    );
  }

  /// Logs this meal again as it was saved, as a new meal eaten now.
  Future<void> _logAgain() async {
    final provider = context.read<AppProvider>();
    final l10n = context.l10n;
    try {
      final copy = await provider.repeatMeal(widget.meal);
      if (!mounted) return;
      AppToast.show(
        context,
        l10n.quickLogLogged(copy.mealName),
        kind: AppToastKind.success,
        top: MediaQuery.paddingOf(context).top + 64,
        actionLabel: l10n.quickLogUndo,
        onAction: () => provider.deleteMeal(copy.id),
      );
    } catch (e) {
      AppToast.show(
        context,
        errorMessage(context.l10n, e),
        kind: AppToastKind.error,
        top: MediaQuery.paddingOf(context).top + 64,
      );
    }
  }

  /// Shows a context bottom sheet pre-filled with the previous context,
  /// then re-runs analysis with the updated context.
  Future<void> _showContextAndRetry() async {
    final provider = context.read<AppProvider>();
    final apiKey = provider.apiKey;
    if (apiKey.isEmpty) return;

    // A meal logged from a barcode can be analysed as a meal instead, e.g.
    // when the code was on a package in the background. The product's name
    // and values must not steer that analysis.
    final barcodeProduct = FoodProduct.productNameOfMeal(_meal.mealContext);
    final request = await showRetrySheet(
      context,
      initialNote: barcodeProduct == null ? _mealContext : null,
      barcodeProduct: barcodeProduct,
      hasPhotos: _meal.photoPaths.isNotEmpty,
    );
    if (request == null || !mounted) return;
    final submittedContext = request.note;

    setState(() {
      _mealContext = submittedContext;
      _isAnalyzing = true;
      _analysisHeroImageProvider = _meal.photoPaths.isNotEmpty
          ? _mealPhotoImageProvider(_meal.photoPaths.first)
          : null;
    });
    final accurate = provider.user?.useAccurateMode ?? true;
    _tracker.start(
      estimates: accurate ? GeminiService.ensembleSize : 1,
      hasPhoto: _meal.photoPaths.isNotEmpty,
      description: submittedContext,
    );

    Map<String, dynamic>? result;

    try {
      final language = provider.language;
      final gemini = GeminiService(apiKey: apiKey, language: language);
      final stream = gemini.analyzeMealStream(
        _meal.photoPaths,
        useGrams: provider.user?.useGramsByDefault ?? false,
        mealContext: submittedContext,
        useAccurateMode: accurate,
        allowEstimateVariation: true,
        previousAnalysis: barcodeProduct == null
            ? _currentAnalysisSnapshot()
            : null,
        leftoverPaths: request.leftoverPaths,
      );

      await for (final event in stream) {
        if (!mounted) break;
        if (event is AnalysisResult) {
          result = event.data;
        } else {
          _tracker.handle(event);
        }
      }

      final analysis = result;
      if (analysis != null) {
        if (analysis.containsKey('error') &&
            analysis['error'] == 'no_food_detected') {
          if (mounted) {
            AppToast.show(
              context,
              context.l10n.noFoodDetected,
              kind: AppToastKind.info,
            );
          }
          return;
        }

        await _tracker.finish(analysis);
        if (!mounted) return;
        final parsed = parseAnalysisResult(analysis);
        setState(() {
          _meal = _meal.copyWith(
            mealContext: submittedContext,
            mealName: parsed.mealName,
            calories: parsed.calories,
            protein: parsed.protein,
            carbs: parsed.carbs,
            fats: parsed.fats,
            caloriesPer100g: parsed.caloriesPer100g,
            proteinPer100g: parsed.proteinPer100g,
            carbsPer100g: parsed.carbsPer100g,
            fatsPer100g: parsed.fatsPer100g,
            analysisConfidence: parsed.confidence,
            analysisNote: parsed.note,
            caloriesMin: parsed.caloriesMin,
            caloriesMax: parsed.caloriesMax,
            components: parsed.components,
            vitamins: parsed.vitamins,
            minerals: parsed.minerals,
            portionUnit: parsed.unit,
            quantityPerUnit: parsed.quantityPerUnit,
          );
          _portionMultiplier = parsed.multiplier;
          _originalCalories = _meal.calories;
        });

        if (mounted) {
          AppToast.show(
            context,
            context.l10n.analysisUpdated,
            kind: AppToastKind.info,
          );
        }
      } else if (mounted) {
        AppToast.show(
          context,
          context.l10n.analysisNoResult,
          kind: AppToastKind.info,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          analysisErrorMessage(context.l10n, e),
          kind: AppToastKind.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisHeroImageProvider = null;
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
      if (_meal.components case final components?)
        'items': [
          for (final component in components)
            {
              'name': component.name,
              'grams': component.grams * _portionMultiplier,
              'kcal': component.calories * _portionMultiplier,
            },
        ],
    };
  }

  Future<void> _showEditPortionDialog() async {
    final serving = _meal.portionUnit == 'serving';
    final currentValue = serving
        ? _portionMultiplier
        : (_portionMultiplier * _meal.quantityPerUnit);
    final value = await showNumberPrompt(
      context,
      title: context.l10n.portionEdit,
      initial: currentValue,
      suffix: serving ? '×' : displayUnitFor(_meal.portionUnit),
    );
    if (value != null && mounted) _updatePortionByValue(value);
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

    try {
      await provider.saveMeal(finalMeal);
    } on FormatException catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          errorMessage(context.l10n, e),
          kind: AppToastKind.info,
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(finalMeal); // Return to previous screen
    }
  }

  Future<void> _showEditMealNameDialog() async {
    final values = await showPromptDialog(
      context,
      title: context.l10n.editMealName,
      fields: [PromptField(initial: _meal.mealName)],
    );
    final name = values?.first ?? '';
    if (name.isEmpty || !mounted) return;
    setState(() => _meal = _meal.copyWith(mealName: name));
  }

  Future<void> _showEditCaloriesDialog() async {
    final newValue = await showNumberPrompt(
      context,
      title: context.l10n.editCalories,
      initial: (_meal.calories * _portionMultiplier).roundToDouble(),
      suffix: 'kcal',
      decimals: 0,
    );
    if (newValue == null || !mounted) return;
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
        // Typed totals no longer come from the components.
        components: null,
      );
    });
  }

  Future<void> _showEditMacroDialog(
    String label,
    double currentValue,
    ValueChanged<double> onSave,
  ) async {
    final newValue = await showNumberPrompt(
      context,
      title: '${context.l10n.edit} $label',
      initial: currentValue,
      suffix: 'g',
    );
    if (newValue != null && mounted) onSave(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(
      context,
    );

    if (_isAnalyzing) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: AnalyzingView(
          heroImage: _analysisHeroImageProvider,
          tracker: _tracker,
        ),
      );
    }

    final photoHeight = media.size.height * 0.42;
    final photos = _meal.photoPaths;
    final context0 = _mealContext?.trim() ?? '';
    // What was typed with the meal; a barcode meal's context is its product.
    final typed =
        context0.isEmpty ||
            FoodProduct.productNameOfMeal(_meal.mealContext) != null
        ? null
        : context0;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          hint: l10n.editMealName,
          child: GestureDetector(
            onTap: _showEditMealNameDialog,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _meal.mealName.isNotEmpty
                        ? _meal.mealName
                        : l10n.mealName,
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: Icon(Icons.edit, size: 20, color: AppColors.ink3),
                    ),
                  ),
                ],
              ),
              style: AppTypography.title,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildTimeChip(),
        if (typed != null) ...[
          const SizedBox(height: 20),
          _buildTypedText(typed),
        ],
        const SizedBox(height: 22),
        _buildNutritionOverview(),
        if (_hasUncertaintyNote()) ...[
          const SizedBox(height: 16),
          _buildUncertaintyNote(),
        ],
        const SizedBox(height: 20),
        _buildMacroRows(),
        if (_meal.components case final components?) ...[
          const SizedBox(height: 32),
          MealComponentsSection(
            components: components,
            multiplier: _portionMultiplier,
            onEdit: _editComponent,
          ),
        ],
        if (_hasPer100Reference() || _canEditPer100Reference()) ...[
          const SizedBox(height: 20),
          _buildPer100Reference(),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // 1. The meal's photos, swiped through, and under them its
          // numbers; the photos scroll away with the content. A meal logged
          // without a photo starts with its name.
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: media.padding.bottom + 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (photos.isEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        media.padding.top + 72,
                        20,
                        0,
                      ),
                      child: details,
                    )
                  else ...[
                    SizedBox(
                      height: photoHeight + AppTheme.borderRadius,
                      child: PageView.builder(
                        controller: _photoPages,
                        itemCount: photos.length,
                        onPageChanged: (i) {
                          Haptics.selection();
                          setState(() => _photoIndex = i);
                        },
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () => _openPhotos(i),
                          child: Hero(
                            tag: _photoHeroTag(i),
                            child: Image(
                              image: _mealPhotoImageProvider(photos[i]),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) => MealMark(
                                name: _meal.mealName,
                                size: 120,
                                fill: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -AppTheme.borderRadius),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.borderRadius),
                          ),
                          border: Border(
                            top: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                          child: details,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Keeps the round buttons readable on a bright photo.
          if (photos.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: media.padding.top + 72,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 2. Back and the meal's other actions.
          Positioned(
            top: media.padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _GlassButton(
                  icon: Icons.arrow_back,
                  tooltip: widget.isNewEntry ? l10n.discard : l10n.back,
                  onPressed: () => Navigator.pop(context),
                  plain: photos.isEmpty,
                ),
                const Spacer(),
                if (photos.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                    child: Text(
                      '${_photoIndex + 1}/${photos.length}',
                      style: AppTypography.number(
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                _buildMoreMenu(),
              ],
            ),
          ),

          // 4. Portion and save, on an opaque bar.
          if (!isKeyboardVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  media.padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    _buildPortionStepper(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionButton(
                        text: widget.isNewEntry ? l10n.saveMeal : l10n.save,
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

  Widget _buildMoreMenu() {
    final l10n = context.l10n;
    final canDelete = !widget.isNewEntry && !_meal.isPending;
    return PopupMenuButton<String>(
      tooltip: l10n.moreActions,
      position: PopupMenuPosition.under,
      onOpened: Haptics.tick,
      onSelected: (value) {
        switch (value) {
          case 'photo':
            _saveToGallery();
          case 'again':
            _logAgain();
          case 'retry':
            _showContextAndRetry();
          case 'delete':
            _deleteMeal();
        }
      },
      itemBuilder: (context) => [
        if (_meal.photoPaths.isNotEmpty)
          _menuItem('photo', Icons.download, l10n.saveToGallery),
        if (canDelete)
          _menuItem('again', Icons.replay, l10n.quickLogAgainAction),
        _menuItem('retry', Icons.refresh, l10n.retryAnalysis),
        if (canDelete) ...[
          const PopupMenuDivider(),
          _menuItem('delete', Icons.delete, l10n.delete, destructive: true),
        ],
      ],
      child: _GlassButton(
        icon: Icons.more_horiz,
        plain: _meal.photoPaths.isEmpty,
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    bool destructive = false,
  }) {
    final color = destructive ? AppColors.negative : AppColors.text;
    final text = Text(label, style: AppTypography.body.copyWith(color: color));
    final glyph = Icon(icon, size: 20, color: color);
    return PopupMenuItem(
      value: value,
      child: Row(children: [glyph, const SizedBox(width: 12), text]),
    );
  }

  Future<void> _deleteMeal() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteQuestion,
      message: l10n.deleteMealConfirmation,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<AppProvider>().deleteMeal(_meal.id);
    if (mounted) Navigator.pop(context);
  }

  Widget _buildTypedText(String text) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _meal.photoPaths.isEmpty ? l10n.yourDescription : l10n.yourNote,
            style: AppTypography.meta,
          ),
          const SizedBox(height: 4),
          Text(text, style: AppTypography.body),
        ],
      ),
    );
  }

  Widget _buildTimeChip() {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final t = _meal.timestamp;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final clock = DateFormat.Hm(language).format(t);
    final label = day == today
        ? l10n.todayAt(clock)
        : day == today.subtract(const Duration(days: 1))
        ? l10n.yesterdayAt(clock)
        : '${DateFormat.yMMMd(language).format(t)}, $clock';
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: _editTimestamp,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 16, color: AppColors.ink2),
              const SizedBox(width: 6),
              MonoDigits(label, style: AppTypography.secondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortionStepper() {
    final l10n = context.l10n;
    final serving = _meal.portionUnit == 'serving';
    final canShrink = _portionMultiplier > 0.1;
    void change(double sign) {
      Haptics.selection();
      _updatePortion(sign * (serving ? 0.5 : 50.0 / _meal.quantityPerUnit));
    }

    final label = serving
        ? '${_portionMultiplier.toStringAsFixed(1)}×'
        : '${(_portionMultiplier * _meal.quantityPerUnit).round()} ${displayUnitFor(_meal.portionUnit)}';
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: canShrink ? () => change(-1) : null,
            tooltip: l10n.portionLess,
            icon: Icon(
              Icons.remove,
              color: canShrink ? AppColors.text : AppColors.border,
            ),
          ),
          Semantics(
            button: true,
            hint: l10n.portionEdit,
            child: GestureDetector(
              onTap: _showEditPortionDialog,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.number(
                    size: 16,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => change(1),
            tooltip: l10n.portionMore,
            icon: Icon(Icons.add, color: AppColors.text),
          ),
        ],
      ),
    );
  }

  bool _hasUncertaintyNote() {
    final note = _meal.analysisNote?.trim() ?? '';
    final low = _meal.caloriesMin;
    final high = _meal.caloriesMax;
    final confidence = _meal.analysisConfidence;
    return note.isNotEmpty ||
        (low != null && high != null && (high - low).abs() >= 1) ||
        (confidence != null && confidence < 0.75);
  }

  Widget _buildUncertaintyNote() {
    final l10n = context.l10n;
    final low = _meal.caloriesMin;
    final high = _meal.caloriesMax;
    final scale = _portionMultiplier;
    final note = _meal.analysisNote?.trim() ?? '';
    final confidence = _meal.analysisConfidence;
    final choices = calorieChoices(
      _meal,
      _portionMultiplier,
      originalCalories: _originalCalories,
    );
    final shown = (_meal.calories * _portionMultiplier).round();

    String choiceLabel(CalorieChoiceKind kind) => switch (kind) {
      CalorieChoiceKind.lower => l10n.correctionLower,
      CalorieChoiceKind.original => l10n.correctionCurrent,
      CalorieChoiceKind.higher => l10n.correctionHigher,
    };

    final parts = <String>[
      if (confidence != null) l10n.confidenceShort((confidence * 100).round()),
      if (low != null && high != null)
        l10n.probablyBetween((low * scale).round(), (high * scale).round()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts.isNotEmpty)
          MonoDigits(parts.join(' · '), style: AppTypography.secondary),
        if (choices.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < choices.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _CorrectionChip(
                    label: choiceLabel(choices[i].kind),
                    kcal: choices[i].kcal,
                    selected: choices[i].kcal == shown,
                    onTap: () => _applyCalories(choices[i].kcal.toDouble()),
                  ),
                ),
              ],
            ],
          ),
        ],
        if (note.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(note, style: AppTypography.secondary),
        ],
      ],
    );
  }

  Future<void> _editComponent(int index) async {
    final components = _meal.components;
    if (components == null || index >= components.length) return;
    final edit = await showComponentSheet(
      context,
      component: components[index],
      multiplier: _portionMultiplier,
      mealCalories: _meal.calories * _portionMultiplier,
      canRemove: components.length > 1,
    );
    if (edit == null || !mounted) return;
    final grams = edit.grams;
    final list = [...components];
    if (grams == null) {
      list.removeAt(index);
    } else {
      list[index] = list[index].withGrams(grams / _portionMultiplier);
    }
    setState(() {
      final change = applyComponents(_meal, list, _portionMultiplier);
      _meal = change.meal;
      _portionMultiplier = change.multiplier;
      _originalCalories = _meal.calories;
    });
  }

  /// One-tap correction: the calories become [kcal] and the macros follow.
  void _applyCalories(double kcal) {
    Haptics.tick();
    setState(() {
      _meal = mealWithCalories(
        _meal,
        portionMultiplier: _portionMultiplier,
        calories: kcal,
      );
    });
  }

  bool _hasPer100Reference() {
    return _meal.caloriesPer100g != null ||
        _meal.proteinPer100g != null ||
        _meal.carbsPer100g != null ||
        _meal.fatsPer100g != null;
  }

  Widget _buildNutritionOverview() {
    final l10n = context.l10n;
    final calories = (_meal.calories * _portionMultiplier).round();
    return Semantics(
      button: true,
      label: '$calories ${l10n.kcal}',
      hint: l10n.editCalories,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _showEditCaloriesDialog,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$calories', style: AppTypography.hero(size: 56)),
            const SizedBox(width: 8),
            Text(
              l10n.kcal,
              style: AppTypography.body.copyWith(color: AppColors.ink2),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit, size: 18, color: AppColors.ink3),
          ],
        ),
      ),
    );
  }

  /// Protein, carbohydrates and fat, each with its share of the calories as
  /// a thin ink bar. Protein leads: it is what a training day is about.
  Widget _buildMacroRows() {
    final l10n = context.l10n;
    final protein = _meal.protein * _portionMultiplier;
    final carbs = _meal.carbs * _portionMultiplier;
    final fats = _meal.fats * _portionMultiplier;
    final total = protein * 4 + carbs * 4 + fats * 9;
    double share(double kcal) => total <= 0 ? 0 : kcal / total;
    return Column(
      children: [
        _MacroRow(
          label: l10n.protein,
          grams: protein,
          share: share(protein * 4),
          strong: true,
          onTap: _editProtein,
        ),
        _MacroRow(
          label: l10n.carbs,
          grams: carbs,
          share: share(carbs * 4),
          onTap: _editCarbs,
        ),
        _MacroRow(
          label: l10n.fats,
          grams: fats,
          share: share(fats * 9),
          onTap: _editFats,
          last: true,
        ),
      ],
    );
  }

  void _editProtein() => _editMacro(_Macro.protein);
  void _editCarbs() => _editMacro(_Macro.carbs);
  void _editFats() => _editMacro(_Macro.fats);

  /// Edits one macro of the eaten amount. Calories follow the macros unless
  /// they were typed in by hand; a per-100 meal keeps its reference in step.
  void _editMacro(_Macro macro) {
    final l10n = context.l10n;
    final (label, current) = switch (macro) {
      _Macro.protein => (l10n.protein, _meal.protein),
      _Macro.carbs => (l10n.carbs, _meal.carbs),
      _Macro.fats => (l10n.fats, _meal.fats),
    };
    _showEditMacroDialog(label, current * _portionMultiplier, (value) {
      setState(() {
        final base = baseValueFromScaled(
          scaledValue: value,
          portionMultiplier: _portionMultiplier,
        );
        final protein = macro == _Macro.protein ? base : _meal.protein;
        final carbs = macro == _Macro.carbs ? base : _meal.carbs;
        final fats = macro == _Macro.fats ? base : _meal.fats;
        final calories = _meal.isCalorieOverride
            ? _meal.calories
            : protein * 4 + carbs * 4 + fats * 9;
        final per100 = isPer100Unit(_meal.portionUnit);
        _meal = _meal.copyWith(
          protein: protein,
          carbs: carbs,
          fats: fats,
          calories: calories,
          proteinPer100g: per100 && macro == _Macro.protein
              ? base
              : _meal.proteinPer100g,
          carbsPer100g: per100 && macro == _Macro.carbs
              ? base
              : _meal.carbsPer100g,
          fatsPer100g: per100 && macro == _Macro.fats
              ? base
              : _meal.fatsPer100g,
          caloriesPer100g: per100 && !_meal.isCalorieOverride
              ? calories
              : _meal.caloriesPer100g,
          components: null,
        );
      });
    });
  }

  bool _canEditPer100Reference() {
    return isPer100Unit(_meal.portionUnit);
  }

  String _numberOrEmpty(double? value, {int decimals = 1}) => value == null
      ? ''
      : PromptField.numberText(context, value, decimals: decimals);

  Future<void> _showEditPer100ReferenceDialog() async {
    if (!_canEditPer100Reference()) return;
    final l10n = context.l10n;
    final values = await showPromptDialog(
      context,
      title: '${l10n.edit} ${l10n.reference}',
      fields: [
        PromptField(
          initial: _numberOrEmpty(_meal.caloriesPer100g, decimals: 0),
          label: l10n.kcal.toUpperCase(),
          suffix: 'kcal',
          keyboardType: PromptField.number,
        ),
        PromptField(
          initial: _numberOrEmpty(_meal.fatsPer100g),
          label: l10n.fatsShort.toUpperCase(),
          suffix: 'g',
          keyboardType: PromptField.number,
        ),
        PromptField(
          initial: _numberOrEmpty(_meal.carbsPer100g),
          label: l10n.carbsShort.toUpperCase(),
          suffix: 'g',
          keyboardType: PromptField.number,
        ),
        PromptField(
          initial: _numberOrEmpty(_meal.proteinPer100g),
          label: l10n.proteinShort.toUpperCase(),
          suffix: 'g',
          keyboardType: PromptField.number,
        ),
      ],
    );
    if (values == null || !mounted) return;
    double? read(int i) => PromptField.parseNumber(values[i]);
    final calories = read(0);
    final fats = read(1);
    final carbs = read(2);
    final protein = read(3);
    setState(() {
      _meal = _meal.copyWith(
        components: null,
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
  }

  Widget _buildPer100Reference() {
    final l10n = context.l10n;
    final unit = _meal.portionUnit == 'ml' ? '100ml' : '100g';
    final canEdit = _canEditPer100Reference();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.reference} / $unit',
                  style: AppTypography.secondary.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (canEdit)
                InkWell(
                  onTap: _showEditPer100ReferenceDialog,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit, size: 16, color: AppColors.ink3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Per100Value(
                label: l10n.kcal,
                value: _meal.caloriesPer100g?.toStringAsFixed(0) ?? '-',
              ),
              _Per100Value(
                label: l10n.fatsShort,
                value: _formatPer100Macro(_meal.fatsPer100g),
              ),
              _Per100Value(
                label: l10n.carbsShort,
                value: _formatPer100Macro(_meal.carbsPer100g),
              ),
              _Per100Value(
                label: l10n.proteinShort,
                value: _formatPer100Macro(_meal.proteinPer100g),
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

enum _Macro { protein, carbs, fats }

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  /// Over the page instead of over a photo.
  final bool plain;

  const _GlassButton({
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.plain = false,
  });

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: plain ? AppColors.surface : Colors.black.withValues(alpha: 0.42),
        shape: BoxShape.circle,
        border: plain ? Border.all(color: AppColors.border) : null,
      ),
      child: Icon(icon, color: plain ? AppColors.text : Colors.white, size: 22),
    );
    if (onPressed == null) return circle;
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Haptics.tick();
          onPressed!();
        },
        child: circle,
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double grams;
  final double share;
  final bool strong;
  final bool last;
  final VoidCallback onTap;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.share,
    required this.onTap,
    this.strong = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final weight = strong ? FontWeight.w600 : FontWeight.w400;
    return Semantics(
      button: true,
      label: '$label ${grams.toStringAsFixed(1)} ${context.l10n.grams}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.border),
              bottom: last
                  ? BorderSide(color: AppColors.border)
                  : BorderSide.none,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.body.copyWith(fontWeight: weight),
                    ),
                  ),
                  Text(
                    grams.toStringAsFixed(1),
                    style: AppTypography.number(size: 17, weight: weight),
                  ),
                  Text(
                    ' ${context.l10n.grams}',
                    style: AppTypography.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ThinBar(share: share),
            ],
          ),
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
          Text(value, style: AppTypography.number(size: 17)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.meta),
        ],
      ),
    );
  }
}

/// One value the calories can be set to with a tap.
class _CorrectionChip extends StatelessWidget {
  final String label;
  final int kcal;
  final bool selected;
  final VoidCallback onTap;

  const _CorrectionChip({
    required this.label,
    required this.kcal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primary : AppColors.ink2;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $kcal kcal',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentSoft : AppColors.canvas,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTypography.secondary.copyWith(
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                    Text(
                      '$kcal kcal',
                      style: AppTypography.number(size: 13, color: foreground),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
