import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/ui/finance_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Minimal — faqat majburiy proplar
            FinanceCard(
              onTap: () => context.push('/finance/expense-requests'),
              title: "Xarajat so'rovlari",
              imagePath: 'assets/images/earth.png',
              isWide: true,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                // Hamma narsa default
                Expanded(
                  child: FinanceCard(
                    title: 'Ish haqi',
                    onTap: () => context.push('/finance/salary'),
                    imagePath: 'assets/images/briefcase.png',
                  ),
                ),
                const SizedBox(width: 12),
                // Bazi narsalar custom
                Expanded(
                  child: FinanceCard(
                    onTap: () => context.push('/finance/history'),
                    title: 'Tarix',
                    imagePath: 'assets/images/mobile.png',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
