import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';

class _TabItem {
  final String label;
  final String path;
  final String? svgAsset; // assets/icons/...svg
  final IconData? fallbackIcon; // SVG yo'q bo'lsa

  const _TabItem({
    required this.label,
    required this.path,
    this.svgAsset,
    this.fallbackIcon,
  });
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  static const _tabs = [
    _TabItem(
      label: 'Foydalanuvchilar',
      path: '/users',
      fallbackIcon: LucideIcons.users,
    ),
    _TabItem(
      label: 'Loyihalar',
      path: '/projects',
      svgAsset: 'assets/icons/folder.svg',
    ),
    _TabItem(
      label: 'Moliya',
      path: '/home',
      svgAsset: 'assets/icons/briefcase-dollar.svg',
    ),
    _TabItem(
      label: 'Hisobotlar',
      path: '/reports',
      svgAsset: 'assets/icons/analytics.svg',
    ),
    _TabItem(
      label: 'Shaxsiy',
      path: '/profile',
      fallbackIcon: null, // avatar widget ishlatamiz
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
          border: Border(top: BorderSide(color: colors.strokeSub, width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
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
                final iconColor = isActive ? _activeColor : inactiveColor;

                Widget iconWidget;

                if (i == 4) {
                  // Shaxsiy — avatar
                  iconWidget = _AvatarIcon(isActive: isActive);
                } else if (tab.svgAsset != null) {
                  iconWidget = SvgPicture.asset(
                    tab.svgAsset!,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  );
                } else {
                  iconWidget = Icon(
                    tab.fallbackIcon,
                    size: 22,
                    color: iconColor,
                  );
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.path),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          iconWidget,
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive ? _activeColor : inactiveColor,
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

// ---------------------------------------------------------------------------
// Avatar icon — AuthService dan username oladi
// ---------------------------------------------------------------------------
class _AvatarIcon extends StatefulWidget {
  final bool isActive;
  const _AvatarIcon({required this.isActive});

  @override
  State<_AvatarIcon> createState() => _AvatarIconState();
}

class _AvatarIconState extends State<_AvatarIcon> {
  String _initial = 'A';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username') ?? 'A';
    if (mounted) setState(() => _initial = name[0].toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF5B6EF5);
    const activeBg = Color(0x155B6EF5);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: widget.isActive ? activeBg : const Color(0xFFE5E7EB),
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
          color: widget.isActive ? activeColor : const Color(0xFF6B7280),
        ),
      ),
    );
  }
}
