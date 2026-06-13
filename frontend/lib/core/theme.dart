import 'package:flutter/material.dart';

/// All app colors live here. To change the look of the app, edit this file.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFC2C2C2); // medium gray (matches reference)
  static const Color surface = Color(0xFFFFFFFF);

  // Sidebar
  static const Color navSelected = Color(0xFF3D3D3D);
  static const Color navUnselected = Color(0xFFE8E8E8);

  // Status
  static const Color activeGreen = Color(0xFF27AE60);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  // Shadows (semi-transparent black)
  static const Color cardShadow = Color(0x33000000); // 20% black — visible on gray bg
  static const Color sidebarShadow = Color(0x40000000); // 25% black
  static const Color backdrop = Color(0x4D000000); // 30% black
}

/// Call this in MaterialApp's `theme:` parameter.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      surface: AppColors.surface,
      primary: AppColors.navSelected,
    ),
    fontFamily: 'Roboto',
  );
}
