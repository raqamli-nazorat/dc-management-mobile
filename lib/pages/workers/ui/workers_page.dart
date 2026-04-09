import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_spacing.dart';

class WorkersPage extends StatelessWidget {
  const WorkersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(title: const Text('Ishchilar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.obsidian,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              style: const TextStyle(color: AppColors.ivory),
              decoration: InputDecoration(
                hintText: 'Qidirish...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list, size: 20),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          // Workers list placeholder
          const Expanded(
            child: Center(
              child: Text('Ishchilar ro\'yxati', style: AppTextStyles.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
