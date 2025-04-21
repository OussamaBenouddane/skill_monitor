import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/features/screens/add_skill.dart';
import 'package:skill_monitor/features/screens/home.dart';
import 'package:skill_monitor/theme_controller.dart';
import 'package:skill_monitor/utils/theme/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();

    return Obx(() => GetMaterialApp(
          themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routes: {
            '/add_skill': (context) => SkillSetupScreen(),
          },
          home: const Home(),
          debugShowCheckedModeBanner: false,
        ));
  }
}
