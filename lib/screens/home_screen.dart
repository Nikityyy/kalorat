import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_colors.dart';
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
        _showMessage(
          language == 'de'
              ? 'Du bist offline. Die Mahlzeit wird später analysiert.'
              : 'You are offline. The meal will be analyzed later.',
        );
      }
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final gemini = GeminiService(apiKey: apiKey, language: language);
      final result = await gemini.analyzeMeal(_capturedPhotos);

      if (result != null) {
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
      _showMessage(
        language == 'de' ? 'Fehler bei der Analyse: $e' : 'Analysis error: $e',
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveMeal() async {
    if (_analyzedMeal == null) return;

    final provider = context.read<AppProvider>();
    await provider.saveMeal(_analyzedMeal!);

    setState(() {
      _capturedPhotos = [];
      _analyzedMeal = null;
    });

    _showMessage(
      provider.language == 'de' ? 'Mahlzeit gespeichert!' : 'Meal saved!',
    );
  }

  void _showMessage(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
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
    final language = provider.language;
    final isOnline = provider.isOnline;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline) OfflineBanner(language: language),
            Expanded(child: _buildContent(language)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String language) {
    if (!_hasPermission) {
      return _buildPermissionRequest(language);
    }

    if (_analyzedMeal != null) {
      return _buildMealResult(language);
    }

    // Change: if we are in 'review' but click 'more', we go back to camera but keep state.
    // I'll add a boolean to toggle between 'review mode' and 'camera mode' if photos exist.
    if (_capturedPhotos.isNotEmpty && !_isTakingMore) {
      return _buildPhotoReview(language);
    }

    return _buildCamera(language);
  }

  bool _isTakingMore = false;

  Widget _buildPermissionRequest(String language) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.shamrock.withValues(alpha: 1.0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              language == 'de' ? 'Kamera benötigt' : 'Camera Access Needed',
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              language == 'de'
                  ? 'Damit Kalorat deine Mahlzeiten analysieren kann, benötigen wir Zugriff auf deine Kamera.'
                  : 'To analyze your meals, Kalorat needs access to your camera.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ActionButton(
              text: language == 'de'
                  ? 'Berechtigung erteilen'
                  : 'Grant Permission',
              onPressed: _initCamera,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera(String language) {
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
            child: CircularProgressIndicator(color: AppColors.shamrock),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      language == 'de'
                          ? 'Zurück zur Auswahl'
                          : 'Back to selection',
                      style: const TextStyle(
                        color: Colors.white,
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
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
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.shamrock,
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
                              border: Border.all(color: Colors.white, width: 2),
                              image: DecorationImage(
                                image: FileImage(File(_capturedPhotos.last)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.shamrock,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_capturedPhotos.length}',
                              style: const TextStyle(
                                color: Colors.white,
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

  Widget _buildPhotoReview(String language) {
    final isDe = language == 'de';

    return Container(
      color: AppColors.lavenderBlush,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            isDe ? 'Fotos überprüfen' : 'Review Photos',
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
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
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
                            color: Colors.white,
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
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
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
                            side: const BorderSide(color: AppColors.celadon),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Text(
                            isDe ? 'Verwerfen' : 'Discard',
                            style: const TextStyle(
                              color: AppColors.carbonBlack,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _isTakingMore = true),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.shamrock),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Text(
                            isDe ? '+ Foto' : '+ Photo',
                            style: const TextStyle(color: AppColors.shamrock),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ActionButton(
                    text: isDe ? 'Analyse starten' : 'Start Analysis',
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

  Widget _buildMealResult(String language) {
    final meal = _analyzedMeal!;
    final isDe = language == 'de';

    return Container(
      color: AppColors.lavenderBlush,
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
                    isDe ? 'Analyse Ergebnis' : 'Analysis Result',
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
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
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
                      color: AppColors.shamrock,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${meal.calories.toInt()}',
                          style: AppTypography.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 64,
                          ),
                        ),
                        Text(
                          isDe ? 'KALORIEN' : 'CALORIES',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
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
                        label: isDe ? 'Protein' : 'Protein',
                        value: '${meal.protein.toInt()}g',
                        color: const Color(0xFF4A90E2),
                        isDe: isDe,
                      ),
                      const SizedBox(width: 12),
                      _MacroCard(
                        label: isDe ? 'KH' : 'Carbs',
                        value: '${meal.carbs.toInt()}g',
                        color: const Color(0xFFF5A623),
                        isDe: isDe,
                      ),
                      const SizedBox(width: 12),
                      _MacroCard(
                        label: isDe ? 'Fett' : 'Fat',
                        value: '${meal.fats.toInt()}g',
                        color: const Color(0xFFD0021B),
                        isDe: isDe,
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  ActionButton(
                    text: isDe ? 'Speichern' : 'Save Meal',
                    onPressed: _saveMeal,
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _clearPhotos,
                    child: Text(
                      isDe ? 'Abbrechen' : 'Discard',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.carbonBlack.withValues(alpha: 0.5),
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
  final bool isDe;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.color,
    required this.isDe,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
                color: AppColors.carbonBlack.withValues(alpha: 0.5),
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
