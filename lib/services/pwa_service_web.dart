import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import '../utils/app_logger.dart';
import 'pwa_service.dart';

class WebPwaService implements PwaService {
  final _updateAvailableController = StreamController<bool>.broadcast();

  @override
  Stream<bool> get updateAvailableStream => _updateAvailableController.stream;

  bool _updateAvailable = false;
  @override
  bool get updateAvailable => _updateAvailable;

  @override
  void init() {
    // Listen for the custom event dispatched from index.html
    html.window.addEventListener('flutter-pwa-update-available', (event) {
      AppLogger.info('PwaService', 'Update available event received');
      _updateAvailable = true;
      _updateAvailableController.add(true);
    });

    AppLogger.info('PwaService', 'Web PwaService initialized');
  }

  @override
  void performUpdate() {
    AppLogger.info('PwaService', 'Performing update (skipWaiting and reload)');
    // Call the JavaScript function defined in index.html
    if (js.context.hasProperty('skipWaitingAndReload')) {
      js.context.callMethod('skipWaitingAndReload');
    } else {
      // Fallback: just reload
      html.window.location.reload();
    }
  }

  @override
  void dispose() {
    _updateAvailableController.close();
  }
}

PwaService createService() => WebPwaService();
