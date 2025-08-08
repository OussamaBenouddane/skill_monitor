import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/view/home.dart';
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:skill_monitor/services/notification_service.dart';
import 'controllers/theme_controller.dart';
import 'controllers/composite_controller.dart';
import 'services/sharedpref_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_init.initializeTimeZones();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Skill Monitor',
      debugShowCheckedModeBanner: false,
      home: InitializationScreen(),
      theme: ThemeData.light().copyWith(
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Poppins'),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Poppins'),
      ),
      themeMode: ThemeMode.system,
    );
  }
}

class InitializationScreen extends StatefulWidget {
  @override
  _InitializationScreenState createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize SharedPreferences service first
      await Get.putAsync(() => SharedPrefsService().init());

      // Initialize and register notification service
      final notificationService = NotificationService();
      await notificationService.initialize();
      Get.put(notificationService);

      // Initialize other services
      Get.put(ThemeController());

      // Initialize the main controller and load data
      final compositeController = Get.put(CompositeController());
      await compositeController.loadSkillsWithHabits();

      // Add lifecycle observer for app state changes
      WidgetsBinding.instance.addObserver(_AppLifecycleObserver());

      // Navigate to home screen
      Get.off(() => HomeScreen());
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Show error dialog or navigate to error screen
      _showInitializationError(e.toString());
    }
  }

  void _showInitializationError(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text('Failed to initialize the app: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry initialization
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only refresh if notifications are running low (prevents double scheduling)
      if (Get.isRegistered<NotificationService>()) {
        Get.find<NotificationService>().refreshNotificationsIfNeeded();
      }
    }
  }
}