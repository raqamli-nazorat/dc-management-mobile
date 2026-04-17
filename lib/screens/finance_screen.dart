import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 🔥 vertical center
            // crossAxisAlignment: CrossAxisAlignment.center, //
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moliya',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colors.textStrong,
                ),
              ),
              const SizedBox(height: 16),

              _BigCard(
                colors: colors,
                title: "Xarajat so'rovlari",
                imagePath: 'assets/images/earth.png',
                onTap: () => context.push('/finance/expense-requests'),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _SmallCard(
                      colors: colors,
                      title: 'Ish haqi',
                      imagePath: 'assets/images/briefcase.png',
                      onTap: () => context.push('/finance/salary'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallCard(
                      colors: colors,
                      title: 'Tarix',
                      imagePath: 'assets/images/mobile.png',
                      onTap: () => context.push('/finance/history'),
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

// ─────────────────────────────────────────

class _BigCard extends StatelessWidget {
  final AppColors colors;
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _BigCard({
    required this.colors,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 20), // 🔥 FIX
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.strokeSub),
        ),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft, // 🔥 FIX
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textStrong,
                  ),
                ),
              ),
            ),
            Center(
              // 🔥 FIX
              child: Image.asset(
                imagePath,
                width: 110,
                height: 110,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────

class _SmallCard extends StatelessWidget {
  final AppColors colors;
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _SmallCard({
    required this.colors,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.strokeSub),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textStrong,
              ),
            ),
            Image.asset(imagePath, width: 80, height: 80, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}