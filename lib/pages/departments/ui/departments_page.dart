import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class DepartmentsPage extends StatelessWidget {
  const DepartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(title: const Text("Bo'limlar")),
      body: const Center(
        child: Text("Bo'limlar ro'yxati", style: AppTextStyles.bodyMedium),
      ),
    );
  }
}
