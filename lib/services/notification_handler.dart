import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/services/notification_service.dart';

import 'backgound_task_manager.dart';

Future<void> handleBackgroundNotification(NotificationResponse response) async {
  if (response.payload == 'background_check') {
    debugPrint('Handling background check notification response');

    if (Get.isRegistered<NotificationService>() &&
        Get.isRegistered<BackgroundTaskManager>()) {
      final backgroundTaskManager = Get.find<BackgroundTaskManager>();
      await backgroundTaskManager.performBackgroundCheck();
    }
  }
}
