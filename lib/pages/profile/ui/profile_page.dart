import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../features/auth/model/auth_notifier.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Avatar & name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.graphite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.smoke),
                  ),
                  child: Center(
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, color: AppColors.ivory, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? '—', style: AppTextStyles.h2),
                const SizedBox(height: 4),
                Text(user?.email ?? '—', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Logout
          OutlinedButton.icon(
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Tizimdan chiqish'),
          ),
        ],
      ),
    );
  }
}
