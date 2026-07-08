import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../extensions/l10n_extension.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/nutrition_units.dart';
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
  bool _isInitializingCamera = false;
  bool _isAnalyzing = false;
  List<String> _capturedPhotos = [];
  bool _isTakingMore = false;
  int _cameraPreviewKey = 0;
  String? _mealContext;
  bool _isTorchOn = false;
  bool _canUseTorch = true;
  bool _canZoom = false;
  bool _canTapFocus = true;
  bool _showZoomIndicator = false;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _currentZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;
  int _activePointers = 0;
  Offset? _focusIndicatorOffset;
  Timer? _focusIndicatorTimer;

  // Live thought summary text accumulated during streaming analysis
  String _liveThoughtText = '';
  AnalysisPhase _analysisPhase = AnalysisPhase.drafting;
  ImageProvider? _analysisHeroImageProvider;

  // FocusNode for context textarea — avoids the autofocus keyboard-jump bug
  final FocusNode _contextFocusNode = FocusNode();

  static const String _pendingPhotosBox = 'pending_photos_box';
  static const String _pendingPhotosKey = 'pending_photos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _restorePersistedPhotos();
  }

  @override
  void dispose() {
    try {
      context.read<AppProvider>().setMealAnalysisActive(false);
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    _focusIndicatorTimer?.cancel();
    _cameraController?.dispose();
    _contextFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (PlatformUtils.isWeb) return;

    if (state == AppLifecycleState.inactive) {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final controller = _cameraController;
        _cameraController = null;
        unawaited(controller?.dispose());
        setState(() {
          _isCameraInitialized = false;
          _isTorchOn = false;
          _canZoom = false;
          _showZoomIndicator = false;
          _focusIndicatorOffset = null;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isCameraInitialized) {
        _initCamera();
      }
    }
  }

  Future<void> _disposeCamera({bool clearCameraList = false}) async {
    final controller = _cameraController;
    _cameraController = null;
    if (clearCameraList) {
      _cameras = null;
    }
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
        _isTorchOn = false;
        _canUseTorch = true;
        _canZoom = false;
        _canTapFocus = !PlatformUtils.isWeb;
        _showZoomIndicator = false;
        _currentZoomLevel = 1.0;
        _minZoomLevel = 1.0;
        _maxZoomLevel = 1.0;
        _activePointers = 0;
        _focusIndicatorOffset = null;
        _cameraPreviewKey++;
      });
    }
    await controller?.dispose();
  }

  Future<CameraController> _createBestCameraController(
    CameraDescription camera,
  ) async {
    const presets = [ResolutionPreset.veryHigh, ResolutionPreset.high];

    Object? lastError;
    for (final preset in presets) {
      final controller = CameraController(
        camera,
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await controller.initialize();
        return controller;
      } catch (e) {
        lastError = e;
        await controller.dispose();
      }
    }

    throw CameraException(
      'cameraInitFailed',
      'Could not initialize camera at a supported resolution: $lastError',
    );
  }

  Future<void> _prepareCameraControls() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    double minZoom = 1.0;
    double maxZoom = 1.0;
    var canZoom = false;
    var canUseTorch = true;

    try {
      minZoom = await controller.getMinZoomLevel();
      maxZoom = await controller.getMaxZoomLevel();
      canZoom = maxZoom > minZoom;
      if (canZoom) {
        final initialZoom = _currentZoomLevel
            .clamp(minZoom, maxZoom)
            .toDouble();
        await controller.setZoomLevel(initialZoom);
        _currentZoomLevel = initialZoom;
      }
    } catch (e) {
      minZoom = 1.0;
      maxZoom = 1.0;
      canZoom = false;
      _currentZoomLevel = 1.0;
    }

    try {
      await controller.setFlashMode(FlashMode.off);
    } catch (e) {
      canUseTorch = false;
    }

    if (mounted) {
      setState(() {
        _minZoomLevel = minZoom;
        _maxZoomLevel = maxZoom;
        _canZoom = canZoom;
        _canUseTorch = canUseTorch;
        _canTapFocus = !PlatformUtils.isWeb;
        _isTorchOn = false;
      });
    }
  }

  Future<void> _initCamera({bool forceRestart = false}) async {
    if (_isInitializingCamera) return;
    if (!forceRestart &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      if (mounted) {
        setState(() {
          _hasPermission = true;
          _isCameraInitialized = true;
        });
      }
      return;
    }

    _isInitializingCamera = true;

    try {
      if (PlatformUtils.isWeb) {
        if (mounted) setState(() => _hasPermission = true);
      } else {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) setState(() => _hasPermission = false);
          return;
        }
        if (mounted) setState(() => _hasPermission = true);
      }

      if (_cameras == null || forceRestart) {
        try {
          _cameras = await availableCameras();
        } catch (e) {
          debugPrint('Error accessing cameras: $e');
          if (PlatformUtils.isWeb) {
            await Future<void>.delayed(const Duration(milliseconds: 350));
            try {
              _cameras = await availableCameras();
            } catch (retryError) {
              debugPrint('Camera retry failed: $retryError');
              _cameras = [];
            }
          } else {
            _cameras = [];
          }
        }
      }

      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() => _isCameraInitialized = false);
        }
        return;
      }

      if (_cameraController != null) {
        if (forceRestart || !_cameraController!.value.isInitialized) {
          await _cameraController!.dispose();
          _cameraController = null;
        }
      }

      if (_cameraController == null) {
        final selectedCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _cameraController = await _createBestCameraController(selectedCamera);
      }

      if (!_cameraController!.value.isInitialized) {
        await _cameraController!.initialize();
      }
      await _prepareCameraControls();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraPreviewKey++;
        });
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    } finally {
      _isInitializingCamera = false;
    }
  }

  /// Restore photos that were captured but not yet analyzed (e.g. after PWA refresh).
  Future<void> _restorePersistedPhotos() async {
    try {
      final box = await Hive.openBox<dynamic>(_pendingPhotosBox);
      final stored = box.get(_pendingPhotosKey);
      if (stored is List && stored.isNotEmpty && mounted) {
        setState(() {
          _capturedPhotos = List<String>.from(stored);
        });
      }
    } catch (_) {
      // Non-critical: ignore restore errors
    }
  }

  /// Persist current photo list so it survives a PWA reload / app restart.
  Future<void> _persistPhotos() async {
    try {
      final box = await Hive.openBox<dynamic>(_pendingPhotosBox);
      await box.put(_pendingPhotosKey, List<String>.from(_capturedPhotos));
    } catch (_) {}
  }

  /// Clear persisted photos after analysis or discard.
  Future<void> _clearPersistedPhotos() async {
    try {
      final box = await Hive.openBox<dynamic>(_pendingPhotosBox);
      await box.delete(_pendingPhotosKey);
    } catch (_) {}
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

      String storedPhoto;
      if (PlatformUtils.isWeb) {
        final bytes = await photo.readAsBytes();
        storedPhoto = base64Encode(bytes);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'meal_${DateTime.now().millisecondsSinceEpoch}_${_capturedPhotos.length}.jpg';
        final savedPath = '${appDir.path}/$fileName';
        await File(photo.path).copy(savedPath);
        storedPhoto = savedPath;
      }

      setState(() {
        _capturedPhotos.add(storedPhoto);
      });
      await _persistPhotos();
      if (!_isTakingMore && _isTorchOn) {
        await _setTorchMode(false);
      }
      if (PlatformUtils.isWeb && _isTakingMore && mounted) {
        await _restartWebCameraStream();
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _restartWebCameraStream() async {
    if (!PlatformUtils.isWeb) return;

    await _disposeCamera();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await _initCamera(forceRestart: true);
  }

  Future<void> _setTorchMode(bool enabled) async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        !_canUseTorch) {
      return;
    }

    try {
      await controller.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
      if (mounted) {
        setState(() => _isTorchOn = enabled);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTorchOn = false;
          _canUseTorch = false;
        });
      }
    }
  }

  Future<void> _toggleTorch() async {
    await _setTorchMode(!_isTorchOn);
  }

  void _handlePreviewPointerDown(PointerDownEvent event) {
    _activePointers++;
  }

  void _handlePreviewPointerUp(PointerEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10).toInt();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoomLevel = _currentZoomLevel;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        !_canZoom ||
        _activePointers < 2) {
      return;
    }

    final nextZoom = (_baseZoomLevel * details.scale)
        .clamp(_minZoomLevel, _maxZoomLevel)
        .toDouble();
    if ((nextZoom - _currentZoomLevel).abs() < 0.01) return;

    try {
      await controller.setZoomLevel(nextZoom);
      if (mounted) {
        setState(() {
          _currentZoomLevel = nextZoom;
          _showZoomIndicator = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _canZoom = false);
      }
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (mounted) {
      setState(() => _showZoomIndicator = false);
    }
  }

  Offset _normalizePreviewPoint(
    Offset localPosition,
    BoxConstraints constraints,
    double cameraAspectRatio,
  ) {
    final previewWidth = constraints.maxWidth;
    final previewHeight = previewWidth / cameraAspectRatio;
    final widthScale = constraints.maxWidth / previewWidth;
    final heightScale = constraints.maxHeight / previewHeight;
    final scale = widthScale > heightScale ? widthScale : heightScale;
    final displayedWidth = previewWidth * scale;
    final displayedHeight = previewHeight * scale;
    final cropLeft = (constraints.maxWidth - displayedWidth) / 2;
    final cropTop = (constraints.maxHeight - displayedHeight) / 2;

    return Offset(
      ((localPosition.dx - cropLeft) / displayedWidth).clamp(0.0, 1.0),
      ((localPosition.dy - cropTop) / displayedHeight).clamp(0.0, 1.0),
    );
  }

  Future<void> _focusAtPoint(
    TapDownDetails details,
    BoxConstraints constraints,
    CameraController controller,
  ) async {
    if (_activePointers > 1 ||
        !controller.value.isInitialized ||
        !_canTapFocus) {
      return;
    }

    final normalizedPoint = _normalizePreviewPoint(
      details.localPosition,
      constraints,
      controller.value.aspectRatio,
    );

    _focusIndicatorTimer?.cancel();
    if (mounted) {
      setState(() => _focusIndicatorOffset = details.localPosition);
    }

    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (_) {}

    try {
      await controller.setFocusPoint(normalizedPoint);
    } catch (_) {
      if (mounted) {
        setState(() {
          _canTapFocus = false;
          _focusIndicatorOffset = null;
        });
      }
      return;
    }

    _focusIndicatorTimer = Timer(const Duration(milliseconds: 850), () {
      if (mounted) {
        setState(() => _focusIndicatorOffset = null);
      }
    });
  }

  Future<void> _pickFromGallery() async {
    if (PlatformUtils.isWeb) {
      await _disposeCamera();
    }

    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      imageQuality: 55,
      maxWidth: 1280,
      maxHeight: 1280,
      requestFullMetadata: false,
    );

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
      await _persistPhotos();
      if (PlatformUtils.isWeb && mounted) {
        setState(() => _isTakingMore = false);
      }
    } else if (PlatformUtils.isWeb && mounted) {
      if (_capturedPhotos.isEmpty) {
        await _initCamera();
      } else {
        setState(() => _isTakingMore = false);
      }
    }
  }

  Future<void> _deleteStoredPhotoIfDisposable(String photoPath) async {
    if (PlatformUtils.isWeb || photoPath.isEmpty) return;

    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Could not delete discarded photo: $e');
    }
  }

  Future<void> _removeCapturedPhoto(int index) async {
    if (index < 0 || index >= _capturedPhotos.length) return;

    final removedPhoto = _capturedPhotos[index];
    setState(() {
      _capturedPhotos.removeAt(index);
      if (_capturedPhotos.isEmpty) {
        _isTakingMore = false;
        _mealContext = null;
      }
    });

    await _deleteStoredPhotoIfDisposable(removedPhoto);

    if (_capturedPhotos.isEmpty) {
      await _clearPersistedPhotos();
      if (PlatformUtils.isWeb) {
        await _restartWebCameraStream();
      } else if (!_isCameraInitialized ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        await _initCamera();
      }
    } else {
      await _persistPhotos();
    }
  }

  ImageProvider _photoImageProvider(String photo) {
    return PlatformUtils.isWeb
        ? MemoryImage(base64Decode(photo))
        : FileImage(File(photo)) as ImageProvider;
  }

  Future<void> _saveCapturedPhoto(String photo) async {
    final l10n = context.l10n;

    try {
      if (PlatformUtils.isWeb) {
        final bytes = base64Decode(photo);
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
        await Gal.putImage(photo, album: 'Kalorat');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveToGallerySuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
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

  Future<void> _openCapturedPhoto(int index) async {
    if (index < 0 || index >= _capturedPhotos.length) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) {
        final photo = _capturedPhotos[index];

        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: Image(
                        image: _photoImageProvider(photo),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PhotoPreviewButton(
                        icon: Icons.close,
                        tooltip: 'Schliessen',
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                      Row(
                        children: [
                          _PhotoPreviewButton(
                            icon: Icons.download,
                            tooltip: context.l10n.saveToGallery,
                            onPressed: () => _saveCapturedPhoto(photo),
                          ),
                          const SizedBox(width: 10),
                          _PhotoPreviewButton(
                            icon: Icons.delete_outline,
                            tooltip: context.l10n.discard,
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await _removeCapturedPhoto(index);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _analyzeMeal({String? mealContext, bool background = false}) async {
    if (_capturedPhotos.isEmpty) return;

    final provider = context.read<AppProvider>();
    final isOnline = provider.isOnline;
    final apiKey = provider.apiKey;
    final language = provider.language;
    final l10n = context.l10n;

    final mealId = DateTime.now().millisecondsSinceEpoch.toString();

    if (background || !isOnline || apiKey.isEmpty) {
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
      await _clearPersistedPhotos();

      if (mounted) {
        if (background) {
          _showMessage(l10n.mealSavedBackground);
          if (isOnline && apiKey.isNotEmpty) {
            provider.processOfflineQueue();
          }
        } else {
          final message = !isOnline ? l10n.offlineMessage : l10n.enterApiKeyError;
          _showMessage(message);
        }
      }
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisHeroImageProvider = _capturedPhotos.isNotEmpty
          ? _photoImageProvider(_capturedPhotos.first)
          : null;
      _liveThoughtText = '';
      _analysisPhase = AnalysisPhase.drafting;
    });
    provider.setMealAnalysisActive(true);

    Map<String, dynamic>? result;

    try {
      final gemini = GeminiService(apiKey: apiKey, language: language);
      final stream = gemini.analyzeMealStream(
        _capturedPhotos,
        useGrams: provider.user?.useGramsByDefault ?? false,
        mealContext: mealContext,
        useAccurateMode: provider.user?.useAccurateMode ?? false,
      );

      await for (final event in stream) {
        if (!mounted) break;
        if (event is AnalysisPhaseChanged) {
          setState(() {
            _analysisPhase = event.phase;
            if (event.phase == AnalysisPhase.verifying &&
                !_liveThoughtText.contains(l10n.verifyingEstimate)) {
              _liveThoughtText =
                  '${_liveThoughtText.trimRight()}\n\n## ${l10n.verifyingEstimate}\n\n';
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
    } catch (e) {
      debugPrint('Analysis stream error: $e');
      if (mounted) {
        String errorMsg;
        if (e is GeminiError && e.type == GeminiErrorType.timedOut) {
          errorMsg = l10n.analysisTimedOut;
        } else {
          errorMsg = l10n.analysisError(e.toString());
        }
        setState(() {
          _isAnalyzing = false;
          _analysisHeroImageProvider = null;
        });
        provider.setMealAnalysisActive(false);
        _showMessage(errorMsg);
        setState(() => _liveThoughtText = '');
        return;
      }
    }

    if (result != null) {
      debugPrint('Analysis result received. Checking content...');
      if (result.containsKey('error') &&
          result['error'] == 'no_food_detected') {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _analysisHeroImageProvider = null;
          });
          provider.setMealAnalysisActive(false);
          _showMessage(l10n.noFoodDetected);
          _resetCaptureState();
        }
        return;
      }

      try {
        debugPrint('Parsing meal data...');
        final detectedPortion = normalizeDetectedPortion(result);
        final detectedUnit = detectedPortion.unit;
        final detectedQty = detectedPortion.quantity;
        final baseQuantityPerUnit = quantityPerUnitFor(detectedUnit);
        final finalMeal = MealModel(
          id: mealId,
          timestamp: DateTime.now(),
          photoPaths: List.from(_capturedPhotos),
          mealName: result['meal_name'] ?? '',
          calories: nutritionBaseValue(
            result,
            unit: detectedUnit,
            valueKey: 'calories',
            referenceKey: 'calories_per_100g',
          ),
          protein: nutritionBaseValue(
            result,
            unit: detectedUnit,
            valueKey: 'protein',
            referenceKey: 'protein_per_100g',
          ),
          carbs: nutritionBaseValue(
            result,
            unit: detectedUnit,
            valueKey: 'carbs',
            referenceKey: 'carbs_per_100g',
          ),
          fats: nutritionBaseValue(
            result,
            unit: detectedUnit,
            valueKey: 'fats',
            referenceKey: 'fats_per_100g',
          ),
          caloriesPer100g: (result['calories_per_100g'] as num?)?.toDouble(),
          proteinPer100g: (result['protein_per_100g'] as num?)?.toDouble(),
          carbsPer100g: (result['carbs_per_100g'] as num?)?.toDouble(),
          fatsPer100g: (result['fats_per_100g'] as num?)?.toDouble(),
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

        // Calculate portion data
        double detectedMultiplier = (detectedUnit == 'serving')
            ? detectedQty
            : (detectedQty / baseQuantityPerUnit);

        // Ensure we don't divide by zero
        if (detectedMultiplier <= 0) detectedMultiplier = 1.0;

        final mealWithPortion = finalMeal.copyWith(
          calories: finalMeal.calories,
          protein: finalMeal.protein,
          carbs: finalMeal.carbs,
          fats: finalMeal.fats,
          portionMultiplier: detectedMultiplier,
          portionUnit: detectedUnit,
          quantityPerUnit: baseQuantityPerUnit,
        );

        debugPrint('Meal parsed successfully: ${mealWithPortion.mealName}');

        if (mounted) {
          debugPrint('Pushing MealDetailScreen...');
          setState(() {
            _isAnalyzing = false;
            _analysisHeroImageProvider = null;
          });
          provider.setMealAnalysisActive(false);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MealDetailScreen(
                meal: mealWithPortion,
                isNewEntry: true,
                initialMealContext: mealContext,
              ),
            ),
          );
          debugPrint('Returned from MealDetailScreen');
          await _resetCaptureState();
        }
      } catch (e, stack) {
        debugPrint('Error parsing/pushing: $e\n$stack');
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _analysisHeroImageProvider = null;
          });
          provider.setMealAnalysisActive(false);
          _showMessage(l10n.analysisError('Parse error: $e'));
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisHeroImageProvider = null;
        });
        provider.setMealAnalysisActive(false);
        _showMessage(l10n.analysisError('No result received.'));
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

  Future<void> _resetCaptureState() async {
    setState(() {
      _capturedPhotos = [];
      _isTakingMore = false;
      _mealContext = null;
      // Prevent the old CameraPreview from being shown while reinitializing
      _isCameraInitialized = false;
    });
    await _clearPersistedPhotos();
    if (PlatformUtils.isWeb) {
      await _restartWebCameraStream();
    } else if (!_isCameraInitialized) {
      await _initCamera();
    }
  }

  Future<void> _clearPhotos() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardPhotos),
        content: Text(l10n.discardPhotosConfirm),
        backgroundColor: AppColors.limestone,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.slate),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.discard,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final photo in List<String>.from(_capturedPhotos)) {
        await _deleteStoredPhotoIfDisposable(photo);
      }
      await _resetCaptureState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isOnline = provider.isOnline;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildContent()),
          if (!isOnline)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: const OfflineBanner(),
            ),
        ],
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
        if (_analysisHeroImageProvider != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.35,
            child: Image(
              image: _analysisHeroImageProvider!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),

        // 2. Content Sheet
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
                  // Header Text (Analyzing...)
                  Text(
                    l10n.analyzing,
                    style: AppTypography.displayMedium.copyWith(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Live Thought Summary Panel - Focused solely on reasoning stream
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

  Widget _buildCameraPreview(CameraController controller) {
    return KeyedSubtree(
      key: ValueKey(_cameraPreviewKey),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Listener(
            onPointerDown: _handlePreviewPointerDown,
            onPointerUp: _handlePreviewPointerUp,
            onPointerCancel: _handlePreviewPointerUp,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              onTapDown: (details) =>
                  _focusAtPoint(details, constraints, controller),
              child: ClipRect(
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height:
                              constraints.maxWidth /
                              controller.value.aspectRatio,
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),
                    if (_focusIndicatorOffset != null)
                      Positioned(
                        left: _focusIndicatorOffset!.dx - 34,
                        top: _focusIndicatorOffset!.dy - 34,
                        child: IgnorePointer(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.pebble,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(34),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_showZoomIndicator && _canZoom)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 24,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${_currentZoomLevel.toStringAsFixed(1)}x',
                                style: const TextStyle(
                                  color: AppColors.pebble,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Switches back to camera mode with a fresh web media stream.
  Future<void> _switchToCameraMode() async {
    setState(() {
      _isTakingMore = true;
      _isCameraInitialized =
          _cameraController != null && _cameraController!.value.isInitialized;
    });
    if (PlatformUtils.isWeb) {
      await _restartWebCameraStream();
    } else if (!_isCameraInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      await _initCamera();
    }
  }

  Widget _buildCamera() {
    final l10n = context.l10n;

    final bool canShowCamera =
        _isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;

    return Stack(
      children: [
        if (canShowCamera)
          Positioned.fill(child: _buildCameraPreview(_cameraController!))
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
                        '${l10n.cameraNotAvailableWeb}\n${l10n.useGalleryInstead}',
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

        // Camera tools
        if (canShowCamera)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: Tooltip(
              message: _canUseTorch ? 'Flash' : 'Flash unavailable',
              child: GestureDetector(
                onTap: _canUseTorch ? () => _toggleTorch() : null,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _canUseTorch ? 1 : 0.45,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isTorchOn
                          ? AppColors.styrianForest
                          : Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.pebble.withValues(alpha: 0.75),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: AppColors.pebble,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Simple Top Bar
        if (_capturedPhotos.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: GestureDetector(
              onTap: () async {
                if (_isTorchOn) {
                  await _setTorchMode(false);
                }
                setState(() {
                  _isTakingMore = false;
                });
              },
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
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              top: 40,
            ),
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
                      onTap: () async {
                        if (_isTorchOn) {
                          await _setTorchMode(false);
                        }
                        setState(() => _isTakingMore = false);
                      },
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
                                    ? MemoryImage(
                                        base64Decode(_capturedPhotos.last),
                                      )
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
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
                      child: GestureDetector(
                        onTap: () => _openCapturedPhoto(index),
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
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          await _removeCapturedPhoto(index);
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
                          onPressed: _switchToCameraMode,
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
                    onPressed: _showContextAndAnalyze,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showContextAndAnalyze() async {
    final l10n = context.l10n;
    final contextController = TextEditingController(text: _mealContext);
    bool analyzeShouldRun = false;
    bool background = false;
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
              // Drag handle
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
                l10n.mealContextTitle,
                style: AppTypography.displayMedium.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contextController,
                // NO autofocus here — we use a FocusNode + postFrameCallback
                // to avoid the "textarea flies off screen" bug on mobile.
                focusNode: _contextFocusNode,
                maxLines: 3,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: l10n.mealContextHint,
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.slate.withValues(alpha: 0.5),
                  ),
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
                      onPressed: () {
                        submittedContext = null;
                        analyzeShouldRun = true;
                        Navigator.pop(sheetContext);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.pebble),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.mealContextSkip,
                        style: const TextStyle(color: AppColors.slate),
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
                        analyzeShouldRun = true;
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
                      child: Text(
                        l10n.mealContextAnalyze,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    final text = contextController.text.trim();
                    submittedContext = text.isNotEmpty ? text : null;
                    analyzeShouldRun = true;
                    background = true;
                    Navigator.pop(sheetContext);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.mealContextBackground,
                    style: const TextStyle(
                      color: AppColors.styrianForest,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Only analyze if user explicitly tapped the Analyze button
    if (analyzeShouldRun && mounted) {
      setState(() => _mealContext = submittedContext);
      await _analyzeMeal(mealContext: submittedContext, background: background);
    }
  }
}

class _PhotoPreviewButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _PhotoPreviewButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.46),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: AppColors.glacialWhite),
        ),
      ),
    );
  }
}
