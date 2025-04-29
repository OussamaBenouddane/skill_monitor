import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/app.dart';
import 'package:skill_monitor/services/notification_service.dart';
import 'package:skill_monitor/theme_controller.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:timezone/timezone.dart';

// This class replaces Workmanager functionality with a periodic check system
class BackgroundTaskManager {
  static const String _lastBackgroundCheckKey = 'last_background_check';
  static const Duration _backgroundCheckInterval = Duration(minutes: 15);
  
  final NotificationService notificationService;
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  
  BackgroundTaskManager(this.notificationService) 
      : notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    // Set up background check notification
    await _setupBackgroundNotification();
    
    // Perform initial check
    await performBackgroundCheck();
  }
  
  Future<void> _setupBackgroundNotification() async {
    // Schedule a silent notification to trigger the background check
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentSound: false, presentBadge: false, presentAlert: false),
    );
    
    // Schedule for the next interval
    await notificationsPlugin.zonedSchedule(
      999, // Use a unique ID for this notification
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
      // Check and reschedule daily notification if needed
      await notificationService.checkAndRescheduleNotification();
      
      // Update last check time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackgroundCheckKey, DateTime.now().millisecondsSinceEpoch);
      
      // Schedule next background check
      await _setupBackgroundNotification();
      
      debugPrint('Background check completed successfully');
    } catch (e) {
      debugPrint('Background check failed: $e');
    }
  }
  
  // Calculate the next check time
  TZDateTime _nextCheckTime() {
    final now = TZDateTime.now(local);
    return now.add(_backgroundCheckInterval);
  }
  
  // Ensure we have a record of the last check time
  Future<void> ensureLastCheckTimeInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_lastBackgroundCheckKey)) {
      await prefs.setInt(_lastBackgroundCheckKey, DateTime.now().millisecondsSinceEpoch);
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
      // When app is resumed, check if we need to schedule a new notification
      notificationService.checkAndRescheduleNotification();
    } else if (state == AppLifecycleState.paused) {
      // When app is paused, ensure the background check is scheduled
      backgroundTaskManager._setupBackgroundNotification();
    }
  }
}

Future<void> handleBackgroundNotification(NotificationResponse response) async {
  if (response.payload == 'background_check') {
    debugPrint('Handling background check notification response');
    
    // Get the notification service from GetX
    if (Get.isRegistered<NotificationService>() && Get.isRegistered<BackgroundTaskManager>()) {
      final backgroundTaskManager = Get.find<BackgroundTaskManager>();
      await backgroundTaskManager.performBackgroundCheck();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data (already done in NotificationService but ensuring it's called)
  tz_init.initializeTimeZones();

  // Initialize GetX controllers
  Get.put(ThemeController());

  // Initialize notification service
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  Get.put(notificationService);
  
  // Initialize background task manager (our Workmanager replacement)
  final BackgroundTaskManager backgroundTaskManager = BackgroundTaskManager(notificationService);
  await backgroundTaskManager.initialize();
  await backgroundTaskManager.ensureLastCheckTimeInitialized();
  Get.put(backgroundTaskManager);
  
  // Set up notification handling for when app is launched from notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Check if app was launched from notification
  final NotificationAppLaunchDetails? launchDetails = 
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  
  if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
    final NotificationResponse? response = launchDetails.notificationResponse;
    if (response != null && response.payload == 'background_check') {
      await backgroundTaskManager.performBackgroundCheck();
    }
  }
  
  // Setup notification callback
  flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: handleBackgroundNotification,
  );
  
  // Register app lifecycle observer
  final lifecycleObserver = AppLifecycleObserver(notificationService, backgroundTaskManager);
  WidgetsBinding.instance.addObserver(lifecycleObserver);

  runApp(const MyApp());
}