import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../extensions/l10n_extension.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/inputs/action_button.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  bool _isCapturing = false;
  bool _isAnalyzing = false;
  List<String> _capturedPhotos = [];
  MealModel? _analyzedMeal;
  bool _isTakingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _hasPermission = false);
      return;
    }

    setState(() => _hasPermission = true);

    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    _cameraController = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _cameraController!.takePicture();

      // Save to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'meal_${DateTime.now().millisecondsSinceEpoch}_${_capturedPhotos.length}.jpg';
      final savedPath = '${appDir.path}/$fileName';
      await File(photo.path).copy(savedPath);

      setState(() {
        _capturedPhotos.add(savedPath);
      });
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      final appDir = await getApplicationDocumentsDirectory();
      for (final image in images) {
        final fileName =
            'meal_${DateTime.now().millisecondsSinceEpoch}_${_capturedPhotos.length}.jpg';
        final savedPath = '${appDir.path}/$fileName';
        await File(image.path).copy(savedPath);
        _capturedPhotos.add(savedPath);
      }
      setState(() {});
    }
  }

  Future<void> _analyzeMeal() async {
    if (_capturedPhotos.isEmpty) return;

    final provider = context.read<AppProvider>();
    final isOnline = provider.isOnline;
    final apiKey = provider.apiKey;
    final language = provider.language;
    final l10n = context.l10n;

    final mealId = DateTime.now().millisecondsSinceEpoch.toString();

    if (!isOnline || apiKey.isEmpty) {
      // Save as pending
      final meal = MealModel(
        id: mealId,
        timestamp: DateTime.now(),
        photoPaths: List.from(_capturedPhotos),
        isPending: true,
      );
      await provider.saveMeal(meal);

      setState(() {
        _capturedPhotos = [];
        _analyzedMeal = null;
      });

      if (mounted) {
        _showMessage(l10n.offlineMessage);
      }
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final gemini = GeminiService(apiKey: apiKey, language: language);
      final result = await gemini.analyzeMeal(_capturedPhotos);

      if (result != null) {
        if (result.containsKey('error') &&
            result['error'] == 'no_food_detected') {
          _showMessage(l10n.noFoodDetected);
          _clearPhotos();
          return;
        }

        final meal = MealModel(
          id: mealId,
          timestamp: DateTime.now(),
          photoPaths: List.from(_capturedPhotos),
          mealName: result['meal_name'] ?? '',
          calories: (result['calories'] ?? 0).toDouble(),
          protein: (result['protein'] ?? 0).toDouble(),
          carbs: (result['carbs'] ?? 0).toDouble(),
          fats: (result['fats'] ?? 0).toDouble(),
          vitamins: result['vitamins'] != null
              ? Map<String, double>.from(
                  (result['vitamins'] as Map).map(
                    (k, v) => MapEntry(k.toString(), (v ?? 0).toDouble()),
                  ),
                )
              : null,
          minerals: result['minerals'] != null
              ? Map<String, double>.from(
                  (result['minerals'] as Map).map(
                    (k, v) => MapEntry(k.toString(), (v ?? 0).toDouble()),
                  ),
                )
              : null,
          isPending: false,
        );

        setState(() {
          _analyzedMeal = meal;
        });
      }
    } catch (e) {
      _showMessage(l10n.analysisError(e.toString()));
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveMeal() async {
    if (_analyzedMeal == null) return;

    final provider = context.read<AppProvider>();
    final l10n = context.l10n;
    await provider.saveMeal(_analyzedMeal!);

    setState(() {
      _capturedPhotos = [];
      _analyzedMeal = null;
    });

    _showMessage(l10n.mealSaved);
  }

  void _showMessage(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text(context.l10n.ok),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _clearPhotos() {
    setState(() {
      _capturedPhotos = [];
      _analyzedMeal = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isOnline = provider.isOnline;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline) const OfflineBanner(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    if (_analyzedMeal != null) {
      return _buildMealResult();
    }

    // Show skeleton loading screen while analyzing
    if (_isAnalyzing) {
      return _buildAnalyzingSkeleton();
    }

    // Change: if we are in 'review' but click 'more', we go back to camera but keep state.
    // I'll add a boolean to toggle between 'review mode' and 'camera mode' if photos exist.
    if (_capturedPhotos.isNotEmpty && !_isTakingMore) {
      return _buildPhotoReview();
    }

    return _buildCamera();
  }

  Widget _buildAnalyzingSkeleton() {
    final l10n = context.l10n;

    return Container(
      color: AppColors.glacialWhite,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    // Cancel analysis (user can go back)
                  },
                ),
                Expanded(
                  child: Text(
                    l10n.analyzing,
                    style: AppTypography.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Skeleton Image Preview
                  const SkeletonBox(
                    height: 200,
                    width: double.infinity,
                    borderRadius: 16,
                  ),

                  const SizedBox(height: 32),

                  // Skeleton Meal Name
                  const SkeletonBox(height: 36, width: 200, borderRadius: 8),

                  const SizedBox(height: 32),

                  // Skeleton Calories Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.styrianForest,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                      border: Border.all(color: AppColors.borderGrey, width: 1),
                    ),
                    child: Column(
                      children: [
                        const SkeletonBox(
                          height: 64,
                          width: 120,
                          borderRadius: 8,
                        ),
                        const SizedBox(height: 8),
                        SkeletonBox(height: 16, width: 80, borderRadius: 4),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Skeleton Macros Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.steel,
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            border: Border.all(
                              color: AppColors.styrianForest.withValues(
                                alpha: 0.2,
                              ),
                              width: 2,
                            ),
                          ),
                          child: const Column(
                            children: [
                              SkeletonBox(
                                height: 24,
                                width: 50,
                                borderRadius: 4,
                              ),
                              SizedBox(height: 4),
                              SkeletonBox(
                                height: 12,
                                width: 40,
                                borderRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pebble,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.styrianForest.withValues(
                                alpha: 0.2,
                              ),
                              width: 2,
                            ),
                          ),
                          child: const Column(
                            children: [
                              SkeletonBox(
                                height: 24,
                                width: 50,
                                borderRadius: 4,
                              ),
                              SizedBox(height: 4),
                              SkeletonBox(
                                height: 12,
                                width: 40,
                                borderRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pebble,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.styrianForest.withValues(
                                alpha: 0.2,
                              ),
                              width: 2,
                            ),
                          ),
                          child: const Column(
                            children: [
                              SkeletonBox(
                                height: 24,
                                width: 50,
                                borderRadius: 4,
                              ),
                              SizedBox(height: 4),
                              SkeletonBox(
                                height: 12,
                                width: 40,
                                borderRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Loading indicator with text
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.styrianForest,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.analyzingMeal,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.slate.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.styrianForest.withValues(alpha: 1.0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: AppColors.glacialWhite,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.cameraNeeded,
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.cameraPermissionText,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ActionButton(text: l10n.grantPermission, onPressed: _initCamera),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera() {
    final l10n = context.l10n;
    return Stack(
      children: [
        if (_isCameraInitialized && _cameraController != null)
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          )
        else
          const Center(
            child: CircularProgressIndicator(color: AppColors.styrianForest),
          ),

        // Simple Top Bar
        if (_capturedPhotos.isNotEmpty)
          Positioned(
            top: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => setState(() => _isTakingMore = false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      color: AppColors.pebble,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.backToSelection,
                      style: const TextStyle(
                        color: AppColors.pebble,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bottom Controls Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(bottom: 60, top: 40),
            decoration: const BoxDecoration(color: Colors.black45),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Left: Gallery
                Positioned(
                  left: 40,
                  child: GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.pebble.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.pebble,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                // Center: Capture
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.pebble, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: AppColors.pebble,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.styrianForest,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Right: Done/Review if photos exist
                if (_capturedPhotos.isNotEmpty)
                  Positioned(
                    right: 40,
                    child: GestureDetector(
                      onTap: () => setState(() => _isTakingMore = false),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.pebble,
                                width: 2,
                              ),
                              image: DecorationImage(
                                image: FileImage(File(_capturedPhotos.last)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.styrianForest,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_capturedPhotos.length}',
                              style: const TextStyle(
                                color: AppColors.pebble,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoReview() {
    final l10n = context.l10n;

    return Container(
      color: AppColors.glacialWhite,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.reviewPhotos,
            style: AppTypography.displayMedium.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: _capturedPhotos.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                          border: Border.all(
                            color: AppColors.borderGrey,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                          child: Image.file(
                            File(_capturedPhotos[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _capturedPhotos.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: AppColors.pebble,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.glacialWhite,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.borderRadius),
              ),
              border: Border(
                top: BorderSide(color: AppColors.borderGrey, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearPhotos,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.pebble),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.discard,
                            style: const TextStyle(color: AppColors.slate),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isTakingMore = true),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.styrianForest,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.addPhoto,
                            style: const TextStyle(
                              color: AppColors.styrianForest,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    text: l10n.startAnalysis,
                    isLoading: _isAnalyzing,
                    onPressed: _analyzeMeal,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealResult() {
    final meal = _analyzedMeal!;
    final l10n = context.l10n;

    return Container(
      color: AppColors.glacialWhite,
      child: Column(
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _clearPhotos,
                ),
                Expanded(
                  child: Text(
                    l10n.analysisResult,
                    style: AppTypography.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Placeholder for symmetry
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Image Preview
                  if (meal.photoPaths.isNotEmpty)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                        border: Border.all(
                          color: AppColors.borderGrey,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: meal.photoPaths.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (ctx, i) => Image.file(
                            File(meal.photoPaths[i]),
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Meal Name
                  Text(
                    meal.mealName,
                    style: AppTypography.displayMedium.copyWith(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Calories Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: AppColors.styrianForest,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                      border: Border.all(color: AppColors.borderGrey, width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${meal.calories.toInt()}',
                          style: AppTypography.heroNumber.copyWith(
                            color: AppColors.glacialWhite,
                            fontSize: 64,
                          ),
                        ),
                        Text(
                          l10n.calories.toUpperCase(),
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.glacialWhite.withValues(
                              alpha: 0.7,
                            ),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Macros Row
                  Row(
                    children: [
                      _MacroCard(
                        label: l10n.protein,
                        value: '${meal.protein.toInt()}g',
                        color: AppColors.styrianForest,
                      ),
                      const SizedBox(width: 12),
                      _MacroCard(
                        label: l10n.carbs,
                        value: '${meal.carbs.toInt()}g',
                        color: AppColors.styrianForest,
                      ),
                      const SizedBox(width: 12),
                      _MacroCard(
                        label: l10n.fats,
                        value: '${meal.fats.toInt()}g',
                        color: AppColors.styrianForest,
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  ActionButton(text: l10n.saveMeal, onPressed: _saveMeal),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _clearPhotos,
                    child: Text(
                      l10n.discard,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.slate.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
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

  const _MacroCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.steel,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                color: color,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: AppTypography.labelLarge.copyWith(
                fontSize: 10,
                color: AppColors.frost.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
