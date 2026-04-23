import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  String _getIconAsset(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
      case 'admin':
        return 'assets/roles_icon/admin.png';
      case 'manager':
        return 'assets/roles_icon/manager.png';
      case 'accountant':
        return 'assets/roles_icon/acsessor.png';
      case 'observer':
        return 'assets/roles_icon/modertator.png';
      default:
        return 'assets/roles_icon/worker.png';
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
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      fontFamily: "Manrope",
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tizim funksiyalariga kirish siz tanlagan rolga bog'liq",
                    style: TextStyle(
                      color: colors.white,
                      fontSize: 15,
                      letterSpacing: 1.2,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),

                  // Role Cards
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: roles.length,
                    separatorBuilder: (context2, i) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final role = roles[index];
                      return GestureDetector(
                        onTap: () async {
                          await RoleService.instance.setRole(role);
                          if (!context.mounted) return;
                          context.go('/home');
                        },
                        child: Container(
                          height: 68,
                          decoration: BoxDecoration(
                            color: colors.backgroundElevation1,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 20),
                                Image.asset(
                                  _getIconAsset(role),
                                  width: 28,
                                  height: 28,
                                  color: colors.iconStrong,
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
                                // const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
