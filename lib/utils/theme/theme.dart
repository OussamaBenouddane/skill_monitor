import 'package:flutter/material.dart';
import 'package:skill_monitor/utils/constants/colors.dart';
import 'package:skill_monitor/utils/theme/custom_themes/appbar_theme.dart';
import 'package:skill_monitor/utils/theme/custom_themes/bottom_sheet_theme.dart';
import 'package:skill_monitor/utils/theme/custom_themes/checkbox_theme.dart';
import 'package:skill_monitor/utils/theme/custom_themes/chip_theme.dart';
import 'package:skill_monitor/utils/theme/custom_themes/elevated_button_theme.dart';
import 'package:skill_monitor/utils/theme/custom_themes/outlined_button_theme.dart';
import 'package:skill_monitor/utils/theme/custom_themes/text_field_theme.dart';
import 'package:skill_monitor/utils/theme/custom_themes/text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
      useMaterial3: false,
      fontFamily: 'Poppins',
      brightness: Brightness.light,
      primaryColor: TColors.primary,
      scaffoldBackgroundColor: Colors.white,
      textTheme: TTextTheme.lightTextTheme,
      chipTheme: TChipTheme.lightChipTheme,
      appBarTheme: TAppBarTheme.lightAppBarTheme,
      checkboxTheme: TCheckboxTheme.lightCheckboxTheme,
      bottomSheetTheme: TBottomSheetTheme.lightBottomSheetTheme,
      outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
      elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
      inputDecorationTheme: TTextFieldTheme.lightInputDecorationTheme);

  static ThemeData darkTheme = ThemeData(
      useMaterial3: false,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,
      primaryColor: TColors.primary,
      scaffoldBackgroundColor: const Color(0xff121212),
      textTheme: TTextTheme.darkTextTheme,
      chipTheme: TChipTheme.darkChipTheme,
      appBarTheme: TAppBarTheme.darkAppBarTheme,
      checkboxTheme: TCheckboxTheme.darkCheckboxTheme,
      bottomSheetTheme: TBottomSheetTheme.darkBottomSheetTheme,
      outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
      elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
      inputDecorationTheme: TTextFieldTheme.darkInputDecorationTheme);
}
