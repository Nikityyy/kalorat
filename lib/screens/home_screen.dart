import 'dart:async';
import 'dart:io' show File;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show Uint8List, ValueListenable;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../extensions/l10n_extension.dart';
import '../extensions/validation_l10n.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../services/offline_queue_service.dart';
import '../services/photo_store.dart';
import '../utils/photo_downscale.dart';
import '../services/gemini_service.dart';
import '../services/hints/first_use_hints.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/analysis_error_message.dart';
import '../utils/analysis_parser.dart';
import '../utils/analysis_tracker.dart';
import '../utils/save_photo.dart';
import '../utils/platform_utils.dart';
import '../utils/web_cameras.dart';
import '../widgets/common/adaptive.dart';
import '../widgets/widgets.dart';
import 'home/analyzing_view.dart';
import 'home/camera_controls.dart';
import 'home/camera_switch_veil.dart';
import 'home/camera_permission_request.dart';
import 'home/meal_context_sheet.dart';
import 'home/camera_diagnostics_dialog.dart';
import 'home/photo_review_view.dart';
import 'home/photo_viewer.dart';
import 'home/quick_log_sheet.dart';
import '../l10n/app_localizations.dart';
import '../services/barcode/food_product.dart';
import '../services/barcode/gtin.dart';
import '../services/barcode/live_barcode_scanner.dart';
import '../services/barcode/product_lookup_service.dart';
import '../services/barcode/scan_region.dart';
import '../utils/haptics.dart';
import 'meal_detail_screen.dart';
import '../utils/camera_diagnostics.dart';
import '../utils/camera_preview.dart';
import '../widgets/app_toast.dart';

class HomeScreen extends StatefulWidget {
  final bool isActive;
  final ValueListenable<bool>? activeListenable;

  /// Set to true while two fingers pinch the preview, so the tab pager does
  /// not take the gesture.
  final ValueNotifier<bool>? pagingLock;

