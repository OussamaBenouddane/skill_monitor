import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart'; // 👈 ADD THIS

class NotificationService {
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

  Future<void> initialize() async {
    tz_init.initializeTimeZones();
    
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasScheduledNotification = prefs.getBool('hasScheduledNotification') ?? false;
    
    if (!hasScheduledNotification) {
      await scheduleDailyNotification();
      await prefs.setBool('hasScheduledNotification', true);
    }
  }

  String _getRandomMessage() {
    final random = Random();
    return _motivationalMessages[random.nextInt(_motivationalMessages.length)];
  }

  /// ⏰ FIX: Now schedules a *fresh* notification daily
  Future<void> scheduleDailyNotification() async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Skill Monitor',
      _getRandomMessage(), // A random message on scheduling day
      _nextInstanceOf(TimeOfDay(hour: 20, minute: 0)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'skill_monitor_daily',
          'Daily Reminders',
          channelDescription: 'Daily notification to check your skill progress',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Match *time* every day
      payload: 'daily_notification',
      // 💡 Important to allow repeating on same time everyday
    );
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay timeOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// 🛡️ Proper Android 13+ notification permission request
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// 🖐 Button-triggered immediate notification
  Future<void> showInstantNotification() async {
    await _flutterLocalNotificationsPlugin.show(
      1,
      'Skill Monitor (Instant Test)',
      _getRandomMessage(), // 👈 New random message
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'skill_monitor_instant',
          'Instant Notifications',
          channelDescription: 'Test notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'instant_notification',
    );
  }

  Future<void> scheduleTodayNotification() async {
  await _flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Skill Monitor',
    _getRandomMessage(),
    _nextInstanceOf(const TimeOfDay(hour: 20, minute: 0)),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'skill_monitor_daily',
        'Daily Reminders',
        channelDescription: 'Daily notification to check your skill progress',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
    payload: 'daily_notification',
  );
}

}
