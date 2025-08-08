import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final List<String> _motivationalMessages = [
    "Let's check out what progress today brought!",
    "Even if today didn't feel the best, progress surely was made!",
    "Remember: small steps lead to big results over time.",
    "Time to celebrate your daily wins!",
    "Your skills are growing stronger every day!",
    "Progress isn't always visible - but it's happening!",
    "Ready to level up your skills today?",
    "Each habit checked is a step toward mastery.",
    "Growth comes from consistency, not perfection.",
    "Showing up is half the battle - you've got this!",
    "Habits compound over time - your future self will thank you!",
    "Track your progress, celebrate your journey.",
    "What skill will you level up today?",
    "Your skills are your superpowers in development.",
    "Every day is a chance to gain XP in real life!",
  ];

  bool _isInitialized = false;
  static const int _notificationHour = 16; // 4 PM
  static const int _scheduleDays = 30; // Schedule for 30 days

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('NotificationService already initialized');
      return;
    }

    try {
      tz_init.initializeTimeZones();

      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/notif_icon');

      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: androidInitializationSettings,
            iOS: iosInitializationSettings,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      await _requestPermissions();
      await _scheduleDailyNotifications();
      
      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
    }
    
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  String _getRandomMessage() {
    final random = Random();
    return _motivationalMessages[random.nextInt(_motivationalMessages.length)];
  }

  Future<void> _scheduleDailyNotifications() async {
    // Cancel existing notifications first
    await _flutterLocalNotificationsPlugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    
    // Calculate the first notification time
    tz.TZDateTime firstNotification = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _notificationHour,
      0,
    );

    // If it's already past notification time today, start from tomorrow
    if (firstNotification.isBefore(now)) {
      firstNotification = firstNotification.add(const Duration(days: 1));
    }

    // Schedule notifications for the next 30 days
    for (int i = 0; i < _scheduleDays; i++) {
      final notificationTime = firstNotification.add(Duration(days: i));
      final randomMessage = _getRandomMessage();
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        i, // Unique ID for each notification
        'Skill Monitor',
        randomMessage,
        notificationTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'skill_monitor_daily',
            'Daily Reminders',
            channelDescription: 'Daily notification to check your skill progress',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'daily_notification',
      );

      debugPrint('Scheduled notification ${i + 1} for: $notificationTime');
    }

    debugPrint('Successfully scheduled $_scheduleDays daily notifications starting at $_notificationHour:00');
  }

  Future<void> showTestNotification() async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }

    final message = _getRandomMessage();

    await _flutterLocalNotificationsPlugin.show(
      999, // High ID for test notifications
      'Skill Monitor - Test',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'skill_monitor_test',
          'Test Notifications',
          channelDescription: 'Test notification channel',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_notification',
    );

    debugPrint('Test notification shown: $message');
  }

  // Only reschedule if notifications are getting low (optional optimization)
  Future<void> refreshNotificationsIfNeeded() async {
    if (!_isInitialized) return;

    final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    
    // If we have less than 7 days of notifications left, reschedule
    if (pendingNotifications.length < 7) {
      await _scheduleDailyNotifications();
      debugPrint('Refreshed notifications - ${pendingNotifications.length} were remaining');
    } else {
      debugPrint('Notifications still healthy - ${pendingNotifications.length} pending');
    }
  }

  // Method to check how many notifications are pending (for debugging)
  Future<int> getPendingNotificationCount() async {
    final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pending.length;
  }
}