  const HomeScreen({
    super.key,
    this.isActive = true,
    this.activeListenable,
    this.pagingLock,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isPreviewPaused = false;
  bool _hasPermission = false;
  bool _isCapturing = false;
  bool _isInitializingCamera = false;
  bool _isAnalyzing = false;
  bool _showCameraHint = !FirstUseHints.seen(FirstUseHint.camera);
  List<String> _capturedPhotos = [];
  bool _isTakingMore = false;
  int _cameraPreviewKey = 0;
  BoxConstraints? _lastPreviewConstraints;
  int? _selectedCameraIndex;
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

  // Barcodes are read in the background while the camera shows no photos.
  final LiveBarcodeScanner _barcodeScanner = LiveBarcodeScanner();
  final ProductLookupService _productLookup = ProductLookupService();
  CameraController? _barcodeController;
  Future<void> _barcodeSync = Future.value();
  bool _routeIsCurrent = true;
  bool _usingQuickCameras = false;

  /// While the camera switches between back and front.
  bool _isSwitchingCamera = false;
  // The last picture, softened, over the preview while the camera starts
  // again (see _coverPreview).
  Uint8List? _veil;
  bool _veilMirrored = false;
  bool _veilReveal = false;
  bool _quickCamerasFailed = false;
  Future<void> _previewSync = Future.value();
  bool _barcodeBusy = false;
  String? _lastBarcode;
  DateTime _lastBarcodeSeen = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _barcodeQuietUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// The code the guide has closed around while its product is looked up.
  GuideLock? _guideLock;

  /// After a failed lookup the user may photograph the nutrition label; the
  /// code that failed is then ignored, so it does not interrupt again.
  bool _labelMode = false;
  String? _labelModeCode;

  /// A product whose barcode is in one of the picked photos; the notes sheet
  /// offers its values. [_photoBarcodeSource] is that photo.
  final ValueNotifier<FoodProduct?> _photoBarcode = ValueNotifier(null);
  String? _photoBarcodeSource;
  int _photoScanGeneration = 0;

  // What the running analysis has found so far, for the analysing view.
  final AnalysisTracker _tracker = AnalysisTracker();
  ImageProvider? _analysisHeroImageProvider;

  static const String _pendingPhotosBox = DatabaseService.pendingPhotosBoxName;
  static const String _pendingPhotosKey = DatabaseService.pendingPhotosKey;

  bool get _cameraTabIsActive =>
      widget.activeListenable?.value ?? widget.isActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.activeListenable?.addListener(_handleCameraTabActivity);
    if (!_cameraTabIsActive) {
      // The tab will initialize the camera when first selected.
    } else if (PlatformUtils.isWeb) {
      unawaited(_initWebCameraIfGranted());
    } else {
      _initCamera();
    }
    _restorePersistedPhotos();
  }

  void _handleCameraTabActivity() {
    final controller = _cameraController;
    if (!_cameraTabIsActive && _labelMode) setState(_leaveLabelMode);
    if (_cameraTabIsActive &&
        (controller == null || !controller.value.isInitialized)) {
      unawaited(_initCamera());
    } else {
      _syncCameraPreview();
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      unawaited(_resumeCameraPreview());
    } else {
      unawaited(_pauseCameraPreview());
    }
  }

  Future<void> _pauseCameraPreview() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isPreviewPaused) {
      return;
    }
    if (_isTorchOn) await _setTorchMode(false);
    await _stopBarcodeScanner();
    // A paused preview keeps its last frame, sharp; the soft cover hides
    // that until the camera plays again.
    await _coverPreview();
    try {
      await controller.pausePreview();
      _isPreviewPaused = true;
    } catch (_) {}
  }

  /// Lays the last picture of the preview, softened, over it, until
  /// [_revealPreview] fades it into the live picture: while the other camera
  /// starts, or while the camera tab is away and comes back. Web only; the
  /// snapshot takes a few milliseconds.
  Future<void> _coverPreview() async {
    final bytes = await previewSnapshot();
    if (!mounted || bytes == null) return;
    setState(() {
      _veil = bytes;
      _veilMirrored = _frontCamera;
      _veilReveal = false;
    });
  }

  /// Fades the cover out once the preview shows a new frame.
  Future<void> _revealPreview() async {
    final veil = _veil;
    if (veil == null) return;
    await previewNextFrame();
    if (mounted && identical(_veil, veil)) {
      setState(() => _veilReveal = true);
    }
  }

  Future<void> _resumeCameraPreview() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      await _initCamera();
      return;
    }
    if (!_isPreviewPaused) return;
    try {
      await controller.resumePreview();
      _isPreviewPaused = false;
      unawaited(_revealPreview());
      _syncBarcodeScanner();
    } catch (_) {
      await _initCamera(forceRestart: true);
    }
  }

  /// Plays the preview only while the camera tab is on screen and nothing
  /// covers it. Behind the photo review the live preview would only cost
  /// frames (on an iPhone it is drawn into a canvas each frame, which made
  /// taps on the review screen lag). Calls are serialized, so quick swipes
  /// back and forth end in the state of the last one.
  void _syncCameraPreview() {
    _previewSync = _previewSync
        .then((_) async {
          final controller = _cameraController;
          if (!mounted ||
              controller == null ||
              !controller.value.isInitialized) {
            return;
          }
          if (!_cameraTabIsActive) {
            await _pauseCameraPreview();
            return;
          }
          if (_isAnalyzing) return;
          final covered = _capturedPhotos.isNotEmpty && !_isTakingMore;
          if (covered && !_isPreviewPaused) {
            await _pauseCameraPreview();
          } else if (!covered && _isPreviewPaused) {
            await _resumeCameraPreview();
          }
        })
        .catchError((Object e) => debugPrint('Camera preview: $e'));
  }

  Future<void> _initWebCameraIfGranted() async {
    final provider = context.read<AppProvider>();
    if (await provider.hasCameraPermission() && mounted) {
      await _initCamera();
    }
  }

  @override
  void dispose() {
    try {
      context.read<AppProvider>().setMealAnalysisActive(false);
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    widget.activeListenable?.removeListener(_handleCameraTabActivity);
    _focusIndicatorTimer?.cancel();
    _logoTapTimer?.cancel();
    _photoScanGeneration++;
    _photoBarcode.dispose();
    _tracker.dispose();
    final controller = _cameraController;
    unawaited(
      _barcodeScanner.dispose().whenComplete(() => controller?.dispose()),
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (PlatformUtils.isWeb) return;

    if (state == AppLifecycleState.inactive) {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final controller = _cameraController;
        _cameraController = null;
        unawaited(
          _stopBarcodeScanner().whenComplete(() => controller?.dispose()),
        );
        setState(() {
          _isCameraInitialized = false;
          _isTorchOn = false;
          _canZoom = false;
          _showZoomIndicator = false;
          _focusIndicatorOffset = null;
        });
      }
    } else if (state == AppLifecycleState.resumed && _cameraTabIsActive) {
      if (!_isCameraInitialized) {
        _initCamera();
      }
    }
  }

  /// The back camera first, then the front one. On the web they come from
  /// [quickWebCameras] when possible: the plugin's own list opens every
  /// camera of the phone one after the other, which made the first picture
  /// late.
  Future<List<CameraDescription>> _findCameras() async {
    if (PlatformUtils.isWeb && !_quickCamerasFailed) {
      final quick = await quickWebCameras();
      if (quick != null) {
        _usingQuickCameras = true;
        return quick;
      }
    }
    _usingQuickCameras = false;
    for (var attempt = 0; ; attempt++) {
      try {
        final all = await availableCameras();
        final filtered = [
          for (final direction in [
            CameraLensDirection.back,
            CameraLensDirection.front,
          ])
            ?all.where((c) => c.lensDirection == direction).firstOrNull,
        ];
        return filtered.isNotEmpty ? filtered : all;
      } catch (e) {
        debugPrint('Error accessing cameras: $e');
        // The web camera is sometimes still held by the previous page.
        if (!PlatformUtils.isWeb || attempt > 0) return [];
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }
  }

  /// A kept camera id that no longer opens: forget the kept ids and find
  /// the cameras the plugin's way. True when the caller should retry.
  bool _dropQuickCameras() {
    if (!_usingQuickCameras) return false;
    forgetQuickWebCameras();
    _usingQuickCameras = false;
    _quickCamerasFailed = true;
    _cameras = null;
    return true;
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
        // The format of the image stream the barcode scanner reads (ML Kit
        // takes NV21 on Android, BGRA on iOS). Photos are JPEG either way.
        imageFormatGroup: PlatformUtils.isAndroid
            ? ImageFormatGroup.nv21
            : PlatformUtils.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.jpeg,
      );

      try {
        await controller.initialize();
        return controller;
      } catch (e) {
        lastError = e;
        // The web plugin throws when it disposes a camera that never got a
        // stream; that must not keep the next preset from being tried.
        await controller.dispose().catchError((Object _) {});
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
    var retry = false;

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

      if (_cameras == null || forceRestart) _cameras = await _findCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() => _isCameraInitialized = false);
        }
        return;
      }

      if (_cameraController != null) {
        if (forceRestart || !_cameraController!.value.isInitialized) {
          await _stopBarcodeScanner();
          await _cameraController!.dispose();
          _cameraController = null;
        }
      }

      if (_cameraController == null) {
        _selectedCameraIndex ??= _cameras!.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        if (_selectedCameraIndex! < 0) _selectedCameraIndex = 0;
        final selectedCamera = _cameras![_selectedCameraIndex!];

        _cameraController = await _createBestCameraController(selectedCamera);
      }

      if (!_cameraController!.value.isInitialized) {
        await _cameraController!.initialize();
      }
      await _prepareCameraControls();
      _barcodeScanner.prewarm();
      unawaited(_productLookup.prewarm());
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isPreviewPaused = false;
          _cameraPreviewKey++;
        });
      }
      unawaited(_revealPreview());
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (_dropQuickCameras()) {
        retry = true;
      } else if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    } finally {
      _isInitializingCamera = false;
      if (mounted) setState(() => _isSwitchingCamera = false);
    }
    if (retry) await _initCamera(forceRestart: true);
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

    if (_capturedPhotos.length >= 5) {
      _showMessage(context.l10n.rateLimitPhotos);
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await _cameraController!.takePicture();

      String storedPhoto;
      if (PlatformUtils.isWeb) {
        final bytes = await downscaleForStorage(await photo.readAsBytes());
        storedPhoto = await PhotoStore.instance.save(bytes);
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
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  int _logoTaps = 0;
  Timer? _logoTapTimer;

  void _onLogoTap() {
    _logoTaps++;
    _logoTapTimer?.cancel();
    _logoTapTimer = Timer(const Duration(milliseconds: 1500), () {
      _logoTaps = 0;
    });
    if (_logoTaps >= 5) {
      _logoTaps = 0;
      _logoTapTimer?.cancel();
      _showCameraDiagnostics();
    }
  }

  /// Shows the numbers needed to diagnose a camera layout problem that cannot
  /// be reproduced elsewhere (long press on the logo).
  void _showCameraDiagnostics() {
    final controller = _cameraController;
    final media = MediaQuery.of(context);
    final lines = <String>[
      'app size ${media.size.width.toStringAsFixed(1)}x${media.size.height.toStringAsFixed(1)}'
          ' dpr ${media.devicePixelRatio} padding top ${media.padding.top} bottom ${media.padding.bottom}',
      'preview area ${_lastPreviewConstraints?.biggest}',
      if (controller != null && controller.value.isInitialized) ...[
        'camera aspect ${controller.value.aspectRatio} previewSize ${controller.value.previewSize}',
        'orientation ${controller.value.deviceOrientation} paused $_isPreviewPaused',
      ] else
        'camera not initialized',
      'key $_cameraPreviewKey tabActive $_cameraTabIsActive',
      browserCameraDiagnostics(),
    ];
    showCameraDiagnosticsDialog(context, lines);
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

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2 || _isInitializingCamera) {
      return;
    }
    _isInitializingCamera = true;
    var retry = false;
    final oldController = _cameraController;
    final nextIndex = ((_selectedCameraIndex ?? 0) + 1) % _cameras!.length;
    await _coverPreview();
    if (mounted) {
      setState(() {
        _isSwitchingCamera = true;
        _isCameraInitialized = false;
      });
    }
    try {
      if (_isTorchOn) await _setTorchMode(false);
      await _stopBarcodeScanner();
      await oldController?.dispose();
      _selectedCameraIndex = nextIndex;
      _cameraController = await _createBestCameraController(
        _cameras![nextIndex],
      );
      await _prepareCameraControls();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isPreviewPaused = false;
          _cameraPreviewKey++;
        });
      }
      unawaited(_revealPreview());
    } catch (e) {
      debugPrint('Camera switch error: $e');
      _cameraController = null;
      _veil = null;
      if (_dropQuickCameras()) {
        retry = true;
      } else if (mounted) {
        setState(() => _isCameraInitialized = false);
      }
    } finally {
      _isInitializingCamera = false;
      if (mounted) setState(() => _isSwitchingCamera = false);
    }
    if (retry) await _initCamera(forceRestart: true);
  }

  // Pinch zoom is read from raw pointers instead of a ScaleGestureRecognizer:
  // that recognizer also takes one-finger drags, which would stop the tab
  // pager from ever seeing a swipe over the camera.
  final Map<int, Offset> _pinchPointers = {};
  double? _pinchStartDistance;

  double _pinchDistance() {
    final points = _pinchPointers.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  void _handlePreviewPointerDown(PointerDownEvent event) {
    _activePointers++;
    _pinchPointers[event.pointer] = event.position;
    if (_pinchPointers.length >= 2 && _pinchStartDistance == null) {
      widget.pagingLock?.value = true;
      _pinchStartDistance = _pinchDistance();
      _handleScaleStart(ScaleStartDetails(pointerCount: 2));
    }
  }

  void _handlePreviewPointerMove(PointerMoveEvent event) {
    if (!_pinchPointers.containsKey(event.pointer)) return;
    _pinchPointers[event.pointer] = event.position;
    final start = _pinchStartDistance;
    if (start != null && start > 0 && _pinchPointers.length >= 2) {
      _handleScaleUpdate(
        ScaleUpdateDetails(scale: _pinchDistance() / start, pointerCount: 2),
      );
    }
  }

  void _handlePreviewPointerUp(PointerEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10).toInt();
    _pinchPointers.remove(event.pointer);
    if (_pinchPointers.length < 2 && _pinchStartDistance != null) {
      _pinchStartDistance = null;
      _handleScaleEnd(ScaleEndDetails());
    }
    if (_pinchPointers.length < 2) widget.pagingLock?.value = false;
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
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      imageQuality: 55,
      maxWidth: 1280,
      maxHeight: 1280,
      requestFullMetadata: false,
    );

    if (images.isNotEmpty) {
      if (!mounted) return;
      if (_capturedPhotos.length + images.length > 5) {
        _showMessage(context.l10n.rateLimitPhotos);
        return;
      }

      // On web, store in the photo store
      // On mobile, copy to app documents directory
      final stored = <String>[];
      if (PlatformUtils.isWeb) {
        for (final image in images) {
          final bytes = await downscaleForStorage(await image.readAsBytes());
          stored.add(await PhotoStore.instance.save(bytes));
        }
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        for (final image in images) {
          final fileName =
              'meal_${DateTime.now().millisecondsSinceEpoch}_${_capturedPhotos.length + stored.length}.jpg';
          final savedPath = '${appDir.path}/$fileName';
          await File(image.path).copy(savedPath);
          stored.add(savedPath);
        }
      }
      _capturedPhotos.addAll(stored);
      unawaited(_scanPickedPhotos(images, stored));
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
    if (PhotoStore.isRef(photoPath)) {
      await PhotoStore.instance.delete(photoPath);
      return;
    }
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
    if (removedPhoto == _photoBarcodeSource) _clearPhotoBarcode();
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
      if (!_isCameraInitialized ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        await _initCamera();
      }
    } else {
      await _persistPhotos();
    }
  }

  ImageProvider _photoImageProvider(String photo, {int? cacheWidth}) =>
      PhotoStore.instance.imageProvider(photo, cacheWidth: cacheWidth);

  /// The screen's width in device pixels: the most a full-width photo needs.
  int _screenPixelWidth() =>
      (MediaQuery.sizeOf(context).width *
              MediaQuery.devicePixelRatioOf(context))
          .round();

  Future<void> _openCapturedPhoto(int index) async {
    if (index < 0 || index >= _capturedPhotos.length) return;
    final photos = List<String>.from(_capturedPhotos);
    await showPhotoViewer(
      context,
      images: [for (final p in photos) _photoImageProvider(p)],
      initialIndex: index,
      heroTag: (i) => PhotoReviewView.heroTag(photos[i]),
      onSave: (i) => savePhotoToGallery(context, photos[i]),
      onDelete: (i) => _removeCapturedPhoto(_capturedPhotos.indexOf(photos[i])),
    );
  }

  /// Moves a photo in the review grid; the first one is the meal's cover.
  void _reorderCapturedPhoto(int from, int to) {
    setState(() => _capturedPhotos.insert(to, _capturedPhotos.removeAt(from)));
    unawaited(_persistPhotos());
  }

  Future<void> _analyzeMeal({
    String? mealContext,
    bool background = false,
  }) async {
    // Without a photo the description is the whole input.
    if (_capturedPhotos.isEmpty && (mealContext?.trim().isEmpty ?? true)) {
      return;
    }

    final l10n = context.l10n;
    if (_capturedPhotos.length > 5) {
      _showMessage(l10n.rateLimitPhotos);
      return;
    }

    final provider = context.read<AppProvider>();
    final isOnline = provider.isOnline;
    final apiKey = provider.apiKey;
    final language = provider.language;

    final mealId = DateTime.now().millisecondsSinceEpoch.toString();

    // Persist the job before foreground inference too. If the PWA is closed,
    // the next startup can reclaim and analyze it instead of losing the meal.
    // The claim keeps the queue from analyzing it in parallel meanwhile.
    if (!background && isOnline && apiKey.isNotEmpty) {
      OfflineQueueService.claim(mealId);
      await provider.saveMeal(
        MealModel(
          id: mealId,
          timestamp: DateTime.now(),
          photoPaths: List.from(_capturedPhotos),
          isPending: true,
          analysisStatus: 'queued',
          mealContext: mealContext,
        ),
      );
    }

    if (background || !isOnline || apiKey.isEmpty) {
      // Save as pending
      final meal = MealModel(
        id: mealId,
        timestamp: DateTime.now(),
        photoPaths: List.from(_capturedPhotos),
        isPending: true,
        mealContext: mealContext,
      );
      await provider.saveMeal(meal);

      setState(() {
        _capturedPhotos = [];
        _mealContext = null;
      });
      await _clearPersistedPhotos();

      if (mounted) {
        if (background) {
          _showMessage(l10n.mealSavedBackground, kind: AppToastKind.success);
          if (isOnline && apiKey.isNotEmpty) {
            provider.processOfflineQueue();
          }
        } else {
          final message = !isOnline
              ? l10n.offlineMessage
              : l10n.enterApiKeyError;
          _showMessage(message);
        }
      }
      return;
    }

    // The queued copy only guards against the app closing mid-analysis. Any
    // outcome other than logging the meal (back, discard, error, no food)
    // removes it, or the offline queue would analyze and log it later.
    try {
      await _runForegroundAnalysis(
        provider: provider,
        mealId: mealId,
        mealContext: mealContext,
        apiKey: apiKey,
        language: language,
      );
    } finally {
      await provider.discardPendingMeal(mealId);
      OfflineQueueService.release(mealId);
      if (mounted && _cameraTabIsActive) unawaited(_resumeCameraPreview());
    }
  }

  Future<void> _runForegroundAnalysis({
    required AppProvider provider,
    required String mealId,
    required String? mealContext,
    required String apiKey,
    required String language,
  }) async {
    final l10n = context.l10n;
    setState(() {
      _isAnalyzing = true;
      _analysisHeroImageProvider = _capturedPhotos.isNotEmpty
          ? _photoImageProvider(
              _capturedPhotos.first,
              cacheWidth: _screenPixelWidth(),
            )
          : null;
    });
    final accurate = provider.user?.useAccurateMode ?? true;
    _tracker.start(
      estimates: accurate ? GeminiService.ensembleSize : 1,
      hasPhoto: _capturedPhotos.isNotEmpty,
      description: mealContext,
    );
    provider.setMealAnalysisActive(true);
    // The analysis covers the whole screen; the live preview underneath
    // would only cost frames.
    unawaited(_pauseCameraPreview());

    Map<String, dynamic>? result;

    try {
      final gemini = GeminiService(apiKey: apiKey, language: language);
      final stream = gemini.analyzeMealStream(
        _capturedPhotos,
        useGrams: provider.user?.useGramsByDefault ?? false,
        mealContext: mealContext,
        useAccurateMode: accurate,
      );

      await for (final event in stream) {
        if (!mounted) break;
        if (event is AnalysisResult) {
          result = event.data;
        } else {
          _tracker.handle(event);
        }
      }
    } catch (e) {
      debugPrint('Analysis stream error: $e');
      if (mounted) {
        final errorMsg = analysisErrorMessage(l10n, e);
        setState(() {
          _isAnalyzing = false;
          _analysisHeroImageProvider = null;
        });
        provider.setMealAnalysisActive(false);
        _showMessage(errorMsg, kind: AppToastKind.error);
        return;
      }
    }

    if (result != null) {
      final noFood =
          result['error'] == 'no_food_detected' ||
          // A description with no food in it comes back as zero calories.
          (_capturedPhotos.isEmpty && _hasNoCalories(result));
      if (noFood) {
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
        // The number lands on the photo before the result opens.
        await _tracker.finish(result);
        final parsed = parseAnalysisResult(result);
        final mealWithPortion = MealModel(
          id: mealId,
          timestamp: DateTime.now(),
          photoPaths: List.from(_capturedPhotos),
          mealContext: mealContext,
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
          portionMultiplier: parsed.multiplier,
          portionUnit: parsed.unit,
          quantityPerUnit: parsed.quantityPerUnit,
          isPending: false,
        );

        if (mounted) {
          void endAnalysis() {
            if (!mounted || !_isAnalyzing) return;
            setState(() {
              _isAnalyzing = false;
              _analysisHeroImageProvider = null;
            });
            provider.setMealAnalysisActive(false);
          }

          // Keep the analysis screen underneath until the result fully covers
          // it; ending it earlier flashes the photo review screen.
          final route = MaterialPageRoute<void>(
            builder: (_) => MealDetailScreen(
              meal: mealWithPortion,
              isNewEntry: true,
              initialMealContext: mealContext,
            ),
          );
          final popped = Navigator.push(context, route);
          void onRouteShown(AnimationStatus status) {
            if (status != AnimationStatus.completed) return;
            route.animation?.removeStatusListener(onRouteShown);
            endAnalysis();
          }

          route.animation?.addStatusListener(onRouteShown);
          await popped;
          route.animation?.removeStatusListener(onRouteShown);
          endAnalysis();
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
          _showMessage(l10n.analysisFailed, kind: AppToastKind.error);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisHeroImageProvider = null;
        });
        provider.setMealAnalysisActive(false);
        _showMessage(l10n.analysisNoResult, kind: AppToastKind.error);
      }
    }
  }

  /// Non-blocking message; kept clear of the camera's top buttons and of the
  /// gallery, shutter and tab controls.
  void _showMessage(String message, {AppToastKind kind = AppToastKind.info}) {
    if (!mounted) return;
    AppToast.show(
      context,
      message,
      kind: kind,
      top: MediaQuery.paddingOf(context).top + 76,
    );
  }

  bool _hasNoCalories(Map<String, dynamic> result) {
    try {
      return parseAnalysisResult(result).calories <= 0;
    } catch (_) {
      return false; // the parsing below reports the real error
    }
  }

  Future<void> _resetCaptureState() async {
    setState(() {
      _capturedPhotos = [];
      _isTakingMore = false;
      _mealContext = null;
      _leaveLabelMode();
    });
    _clearPhotoBarcode();
    await _clearPersistedPhotos();
    if (!_isCameraInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      await _initCamera();
    }
  }

  Future<void> _clearPhotos() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.discardPhotos,
      message: l10n.discardPhotosConfirm,
      confirmLabel: l10n.discard,
      destructive: true,
    );

    if (confirmed) {
      for (final photo in List<String>.from(_capturedPhotos)) {
        await _deleteStoredPhotoIfDisposable(photo);
      }
      await _resetCaptureState();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // A sheet or screen on top stops scanning: it rebuilds this screen when
    // it opens and closes.
    _routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCameraPreview();
      _syncBarcodeScanner();
    });
    final provider = context.watch<AppProvider>();
    final isOnline = provider.isOnline;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildContent()),
          if (!isOnline)
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              left: 0,
              right: 0,
              child: const IgnorePointer(child: Center(child: OfflineBanner())),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (!_hasPermission) {
      return CameraPermissionRequest(onGrant: _initCamera);
    }

    return Stack(
      children: [
        Positioned.fill(child: _buildCamera()),
        if (_isAnalyzing)
          Positioned.fill(
            child: AnalyzingView(
              heroImage: _analysisHeroImageProvider,
              tracker: _tracker,
            ),
          )
        else if (_capturedPhotos.isEmpty && _showCameraHint)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 76,
            left: 16,
            right: 16,
            child: FirstUseCard(
              onDark: true,
              icon: Icons.photo_camera_outlined,
              title: context.l10n.hintCameraTitle,
              body: context.l10n.hintCameraBody,
              onDismiss: () {
                setState(() => _showCameraHint = false);
                FirstUseHints.markSeen(FirstUseHint.camera);
              },
            ),
          )
        else if (_capturedPhotos.isNotEmpty && !_isTakingMore)
          Positioned.fill(
            child: PhotoReviewView(
              photos: _capturedPhotos,
              isAnalyzing: _isAnalyzing,
              // Two photos side by side: half the screen is enough.
              imageFor: (photo) => _photoImageProvider(
                photo,
                cacheWidth: (_screenPixelWidth() / 2).round(),
              ),
              onOpen: _openCapturedPhoto,
              onRemove: _removeCapturedPhoto,
              onReorder: _reorderCapturedPhoto,
              onDiscard: _clearPhotos,
              onAddPhoto: _switchToCameraMode,
              onAnalyze: _showContextAndAnalyze,
            ),
          ),
      ],
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    final previewAspectRatio = portraitPreviewAspect(
      controller.value.aspectRatio,
    );

    return KeyedSubtree(
      key: ValueKey(_cameraPreviewKey),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _lastPreviewConstraints = constraints;
          return Listener(
            onPointerDown: _handlePreviewPointerDown,
            onPointerMove: _handlePreviewPointerMove,
            onPointerUp: _handlePreviewPointerUp,
            onPointerCancel: _handlePreviewPointerUp,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _focusAtPoint(details, constraints, controller),
              child: ClipRect(
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: PlatformUtils.isWeb
                          // The video element covers its box itself
                          // (object-fit: cover), whatever size the browser
                          // reports for the stream.
                          ? controller.buildPreview()
                          : FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height:
                                    constraints.maxWidth / previewAspectRatio,
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
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(34),
                            ),
                          ),
                        ),
                      ),
                    if (_showZoomIndicator && _canZoom)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 78,
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
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadius,
                                ),
                              ),
                              child: Text(
                                '${_currentZoomLevel.toStringAsFixed(1)}x',
                                style: TextStyle(
                                  color: Colors.white,
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

  /// Switches back to the still-running camera preview.
  Future<void> _switchToCameraMode() async {
    setState(() {
      _isTakingMore = true;
      _isCameraInitialized =
          _cameraController != null && _cameraController!.value.isInitialized;
    });
    if (!_isCameraInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      await _initCamera();
    }
  }

  /// Turns the torch off and goes back to the photo review.
  Future<void> _leaveCamera() async {
    if (_isTorchOn) {
      await _setTorchMode(false);
    }
    if (mounted) setState(() => _isTakingMore = false);
  }

  Widget _buildCamera() {
    final l10n = context.l10n;

    final bool canShowCamera =
        _isCameraInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;

    // While the camera switches, the controls stay where they are.
    final showControls = canShowCamera || _isSwitchingCamera;
    final veil = _veil;

    return Stack(
      children: [
        if (canShowCamera)
          Positioned.fill(child: _buildCameraPreview(_cameraController!))
        else
          // Black while the camera starts, as the system camera does, in
          // either theme.
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
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                ],
              ),
            ),
          ),

        if (veil != null)
          Positioned.fill(
            child: CameraSwitchVeil(
              key: ObjectKey(veil),
              snapshot: veil,
              mirrored: _veilMirrored,
              reveal: _veilReveal,
              onDone: () {
                if (mounted && identical(_veil, veil)) {
                  setState(() => _veil = null);
                }
              },
            ),
          ),

        if (showControls) CameraLogo(onTap: _onLogoTap),

        if (showControls)
          CameraSwitchButton(
            enabled: (_cameras?.length ?? 0) > 1 && !_isSwitchingCamera,
            onTap: _switchCamera,
          ),

        if (showControls)
          CameraTorchButton(
            available: _canUseTorch,
            isOn: _isTorchOn,
            onTap: _toggleTorch,
          ),

        // Meal Framing Guide & Info Text Overlay
        if (showControls &&
            !_isAnalyzing &&
            (_capturedPhotos.isEmpty || _isTakingMore))
          MealGuideOverlay(
            guideText: _labelMode
                ? l10n.barcodeLabelGuide
                : l10n.cameraGuideText,
            lock: _capturedPhotos.isEmpty ? _guideLock : null,
          ),

        if (_capturedPhotos.isNotEmpty)
          BackToSelectionButton(onTap: _leaveCamera),

        CameraBottomBar(
          photoCount: _capturedPhotos.length,
          lastPhoto: _capturedPhotos.isEmpty
              ? null
              : _photoImageProvider(_capturedPhotos.last, cacheWidth: 180),
          isCapturing: _isCapturing,
          onGallery: _pickFromGallery,
          onCapture: _capturePhoto,
          onReview: _leaveCamera,
          onQuickLog: _showQuickLog,
        ),
      ],
    );
  }

  bool get _shouldScanBarcodes {
    final controller = _cameraController;
    return mounted &&
        _routeIsCurrent &&
        _cameraTabIsActive &&
        _isCameraInitialized &&
        !_isPreviewPaused &&
        controller != null &&
        controller.value.isInitialized &&
        _capturedPhotos.isEmpty &&
        !_isAnalyzing;
  }

  /// Starts or stops the background barcode scanner to match the screen.
  /// Calls are serialized; repeating one is cheap.
  void _syncBarcodeScanner() {
    _barcodeSync = _barcodeSync
        .then((_) async {
          final controller = _cameraController;
          if (_shouldScanBarcodes && controller != null) {
            final view = _lastPreviewConstraints?.biggest;
            if (mounted && view != null && view.isFinite) {
              _barcodeScanner.setRegion(
                _guideRect(),
                view,
                mirrored: _frontCamera,
              );
            }
            if (identical(controller, _barcodeController)) return;
            await _barcodeScanner.start(controller, _onBarcode);
            _barcodeController = controller;
          } else if (_barcodeController != null) {
            _barcodeController = null;
            await _barcodeScanner.stop();
          }
        })
        .catchError((Object e) => debugPrint('Barcode scanner: $e'));
  }

  Future<void> _stopBarcodeScanner() {
    _barcodeSync = _barcodeSync
        .then((_) async {
          if (_barcodeController == null) return;
          _barcodeController = null;
          await _barcodeScanner.stop();
        })
        .catchError((Object e) => debugPrint('Barcode scanner: $e'));
    return _barcodeSync;
  }

  void _onBarcode(ScannedBarcode barcode) {
    if (!_shouldScanBarcodes || !_barcodeInGuide(barcode)) return;
    final code = barcode.code;
    // The box follows the code while its product is looked up.
    final lock = _guideLock;
    if (lock != null && lock.code == code && !lock.found) {
      setState(
        () => _guideLock = GuideLock(
          box: _lockBoxFor(barcode),
          title: lock.title,
          code: code,
        ),
      );
    }
    final format = barcode.format;
    final valid = format == 'UPCE'
        ? expandUpcE(code) != null
        : isValidGtin(code);
    if (!valid) return;
    final now = DateTime.now();
    if (now.isBefore(_barcodeQuietUntil)) return;
    // A code still in view is handled once; it counts again only after it
    // has been out of view for a moment.
    final stillInView =
        code == _lastBarcode &&
        now.difference(_lastBarcodeSeen) < const Duration(seconds: 3);
    _lastBarcode = code;
    _lastBarcodeSeen = now;
    if (stillInView || _barcodeBusy || code == _labelModeCode) return;
    // The lookup goes out first; drawing the lock must not hold it up.
    unawaited(_lookUpBarcode(code, format));
    setState(
      () => _guideLock = GuideLock(
        box: _lockBoxFor(barcode),
        title: context.l10n.barcodeLookingUp,
        code: code,
      ),
    );
  }

  bool get _frontCamera =>
      _cameraController?.description.lensDirection == CameraLensDirection.front;

  Rect? _guideRect() {
    final view = _lastPreviewConstraints?.biggest;
    if (view == null || !view.isFinite || view.isEmpty) return null;
    return MealGuideOverlay.guideRect(view, MediaQuery.paddingOf(context));
  }

  /// Only a code shown inside the guide frame counts, so a package in the
  /// background of a meal photo does not open its product.
  bool _barcodeInGuide(ScannedBarcode barcode) {
    final bounds = barcode.bounds;
    final view = _lastPreviewConstraints?.biggest;
    final guide = _guideRect();
    if (bounds == null || view == null || guide == null) return true;
    return codeInGuide(
      bounds: bounds,
      frameAspect: barcode.frameAspect,
      view: view,
      guide: guide,
      mirrored: _frontCamera,
    );
  }

  /// Where the guide's corners close around [barcode].
  Rect _lockBoxFor(ScannedBarcode barcode) {
    final guide = _guideRect() ?? Rect.zero;
    final bounds = barcode.bounds;
    final view = _lastPreviewConstraints?.biggest;
    final onScreen = bounds == null || view == null
        ? null
        : codeOnScreen(
            bounds: bounds,
            frameAspect: barcode.frameAspect,
            view: view,
            mirrored: _frontCamera,
          );
    if (onScreen == null) {
      return Rect.fromCenter(
        center: guide.center,
        width: guide.width * 0.7,
        height: guide.height * 0.45,
      );
    }
    return lockBox(onScreen, guide);
  }

  Future<void> _lookUpBarcode(String code, String format) async {
    _barcodeBusy = true;
    Haptics.tick();
    // The picture the code was read in becomes the meal photo; it is made
    // while the product is looked up.
    final frame = _barcodeScanner.takeFrame();
    final l10n = context.l10n;
    final language = context.read<AppProvider>().language;
    var opened = false;
    try {
      final result = await _productLookup.lookup(
        code,
        format: format,
        language: language,
      );
      // A photo taken or the tab left meanwhile wins over the lookup.
      if (!mounted || !_cameraTabIsActive || _capturedPhotos.isNotEmpty) {
        AppToast.dismiss();
        return;
      }
      final product = result.product;
      switch (result.status) {
        case ProductLookupStatus.found:
          AppToast.dismiss();
          opened = true;
          final lock = _guideLock;
          if (lock != null) {
            setState(
              () => _guideLock = GuideLock(
                box: lock.box,
                title: product!.displayName,
                code: code,
                found: true,
              ),
            );
          }
          await _openProduct(product!, code, frame, l10n);
        case ProductLookupStatus.noNutrition:
          _offerLabelPhoto(
            l10n.barcodeNoNutrition(product!.displayName),
            code,
            product.displayName,
          );
        case ProductLookupStatus.notFound:
          _offerLabelPhoto(l10n.barcodeNotFound, code, null);
        case ProductLookupStatus.failed:
          _offerLabelPhoto(l10n.barcodeLookupFailed, code, null);
      }
    } finally {
      if (mounted) setState(() => _guideLock = null);
      if (opened) {
        // Back from the product without saving it: the same code, still in
        // front of the camera, opens it again after a short pause instead of
        // only once it has left the view.
        _lastBarcode = null;
        _barcodeQuietUntil = DateTime.now().add(const Duration(seconds: 1));
      } else {
        // The code is probably still in front of the camera.
        _lastBarcode = code;
        _lastBarcodeSeen = DateTime.now();
      }
      _barcodeBusy = false;
    }
  }

  Future<void> _openProduct(
    FoodProduct product,
    String code,
    Future<Uint8List?> frame,
    AppLocalizations l10n,
  ) async {
    final provider = context.read<AppProvider>();
    final now = DateTime.now();
    final photo = await _storeBarcodeFrame(frame);
    if (!mounted) {
      if (photo != null) await _deleteStoredPhotoIfDisposable(photo);
      return;
    }
    final meal = product.toMeal(
      id: now.millisecondsSinceEpoch.toString(),
      timestamp: now,
      note: l10n.barcodeSourceNote(code),
      photoPaths: [?photo],
    );
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MealDetailScreen(meal: meal, isNewEntry: true),
      ),
    );
    // Discarded: the photo belongs to nothing.
    if (photo != null && provider.getMealById(meal.id) == null) {
      await _deleteStoredPhotoIfDisposable(photo);
    }
  }

  /// Stores the picture a barcode was read in like a captured photo; null
  /// when there is none.
  Future<String?> _storeBarcodeFrame(Future<Uint8List?> frame) async {
    try {
      final bytes = await frame;
      if (bytes == null || bytes.isEmpty) return null;
      if (PlatformUtils.isWeb) return await PhotoStore.instance.save(bytes);
      final appDir = await getApplicationDocumentsDirectory();
      final path =
          '${appDir.path}/meal_${DateTime.now().millisecondsSinceEpoch}_barcode.jpg';
      await File(path).writeAsBytes(bytes, flush: true);
      return path;
    } catch (e) {
      debugPrint('Barcode photo not stored: $e');
      return null;
    }
  }

  void _offerLabelPhoto(String message, String code, String? productName) {
    final l10n = context.l10n;
    AppToast.show(
      context,
      message,
      kind: AppToastKind.info,
      top: MediaQuery.paddingOf(context).top + 76,
      actionLabel: l10n.barcodeLabelAction,
      onAction: () {
        if (!mounted) return;
        Haptics.tick();
        setState(() {
          _labelMode = true;
          _labelModeCode = code;
          _mealContext = l10n.barcodeLabelContext(productName ?? 'EAN $code');
        });
      },
    );
  }

  /// Reads the picked photos for a barcode, in order, until one names a
  /// product with nutrition values. Runs while the photos are reviewed.
  Future<void> _scanPickedPhotos(
    List<XFile> images,
    List<String> stored,
  ) async {
    if (_photoBarcode.value != null) return;
    final generation = _photoScanGeneration;
    final language = context.read<AppProvider>().language;
    bool stale() => !mounted || generation != _photoScanGeneration;
    for (var i = 0; i < images.length && i < stored.length; i++) {
      final barcode = await _barcodeScanner.decodeImage(images[i]);
      if (stale()) return;
      if (barcode == null) continue;
      final valid = barcode.format == 'UPCE'
          ? expandUpcE(barcode.code) != null
          : isValidGtin(barcode.code);
      if (!valid) continue;
      final result = await _productLookup.lookup(
        barcode.code,
        format: barcode.format,
        language: language,
      );
      if (stale() || _photoBarcode.value != null) return;
      if (result.status == ProductLookupStatus.found &&
          _capturedPhotos.contains(stored[i])) {
        _photoBarcodeSource = stored[i];
        _photoBarcode.value = result.product;
        return;
      }
    }
  }

  void _clearPhotoBarcode() {
    _photoScanGeneration++;
    _photoBarcodeSource = null;
    _photoBarcode.value = null;
  }

  /// Logs the product found in the picked photos, with all of them attached.
  /// Discarding it returns to the photos.
  Future<void> _openPhotoProduct(FoodProduct product) async {
    final provider = context.read<AppProvider>();
    final now = DateTime.now();
    final meal = product.toMeal(
      id: now.millisecondsSinceEpoch.toString(),
      timestamp: now,
      note: context.l10n.barcodeSourceNote(product.code),
      // The photo with the code shows the product; it comes first.
      photoPaths: [
        ?_photoBarcodeSource,
        ..._capturedPhotos.where((photo) => photo != _photoBarcodeSource),
      ],
    );
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MealDetailScreen(meal: meal, isNewEntry: true),
      ),
    );
    if (mounted && provider.getMealById(meal.id) != null) {
      await _resetCaptureState();
    }
  }

  void _leaveLabelMode() {
    _labelMode = false;
    _labelModeCode = null;
  }

  /// Logs a meal without a photo: from a description, or again from the list
  /// of meals eaten before.
  Future<void> _showQuickLog() async {
    final provider = context.read<AppProvider>();
    final result = await showQuickLogSheet(
      context,
      recent: provider.recentDistinctMeals(),
    );
    if (result == null || !mounted) return;
    switch (result) {
      case QuickLogRepeat(:final meal):
        await _logAgain(meal);
      case QuickLogDescribe(:final text):
        await _analyzeMeal(mealContext: text);
    }
  }

  Future<void> _logAgain(MealModel source) async {
    final provider = context.read<AppProvider>();
    final l10n = context.l10n;
    try {
      final copy = await provider.repeatMeal(source);
      if (!mounted) return;
      AppToast.show(
        context,
        l10n.quickLogLogged(copy.mealName),
        kind: AppToastKind.success,
        top: MediaQuery.paddingOf(context).top + 76,
        actionLabel: l10n.quickLogUndo,
        onAction: () => provider.deleteMeal(copy.id),
      );
    } catch (e) {
      _showMessage(errorMessage(context.l10n, e), kind: AppToastKind.error);
    }
  }

  Future<void> _showContextAndAnalyze() async {
    final result = await showMealContextSheet(
      context,
      initialText: _mealContext,
      barcode: _photoBarcode,
    );

    final product = _photoBarcode.value;
    if (result != null && result.useBarcode && product != null && mounted) {
      await _openPhotoProduct(product);
      return;
    }

    // Only analyze if user explicitly tapped one of the analyze buttons
    if (result != null && mounted) {
      setState(() => _mealContext = result.context);
      await _analyzeMeal(
        mealContext: result.context,
        background: result.background,
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}
