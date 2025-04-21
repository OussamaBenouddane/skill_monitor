import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/app.dart';
import 'package:skill_monitor/theme_controller.dart';

void main() {
  Get.put(ThemeController());
  runApp(const MyApp());
}
