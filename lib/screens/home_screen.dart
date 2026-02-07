import 'dart:convert';
import 'dart:io' show File;
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
import '../utils/platform_utils.dart';
import '../widgets/inputs/action_button.dart';
import '../widgets/widgets.dart';
import 'meal_detail_screen.dart';

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
    if (state == AppLifecycleState.inactive) {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        _cameraController?.dispose();
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isCameraInitialized) {
        _initCamera();
      }
    }
  }

  Future<void> _initCamera() async {
    // On web, camera APIs are not available - use image picker only
    if (PlatformUtils.isWeb) {
      if (mounted) setState(() => _hasPermission = true);
      return;
    }

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _hasPermission = false);
      return;
    }

    if (mounted) setState(() => _hasPermission = true);

    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error accessing cameras: $e');
      _cameras = [];
    }

    if (_cameras == null || _cameras!.isEmpty) {
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
      return;
    }

    // Dispose old controller if it exists
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

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
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    }
  }

  Future<void> _capturePhoto() async {
    // Camera capture not available on web
    if (PlatformUtils.isWeb) return;

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
      // On web, use Base64 string
      // On mobile, copy to app documents directory
      if (PlatformUtils.isWeb) {
        for (final image in images) {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          _capturedPhotos.add(base64Image);
        }
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        for (final image in images) {
          final fileName =
              'meal_${DateTime.now().millisecondsSinceEpoch}_${_capturedPhotos.length}.jpg';
          final savedPath = '${appDir.path}/$fileName';
          await File(image.path).copy(savedPath);
          _capturedPhotos.add(savedPath);
        }
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
        debugPrint('Analysis result received. Checking content...');
        if (result.containsKey('error') &&
            result['error'] == 'no_food_detected') {
          _showMessage(l10n.noFoodDetected);
          _clearPhotos();
          return;
        }

        try {
          debugPrint('Parsing meal data...');
          final finalMeal = MealModel(
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
          debugPrint('Meal parsed successfully: ${finalMeal.mealName}');

          if (mounted) {
            debugPrint('Pushing MealDetailScreen...');
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MealDetailScreen(meal: finalMeal, isNewEntry: true),
              ),
            );
            debugPrint('Returned from MealDetailScreen');
            _clearPhotos();
          }
        } catch (e, stack) {
          debugPrint('Error parsing/pushing: $e\n$stack');
          _showMessage(l10n.analysisError('Parse error: $e'));
        }
      }
    } catch (e) {
      debugPrint('Outer analysis error: $e');
      if (mounted) {
        _showMessage(l10n.analysisError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _showMessage(String message) {
    if (PlatformUtils.isIOS) {
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // 1. Background Image (Actual captured photo)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.35,
          child: PlatformUtils.isWeb
              ? Image.memory(
                  base64Decode(_capturedPhotos.first),
                  fit: BoxFit.cover,
                )
              : Image.file(File(_capturedPhotos.first), fit: BoxFit.cover),
        ),

        // 2. Back Button (Overlay)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                // Cancel analysis (user can go back)
              },
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
              child: Column(
                children: [
                  // Header Text (Analyzing...)
                  Text(
                    l10n.analyzing,
                    style: AppTypography.displayMedium.copyWith(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Skeleton Portion Control
                  Container(
                    width: 160,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.glacialWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Minus skeleton
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.pebble.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        // Text skeleton
                        const SkeletonBox(
                          width: 40,
                          height: 16,
                          borderRadius: 4,
                        ),
                        // Plus skeleton
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.pebble.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Skeleton Calories Card (Green)
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
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 8),
                        const SkeletonBox(
                          height: 16,
                          width: 80,
                          borderRadius: 4,
                          color: Colors.white24,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Skeleton Macros Row
                  Row(
                    children: [
                      Expanded(child: _buildSkeletonMacroCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSkeletonMacroCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildSkeletonMacroCard()),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Loading indicator
                  const CircularProgressIndicator(
                    color: AppColors.styrianForest,
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonMacroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.steel,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.borderGrey, width: 1),
      ),
      child: const Column(
        children: [
          SkeletonBox(height: 24, width: 50, borderRadius: 4),
          SizedBox(height: 4),
          SkeletonBox(height: 12, width: 40, borderRadius: 4),
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

    final bool canShowCamera =
        _isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized &&
        _cameraController!.value.previewSize != null;

    return Stack(
      children: [
        if (canShowCamera)
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(_cameraController!),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_cameras != null && _cameras!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No camera found. Please use Gallery.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.pebble,
                        ),
                      ),
                    )
                  else
                    const CircularProgressIndicator(
                      color: AppColors.styrianForest,
                    ),
                ],
              ),
            ),
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
                                image: PlatformUtils.isWeb
                                    ? NetworkImage(_capturedPhotos.last)
                                    : FileImage(File(_capturedPhotos.last))
                                          as ImageProvider,
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
                          child: PlatformUtils.isWeb
                              ? Image.memory(
                                  base64Decode(_capturedPhotos[index]),
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
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
}
