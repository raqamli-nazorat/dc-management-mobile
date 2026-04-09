import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.obsidian,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.charcoal,
        primary: AppColors.gold,
        onPrimary: AppColors.obsidian,
        secondary: AppColors.goldLight,
        onSecondary: AppColors.obsidian,
        onSurface: AppColors.ivory,
        outline: AppColors.smoke,
        error: AppColors.danger,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        headlineSmall: AppTextStyles.h3,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelSmall: AppTextStyles.labelSmall,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.charcoal,
        foregroundColor: AppColors.ivory,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2,
        iconTheme: IconThemeData(color: AppColors.silver),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.charcoal,
        shadowColor: Colors.black54,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.smoke),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.obsidian,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ivory,
          side: const BorderSide(color: AppColors.smoke),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.graphite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.smoke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.smoke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: const TextStyle(color: AppColors.silver, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.ash, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.smoke, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.charcoal,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.silver,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      iconTheme: const IconThemeData(color: AppColors.silver, size: 22),
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.charcoal,
        textColor: AppColors.ivory,
        iconColor: AppColors.silver,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      splashFactory: InkRipple.splashFactory,
      highlightColor: AppColors.smoke.withAlpha(80),
      splashColor: AppColors.gold.withAlpha(20),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.graphite,
        contentTextStyle: const TextStyle(color: AppColors.ivory),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
