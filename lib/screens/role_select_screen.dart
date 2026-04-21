import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  IconData _getIcon(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
      case 'admin':
        return LucideIcons.building2;
      case 'manager':
        return LucideIcons.briefcase;
      case 'accountant':
        return LucideIcons.coins; // Hisobchi uchun yaxshiroq icon
      case 'observer':
        return LucideIcons.globe;
      default:
        return LucideIcons.user;
    }
  }

  String _getTitle(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
      case 'admin':
        return "Administrator";
      case 'manager':
        return "Menejer";
      case 'accountant':
        return "Hisobchi";
      case 'observer':
        return "Nazoratchi";
      default:
        return "Xodim";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: FutureBuilder<List<String>>(
        future: AuthService().getUserRoles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colors.accentSub),
            );
          }

          final roles = snapshot.data ?? [];

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "O'zingiz uchun rolni tanlang",
                    style: TextStyle(
                      color: colors.textStrong,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Manrope",
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tizim funksiyalariga kirish siz tanlagan rolga bog'liq",
                    style: TextStyle(
                      color: colors.textSub,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 450),

                  // Role Cards
                  Expanded(
                    child: ListView.separated(
                      itemCount: roles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final role = roles[index];
                        return GestureDetector(
                          onTap: () async {
                            await StorageService().saveString(
                              'selected_role',
                              role,
                            );
                            if (!context.mounted) return;
                            context.go('/home');
                          },
                          child: Container(
                            height: 68,
                            decoration: BoxDecoration(
                              color: colors.backgroundElevation1,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 20),
                                Icon(
                                  _getIcon(role),
                                  color: colors.iconStrong,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  _getTitle(role),
                                  style: TextStyle(
                                    color: colors.textStrong,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
