import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:dcmanagement/ui/finance_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ListenableBuilder(
      listenable: RoleService.instance,
      builder: (context, _) {
        final role = RoleService.instance;

        return Scaffold(
          backgroundColor: colors.backgroundBase,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildContent(context, role),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, RoleService role) {
    // Admin / Superadmin: Xarajat so'rovlari + Ish haqi + Tarix
    if (role.isAdmin) {
      return Column(
        children: [
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
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Manager: Xarajat so'rovlari + Mening so'rovlarim
    if (role.isManager) {
      return Column(
        children: [
          FinanceCard(
            onTap: () => context.push('/finance/expense-requests'),
            title: "Xarajat so'rovlari",
            imagePath: 'assets/images/earth.png',
            isWide: true,
          ),
          const SizedBox(height: 12),
          FinanceCard(
            onTap: () => context.push('/finance/my-requests'),
            title: "Mening so'rovlarim",
            imagePath: 'assets/images/docs.png',
            isWide: true,
          ),
        ],
      );
    }

    // Employee / Worker: faqat Mening so'rovlarim
    return Column(
      children: [
        FinanceCard(
          onTap: () => context.push('/finance/my-requests'),
          title: "Mening so'rovlarim",
          imagePath: 'assets/images/docs.png',
          isWide: true,
        ),
      ],
    );
  }
}
