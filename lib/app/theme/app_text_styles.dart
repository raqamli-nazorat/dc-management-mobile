import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display (Playfair Display)
  static const displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.ivory,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const displayMedium = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: AppColors.ivory,
    height: 1.25,
  );

  // Headings
  static const h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.ivory,
    height: 1.3,
  );

  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.ivory,
    height: 1.35,
  );

  static const h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ivory,
    height: 1.4,
  );

  // Body
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.pearl,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.pearl,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.silver,
    height: 1.4,
  );

  // Label
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.ivory,
    height: 1.2,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.silver,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // Gold accent text
  static const goldLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.gold,
  );
}
