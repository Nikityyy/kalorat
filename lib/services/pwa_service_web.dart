import 'dart:async';
import 'dart:js_interop';

import '../utils/app_logger.dart';
import 'pwa_service.dart';

@JS('window')
external JSObject get _window;

@JS('skipWaitingAndReload')
external void _skipWaitingAndReload();

extension type WindowExtension(JSObject _) implements JSObject {
  @JS('addEventListener')
  external void addEventListener(String type, JSFunction callback);

  @JS('location.reload')
  external void reload();
}

class WebPwaService implements PwaService {
  final _updateAvailableController = StreamController<bool>.broadcast();

  @override
  Stream<bool> get updateAvailableStream => _updateAvailableController.stream;

  bool _updateAvailable = false;
  @override
  bool get updateAvailable => _updateAvailable;

  @override
  void init() {
    final window = _window as WindowExtension;

    // Listen for the custom event dispatched from index.html
    window.addEventListener(
      'flutter-pwa-update-available',
      ((JSObject event) {
        AppLogger.info('PwaService', 'Update available event received');
        _updateAvailable = true;
        _updateAvailableController.add(true);
      }).toJS,
    );

    AppLogger.info('PwaService', 'Web PwaService initialized');
  }

  @override
  void performUpdate() {
    AppLogger.info('PwaService', 'Performing update (skipWaiting and reload)');

    try {
      _skipWaitingAndReload();
    } catch (e) {
      AppLogger.warning(
        'PwaService',
        'skipWaitingAndReload not found, falling back to reload',
      );
      (_window as WindowExtension).reload();
    }
  }

  @override
  void dispose() {
    _updateAvailableController.close();
  }
}

PwaService createService() => WebPwaService();
