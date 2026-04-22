import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.barChart2, size: 48, color: colors.iconSub),
              const SizedBox(height: 12),
              Text(
                'Hisobotlar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textStrong,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tez orada...',
                style: TextStyle(fontSize: 14, color: colors.textSub),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
