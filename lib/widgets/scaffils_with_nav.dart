import 'package:dcmanagement/colors/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _TabItem {
  final String label;
  final String path;
  final IconData? activeIcon;
  final IconData? inactiveIcon;

  const _TabItem({
    required this.label,
    required this.path,
    this.activeIcon,
    this.inactiveIcon,
  });
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  static const _tabs = [
    _TabItem(
      label: 'Foydalanuvchilar',
      path: '/users',
      activeIcon: LucideIcons.users,
      inactiveIcon: LucideIcons.users,
    ),
    _TabItem(
      label: 'Moliya',
      path: '/home',
      activeIcon: LucideIcons.briefcase,
      inactiveIcon: LucideIcons.briefcase,
    ),
    _TabItem(
      label: 'Loyihalar',
      path: '/projects',
      activeIcon: LucideIcons.folder,
      inactiveIcon: LucideIcons.folderOpen,
    ),
    _TabItem(
      label: 'Hisobotlar',
      path: '/reports',
      activeIcon: LucideIcons.barChart2,
      inactiveIcon: LucideIcons.barChart2,
    ),
    _TabItem(
      label: 'Shaxsiy',
      path: '/profile',
      activeIcon: LucideIcons.user,
      inactiveIcon: LucideIcons.user,
    ),
  ];

  static const _activeColor = Color(0xFF5B6EF5);
  static const _activeBg = Color(0x155B6EF5);

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexWhere((t) => location.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex(context);
    final colors = AppColors.of(context);
    final inactiveColor = colors.iconSub;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.backgroundBase,
          border: Border(
            top: BorderSide(color: colors.strokeSub, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == current;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.path),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? _activeBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? tab.activeIcon : tab.inactiveIcon,
                            size: 22,
                            color: isActive ? _activeColor : inactiveColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive ? _activeColor : inactiveColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isActive ? 4 : 0,
                            height: isActive ? 4 : 0,
                            decoration: const BoxDecoration(
                              color: _activeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
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
