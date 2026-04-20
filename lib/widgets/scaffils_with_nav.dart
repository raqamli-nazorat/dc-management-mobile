import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/screens/finance_screen.dart';
import 'package:dcmanagement/screens/login_screen.dart';
import 'package:dcmanagement/screens/profile_screen.dart';
import 'package:dcmanagement/screens/project_screen.dart';
import 'package:dcmanagement/screens/role_select_screen.dart';
import 'package:dcmanagement/screens/users_scree.dart';     // ← To'g'rilangan
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TabType { icon, svg, avatar }

class _TabItem {
  final String label;
  final String path;
  final String? svgAsset;
  final IconData? fallbackIcon;
  final TabType type;

  const _TabItem({
    required this.label,
    required this.path,
    this.svgAsset,
    this.fallbackIcon,
    this.type = TabType.icon,
  });
}

final GoRouter router = GoRouter(
  initialLocation: '/role',
  routes: [
    GoRoute(
      path: '/role',
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(
        location: state.uri.path,   // ← Eng muhim qism
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/users',
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsScreen(),
        ),
        GoRoute(
          path: '/finance',
          builder: (context, state) => const FinanceScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Reports'))),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  final String location;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
    required this.location,
  });

  static const _tabs = [
    _TabItem(
      label: 'Foydalanuvchilar',
      path: '/users',
      fallbackIcon: LucideIcons.users,
      type: TabType.icon,
    ),
    _TabItem(
      label: 'Loyihalar',
      path: '/projects',
      svgAsset: 'assets/icons/folder.svg',
      type: TabType.svg,
    ),
    _TabItem(
      label: 'Moliya',
      path: '/finance',
      svgAsset: 'assets/icons/briefcase-dollar.svg',
      type: TabType.svg,
    ),
    _TabItem(
      label: 'Hisobotlar',
      path: '/reports',
      svgAsset: 'assets/icons/analytics.svg',
      type: TabType.svg,
    ),
    _TabItem(
      label: 'Shaxsiy',
      path: '/profile',
      type: TabType.avatar,
    ),
  ];

  bool get _hideNavBar {
    return location.startsWith('/role') ||
        location.startsWith('/login') ||
        location.startsWith('/splash');
  }

  int _currentIndex() {
    final i = _tabs.indexWhere((t) => location.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final current = _currentIndex();
    final inactiveColor = colors.iconSub;

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: child,
      bottomNavigationBar: _hideNavBar
          ? null
          : Container(
              decoration: BoxDecoration(
                color: colors.backgroundBase,
                border: Border(
                  top: BorderSide(color: colors.strokeSub, width: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final tab = _tabs[i];
                      final isActive = i == current;
                      final iconColor = isActive
                          ? colors.accentSub
                          : inactiveColor;

                      Widget icon;
                      switch (tab.type) {
                        case TabType.avatar:
                          icon = AvatarIcon(isActive: isActive);
                          break;
                        case TabType.svg:
                          icon = SvgPicture.asset(
                            tab.svgAsset!,
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              iconColor,
                              BlendMode.srcIn,
                            ),
                          );
                          break;
                        case TabType.icon:
                        default:
                          icon = Icon(
                            tab.fallbackIcon,
                            size: 22,
                            color: iconColor,
                          );
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => context.go(tab.path),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              icon,
                              const SizedBox(height: 4),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}

// ---------------- AVATAR ----------------
class AvatarIcon extends StatefulWidget {
  final bool isActive;
  const AvatarIcon({super.key, required this.isActive});

  @override
  State<AvatarIcon> createState() => _AvatarIconState();
}

class _AvatarIconState extends State<AvatarIcon> {
  String _initial = 'A';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username') ?? 'A';
    if (mounted) {
      setState(() {
        _initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final activeColor = colors.accentSub;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: widget.isActive
            ? colors.accentDisabled
            : colors.backgroundElevation2,
        shape: BoxShape.circle,
        border: widget.isActive
            ? Border.all(color: activeColor, width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: widget.isActive ? activeColor : colors.textSub,
        ),
      ),
    );
  }
}