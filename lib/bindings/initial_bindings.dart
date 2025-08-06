import 'package:get/get.dart';
import 'package:skill_monitor/controllers/composite_controller.dart';
import 'package:skill_monitor/services/notification_service.dart';

import '../controllers/theme_controller.dart';
import '../services/backgound_task_manager.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Theme controller
    Get.put(ThemeController());

    // Notification service
    final notificationService = NotificationService();
    Get.put(notificationService);

    // Background task manager
    final backgroundTaskManager = BackgroundTaskManager(notificationService);
    Get.put(backgroundTaskManager);

    // Composite controller
    Get.put(CompositeController());
  }
}
