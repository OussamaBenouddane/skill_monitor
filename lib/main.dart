import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:skill_monitor/view/home.dart';
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:skill_monitor/services/notification_service.dart';
import 'package:skill_monitor/services/notification_handler.dart';
import 'bindings/initial_bindings.dart';
import 'controllers/theme_controller.dart';
import 'controllers/composite_controller.dart';
import 'services/backgound_task_manager.dart';
import 'services/sharedpref_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_init.initializeTimeZones();

  // Initialize SharedPreferences service first
  await Get.putAsync(() => SharedPrefsService().init());

  // Temporary instantiation before binding to handle async setup
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  final backgroundTaskManager = BackgroundTaskManager(notificationService);
  await backgroundTaskManager.initialize();
  await backgroundTaskManager.ensureLastCheckTimeInitialized();

  // Store these so InitialBinding doesn't re-create them
  Get.put(notificationService);
  Get.put(backgroundTaskManager);
  Get.put(ThemeController());

  // Initialize the main controller
  final compositeController = Get.put(CompositeController());

  // Check if launched from notification
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final launchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
    final response = launchDetails.notificationResponse;
    if (response != null && response.payload == 'background_check') {
      await backgroundTaskManager.performBackgroundCheck();
    }
  }

  flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      // android: AndroidInitializationSettings('@mipmap/ic_launcher'), // Use default Flutter icon
      // iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: handleBackgroundNotification,
  );

  // Lifecycle observer
  final lifecycleObserver = AppLifecycleObserver(
    notificationService,
    backgroundTaskManager,
  );
  WidgetsBinding.instance.addObserver(lifecycleObserver);

  // Load initial data
  await compositeController.loadSkillsWithHabits();

  runApp(
    GetMaterialApp(
      title: 'Skill Monitor',

      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      home: HomeScreen(),
      theme: ThemeData.light().copyWith(
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Poppins'),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Poppins'),
      ),
      themeMode: Get.find<ThemeController>().themeMode,
    ),
  );
}
