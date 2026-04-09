import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_spacing.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Umumiy ko\'rsatkichlar', style: AppTextStyles.h3),
            SizedBox(height: AppSpacing.md),
            _StatsGrid(),
            SizedBox(height: AppSpacing.lg),
            Text('So\'nggi ishchilar', style: AppTextStyles.h3),
            SizedBox(height: AppSpacing.md),
            _RecentWorkersPlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: const [
        _StatCard(label: 'Jami ishchilar', value: '—', icon: Icons.people, accent: true),
        _StatCard(label: 'Faol ishchilar', value: '—', icon: Icons.person_pin),
        _StatCard(label: "Bo'limlar", value: '—', icon: Icons.business),
        _StatCard(label: 'Nofaol', value: '—', icon: Icons.person_off_outlined),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool accent;
  const _StatCard({required this.label, required this.value, required this.icon, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent ? AppColors.gold.withAlpha(50) : AppColors.smoke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: accent ? AppColors.gold : AppColors.silver, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.h2),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentWorkersPlaceholder extends StatelessWidget {
  const _RecentWorkersPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.smoke),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text("Ma'lumotlar yuklanmoqda...", style: AppTextStyles.bodySmall),
        ),
      ),
    );
  }
}
