import 'package:flutter/material.dart';

class TColors {
  TColors._();

  // App Basic Colors
  static const Color primary = Color(0xFF826AFD);
  static const Color darkPrimary = Color(0xFF4868FF);
  static const Color secondary = Color(0xFFFFE248);
  static const Color accent = Color(0xFFb0c7ff);

  static const Color darkbg = Color(0xFF1A1534);
  static const Color purple = Color(0xFF2D245C);

  // Gradient Colors
  static const Gradient linearGradient = LinearGradient(
      begin: Alignment(0.0, 0.0),
      end: Alignment(0.707, -0.707),
      colors: [
        Color(0xFFff9a9e),
        Color(0xFFfad0c4),
        Color(0xFFfad0c4),
      ]);

  // Text Colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textDark = Colors.white;
  static const Color textSecondary = Color(0xFF6c7570);

  // Background Colors
  static const Color light = Color(0xFFf6f6f6);
  static const Color dark = Color(0xFF272727);
  static const Color primaryBackground = Color(0xFFf3f5ff);

  // Background Container Colors
  static const Color lightContainer = Color(0xFFF6F6F6);
  static Color darkContainer = TColors.white.withOpacity(0.1);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF4b68ff);
  static const Color buttonSecondary = Color(0xFF6c7570);
  static const Color buttonDisabled = Color(0xFFc4c4c4);

  // Border Colors
  static const Color borderPrimary = Color(0xFFd9d9d9);
  static const Color borderSecondary = Color(0xFFe6e6e6);

  // Error and Validation Colors
  static const Color error = Color(0xFFd32f2f);
  static const Color success = Color(0xFF388e3c);
  static const Color warning = Color(0xFFf57c00);
  static const Color info = Color(0xFF1976d2);

  // Neutral Shades
  static const Color black = Color(0xFF232323);
  static const Color grey = Color(0xFFe0e0e0);
  static const Color darkGrey = Color(0xFF939393);
  static const Color darkerGrey = Color(0xFF4f4f4f);
  static const Color lightGrey = Color(0xFFf9f9f9);
  static const Color softGrey = Color(0xFFf4f4f4);
  static const Color white = Color(0xFFFFFFFF);

  static const Color trackColor = Color.fromARGB(255, 155, 39, 198);
  static const Color progressBarColor = Color.fromARGB(255, 236, 90, 209);
}
