import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skill_monitor/theme_controller.dart';
import 'package:skill_monitor/utils/constants/colors.dart';
import 'package:skill_monitor/utils/constants/sizes.dart';

class CustomAppbar extends StatelessWidget {
  const CustomAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: TColors.darkbg),
      padding: const EdgeInsets.only(
          left: 16, right: 16, top: TSizes.appBarHeight / 2 + 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text("Welcome back",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Colors.white)),
          ),
          GestureDetector(
            onTap: Get.find<ThemeController>().toggleTheme,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TColors.purple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Get.find<ThemeController>().isDarkMode.value
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
