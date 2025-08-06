import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart';
import 'package:skill_monitor/services/notification_service.dart';

class BackgroundTaskManager {
  static const String _lastBackgroundCheckKey = 'last_background_check';
  static const Duration _backgroundCheckInterval = Duration(minutes: 15);

  final NotificationService notificationService;
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  BackgroundTaskManager(this.notificationService)
    : notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _setupBackgroundNotification();
    await performBackgroundCheck();
  }

  Future<void> _setupBackgroundNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'background_task_channel',
      'Background Tasks',
      channelDescription: 'Silent notifications for background tasks',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      showWhen: false,
      onlyAlertOnce: true,
      visibility: NotificationVisibility.secret,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: false,
        presentBadge: false,
        presentAlert: false,
      ),
    );

    await notificationsPlugin.zonedSchedule(
      999,
      '',
      '',
      _nextCheckTime(),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'background_check',
    );

    debugPrint('Scheduled next background check notification');
  }

  Future<void> performBackgroundCheck() async {
    debugPrint('Performing background notification check');
    try {
      await notificationService.checkAndRescheduleNotification();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastBackgroundCheckKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await _setupBackgroundNotification();
      debugPrint('Background check completed successfully');
    } catch (e) {
      debugPrint('Background check failed: $e');
    }
  }

  TZDateTime _nextCheckTime() {
    final now = TZDateTime.now(local);
    return now.add(_backgroundCheckInterval);
  }

  Future<void> ensureLastCheckTimeInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_lastBackgroundCheckKey)) {
      await prefs.setInt(
        _lastBackgroundCheckKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }
}

class AppLifecycleObserver extends WidgetsBindingObserver {
  final NotificationService notificationService;
  final BackgroundTaskManager backgroundTaskManager;

  AppLifecycleObserver(this.notificationService, this.backgroundTaskManager);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      notificationService.checkAndRescheduleNotification();
    } else if (state == AppLifecycleState.paused) {
      backgroundTaskManager._setupBackgroundNotification();
    }
  }
}
