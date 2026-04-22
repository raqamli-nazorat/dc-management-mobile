import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:dcmanagement/ui/finance_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RoleService.instance,
      builder: (context, _) {
        if (RoleService.instance.isManager) {
          return const _ManagerHomeScreen();
        }
        return const _WorkerHomeScreen();
      },
    );
  }
}

// ── Manager Home ──────────────────────────────────────────────────────────────

class _ManagerHomeScreen extends StatelessWidget {
  const _ManagerHomeScreen();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xush kelibsiz!',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Boshqaruv paneli orqali ishlarni davom ettiring',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  color: colors.textSub,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Moliyaviy bo'lim",
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textStrong,
                ),
              ),
              const SizedBox(height: 16),
              FinanceCard(
                onTap: () => context.push('/finance/expense-requests'),
                title: "Xarajat so'rovlari",
                imagePath: 'assets/images/earth.png',
                isWide: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FinanceCard(
                      title: 'Ish haqi',
                      onTap: () => context.push('/finance/salary'),
                      imagePath: 'assets/images/briefcase.png',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FinanceCard(
                      onTap: () => context.push('/finance/history'),
                      title: 'Tarix',
                      imagePath: 'assets/images/mobile.png',
                      backgroundColor: colors.accentDisabled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Boshqalar',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textStrong,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DashboardItem(
                      onTap: () => context.push('/projects'),
                      title: 'Loyihalar',
                      icon: Icons.folder_open_rounded,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DashboardItem(
                      onTap: () => context.push('/users'),
                      title: 'Xodimlar',
                      icon: Icons.people_outline_rounded,
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Worker Home ───────────────────────────────────────────────────────────────

class _WorkerHomeScreen extends StatelessWidget {
  const _WorkerHomeScreen();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xush kelibsiz!',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Xarajat so\'rovlaringizni bu yerdan boshqaring',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  color: colors.textSub,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Mening so'rovlarim",
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textStrong,
                ),
              ),
              const SizedBox(height: 16),
              FinanceCard(
                onTap: () => context.go('/my-requests'),
                title: "Mening so'rovlarim",
                imagePath: 'assets/images/earth.png',
                isWide: true,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/finance/expense-request-form'),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.accentSub,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.plusCircle,
                        color: colors.textWhite,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "So'rov yuborish",
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _DashboardItem extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final IconData icon;
  final AppColors colors;

  const _DashboardItem({
    required this.onTap,
    required this.title,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeSub),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.accentSub, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
