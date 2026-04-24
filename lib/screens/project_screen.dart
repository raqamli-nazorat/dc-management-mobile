import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:dcmanagement/ui/finance_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

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
    // Worker: Loyihalar + Mening yig'ilishlarim
    if (role.isWorker) {
      return Column(
        children: [
          FinanceCard(
            onTap: () => context.push('/projects/list'),
            title: 'Loyihalar',
            imagePath: 'assets/projects_icon/briefcase.png',
            isWide: true,
          ),
          const SizedBox(height: 12),
          FinanceCard(
            onTap: () => context.push('/projects/my-meetings'),
            title: "Mening yig'ilishlarim",
            imagePath: 'assets/projects_icon/user3d.png',
            isWide: true,
          ),
        ],
      );
    }

    // Admin / Manager: Loyihalar (keng) + Vazifalar + Yig'ilishlar (yarim)
    return Column(
      children: [
        FinanceCard(
          onTap: () => context.push('/projects/list'),
          title: 'Loyihalar',
          imagePath: 'assets/projects_icon/briefcase.png',
          isWide: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FinanceCard(
                onTap: () => context.push('/projects/tasks'),
                title: 'Vazifalar',
                imagePath: 'assets/projects_icon/folder.png',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FinanceCard(
                onTap: () => context.push('/projects/meetings'),
                title: "Yig'ilishlar",
                imagePath: 'assets/projects_icon/user3d.png',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
