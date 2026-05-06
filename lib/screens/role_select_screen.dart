import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  final _authService = AuthService();
  late final Future<List<String>> _rolesFuture;
  String? _savingRole;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rolesFuture = _authService.getUserRoles();
  }

  String _getIconAsset(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
      case 'admin':
        return 'assets/roles_icon/admin.png';
      case 'manager':
        return 'assets/roles_icon/manager.png';
      case 'accountant':
        return 'assets/roles_icon/acsessor.png';
      case 'auditor':
      case 'observer':
        return 'assets/roles_icon/modertator.png';
      case 'employee':
        return 'assets/roles_icon/worker.png';
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
      case 'auditor':
        return "Auditor";
      case 'observer':
        return "Nazoratchi";
      case 'employee':
        return "Xodim";
      default:
        return role;
    }
  }

  void _logRoleMapping(List<String> roles) {
    final mappedRoles = roles
        .map((role) => '$role -> ${_getTitle(role)}')
        .join(', ');
    debugPrint('=== ROLE SELECT: response roles [$mappedRoles] ===');
  }

  Future<void> _selectRole(String role) async {
    if (_savingRole != null) return;

    debugPrint('=== ROLE SELECT: selected role=$role ===');
    setState(() {
      _savingRole = role;
      _errorMessage = null;
    });

    try {
      final activeRole = await _authService.changeActiveRole(role);
      debugPrint('=== ROLE SELECT: API active_role=$activeRole ===');
      await RoleService.instance.setRole(activeRole);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingRole = null;
        _errorMessage = "Rolni o'zgartirishda xatolik yuz berdi: $e";
      });
      debugPrint('=== ROLE SELECT CHANGE ERROR: $e ===');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: FutureBuilder<List<String>>(
        future: _rolesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colors.accentSub),
            );
          }

          final roles = snapshot.data ?? [];
          _logRoleMapping(roles);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Siz dasturni bir nechta rol bilan foydalanishingiz mumkin",
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
                    "Quyidagilardan birini tanlang.",
                    style: TextStyle(
                      color: colors.textStrong,
                      fontSize: 15,
                      letterSpacing: 1.2,
                      height: 1.4,
                      fontFamily: "Manrope",
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colors.errorSub,
                        fontSize: 13,
                        fontFamily: "Manrope",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                      final isSaving = _savingRole == role;
                      return GestureDetector(
                        onTap: _savingRole == null
                            ? () => _selectRole(role)
                            : null,
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
                                if (isSaving) ...[
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.accentSub,
                                    ),
                                  ),
                                ],
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
