import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Record o'rniga class — chunki icon turi mixed (IconData yoki rasm)
class _TabItem {
  final String label;
  final String path;

  // Material icon ishlatmoqchi bo'lsang shu ikkalasini to'ldir
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
      label: 'Ishchilar',
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
  static const _inactiveColor = Color(0xFF9E9E9E);
  static const _activeBg = Color(0x155B6EF5);

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexWhere((t) => location.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  // Icon yoki rasm qaytaradigan helper
  Widget _buildIcon(_TabItem tab, bool isActive) {
    return Icon(
      isActive ? tab.activeIcon : tab.inactiveIcon,
      size: 22,
      color: isActive ? _activeColor : _inactiveColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                          _buildIcon(
                            tab,
                            isActive,
                          ), // ✅ shu yerda qaror qilinadi
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive ? _activeColor : _inactiveColor,
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
