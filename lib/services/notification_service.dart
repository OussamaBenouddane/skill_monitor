import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

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

    // Cancel any existing notifications first to avoid duplicates
    await _flutterLocalNotificationsPlugin.cancelAll();

    // Check the last time we set up notifications
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastScheduledDate = prefs.getString('lastScheduledDate');
    String todayDate = _getCurrentDate();

    // If no notification has been scheduled today, schedule one
    if (lastScheduledDate != todayDate) {
      await scheduleDailyNotification();
      await prefs.setString('lastScheduledDate', todayDate);
      debugPrint('Scheduled new notification for today: $todayDate');
    } else {
      debugPrint('Notification already scheduled for today: $todayDate');
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _getRandomMessage() {
    final random = Random();
    String message =
        _motivationalMessages[random.nextInt(_motivationalMessages.length)];

    // Store this message for today
    _saveMessageForToday(message);

    return message;
  }

  Future<void> _saveMessageForToday(String message) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('todayMessage', message);
    await prefs.setString('messageDate', _getCurrentDate());
  }

  Future<String> _getTodayMessage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String messageDate = prefs.getString('messageDate') ?? '';

    // If message is from today, use it, otherwise get a new one
    if (messageDate == _getCurrentDate()) {
      String savedMessage = prefs.getString('todayMessage') ?? '';
      if (savedMessage.isNotEmpty) {
        return savedMessage;
      }
    }

    return _getRandomMessage();
  }

  Future<void> scheduleDailyNotification() async {
    // Get a fresh message for today
    String message = await _getTodayMessage();

    // Cancel any previous notifications to avoid duplicates
    await _flutterLocalNotificationsPlugin.cancelAll();

    // Schedule for today at 8 PM
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Skill Monitor',
      message,
      _nextInstanceOf(const TimeOfDay(hour: 15, minute: 0)),
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

    debugPrint('Scheduled notification with message: $message');
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

    // If it's already past the time today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    debugPrint('Next notification scheduled for: $scheduledDate');
    return scheduledDate;
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    }
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showInstantNotification() async {
    String message = await _getTodayMessage();

    await _flutterLocalNotificationsPlugin.show(
      1,
      'Skill Monitor',
      message,
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

    debugPrint('Showing instant notification with message: $message');
  }

  // Check and reschedule notification if needed
  Future<void> checkAndRescheduleNotification() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String lastScheduledDate = prefs.getString('lastScheduledDate') ?? '';
    String todayDate = _getCurrentDate();

    // If we haven't scheduled a notification today, do it now
    if (lastScheduledDate != todayDate) {
      await scheduleDailyNotification();
      await prefs.setString('lastScheduledDate', todayDate);
      debugPrint('Rescheduled notification for new day: $todayDate');
    }
  }
}
