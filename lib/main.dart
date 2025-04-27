import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/app.dart';
import 'package:skill_monitor/services/notification_service.dart';
import 'package:skill_monitor/theme_controller.dart';
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final NotificationService notificationService = NotificationService();
    await notificationService.initialize();

    final now = DateTime.now();
    if (now.hour == 20) { // If it's 8:00 PM
      await notificationService.showInstantNotification(); // ⚡ show NEW random message
    }
    return Future.value(true);
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // set false in release
  );

  // Register periodic task
  await Workmanager().registerPeriodicTask(
    "daily_notification_task",
    "daily_notification_task",
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(minutes: 1),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );

  // your existing GetX + NotificationService initialization
  Get.put(ThemeController());

  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  Get.put(notificationService);

  runApp(const MyApp());
}
