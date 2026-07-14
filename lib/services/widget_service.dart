import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

class WidgetService {
  static const String androidWidgetName = 'KaloratWidgetProvider';
  static const String androidMediumWidgetName = 'KaloratWidgetMediumProvider';
  static const String iosWidgetName = 'KaloratWidget'; // This needs to match the iOS Widget class name
  static const String appGroupId = 'group.com.hope.kalorat'; // Important for iOS! Must match the App Group created in Xcode.

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('Error initializing home_widget: $e');
    }
  }

  static Future<void> updateWidgetData({
    required int streak,
    required bool isTrackedToday,
    required String weekHistoryJson, // JSON list of bools for the last 7 days [true, false, true...]
  }) async {
    try {
      // Save data to the native Key-Value store
      await HomeWidget.saveWidgetData<int>('streak_count', streak);
      await HomeWidget.saveWidgetData<bool>('is_tracked_today', isTrackedToday);
      await HomeWidget.saveWidgetData<String>('week_history', weekHistoryJson);

      // Trigger widget update for small
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iosWidgetName,
      );
      
      // Trigger widget update for medium
      await HomeWidget.updateWidget(
        name: androidMediumWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}
