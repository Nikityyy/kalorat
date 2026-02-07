import '../utils/platform_utils.dart';
import 'dart:ui' as ui;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../l10n/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int mealReminderId = 1;
  static const int weightReminderId = 2;

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: initSettings);
  }

  Future<bool> requestPermissions() async {
    if (PlatformUtils.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    } else if (PlatformUtils.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  Future<void> scheduleMealReminders({
    required bool enabled,
    required String language,
  }) async {
    await _notifications.cancel(id: mealReminderId);
    await _notifications.cancel(id: mealReminderId + 10);
    await _notifications.cancel(id: mealReminderId + 20);

    if (!enabled) return;

    final l10n = lookupAppLocalizations(ui.Locale(language));

    // Schedule for breakfast (8:00), lunch (12:00), dinner (18:00)
    final times = [8, 12, 18];
    for (int i = 0; i < times.length; i++) {
      await _scheduleDailyNotification(
        id: mealReminderId + (i * 10),
        title: l10n.mealReminderTitle,
        body: l10n.mealReminderBody,
        hour: times[i],
      );
    }
  }

  Future<void> scheduleWeightReminder({
    required bool enabled,
    required String language,
  }) async {
    await _notifications.cancel(id: weightReminderId);

    if (!enabled) return;

    final l10n = lookupAppLocalizations(ui.Locale(language));

    await _scheduleDailyNotification(
      id: weightReminderId,
      title: l10n.logYourWeight,
      body: l10n.weightReminderBody,
      hour: 7, // Morning reminder
    );
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'kalorat_reminders',
      'Kalorat Reminders',
      channelDescription: 'Reminders for logging meals and weight',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
