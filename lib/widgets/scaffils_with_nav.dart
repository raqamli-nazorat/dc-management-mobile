import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// svg  → actual SVG file  (SvgPicture)
// png  → PNG file with .svg extension (Image.asset + ColorFiltered)
// avatar → circle with user initial
enum _AssetType { svg, png, avatar }

class _TabItem {
  final String label;
  final String path;
  final String? asset;
  final _AssetType type;

  const _TabItem({
    required this.label,
    required this.path,
    this.asset,
    this.type = _AssetType.svg,
  });
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  final String location;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
    required this.location,
  });

  // ── Worker ───────────────────────────────────────────────────────────────
  static const _workerTabs = [
    _TabItem(label: 'Bosh sahifa',      path: '/home',     asset: 'assets/icons/dashboard.svg',        type: _AssetType.png),
    _TabItem(label: 'Foydalanuvchilar', path: '/users',    asset: 'assets/icons/users.svg',            type: _AssetType.png),
    _TabItem(label: 'Loyihalar',        path: '/projects', asset: 'assets/icons/folder.svg',           type: _AssetType.svg),
    _TabItem(label: 'Moliya',           path: '/finance',  asset: 'assets/icons/briefcase-dollar.svg', type: _AssetType.svg),
    _TabItem(label: 'Hisobotlar',       path: '/reports',  asset: 'assets/icons/analytics.svg',        type: _AssetType.svg),
    _TabItem(label: 'Shaxsiy',          path: '/profile',  type: _AssetType.avatar),
  ];

  // ── Manager ──────────────────────────────────────────────────────────────
  static const _managerTabs = [
    _TabItem(label: 'Bosh sahifa',      path: '/home',     asset: 'assets/icons/dashboard.svg',        type: _AssetType.png),
    _TabItem(label: 'Foydalanuvchilar', path: '/users',    asset: 'assets/icons/users.svg',            type: _AssetType.png),
    _TabItem(label: 'Loyihalar',        path: '/projects', asset: 'assets/icons/folder.svg',           type: _AssetType.svg),
    _TabItem(label: 'Moliya',           path: '/finance',  asset: 'assets/icons/briefcase-dollar.svg', type: _AssetType.svg),
    _TabItem(label: 'Hisobotlar',       path: '/reports',  asset: 'assets/icons/analytics.svg',        type: _AssetType.svg),
    _TabItem(label: 'Shaxsiy',          path: '/profile',  type: _AssetType.avatar),
  ];

  // ── Admin ────────────────────────────────────────────────────────────────
  static const _adminTabs = [
    _TabItem(label: 'Tekshiruv', path: '/home',     asset: 'assets/icons/users.svg',            type: _AssetType.png),
    _TabItem(label: 'Loyihalar', path: '/projects', asset: 'assets/icons/folder.svg',           type: _AssetType.svg),
    _TabItem(label: 'Moliya',    path: '/finance',  asset: 'assets/icons/briefcase-dollar.svg', type: _AssetType.svg),
    _TabItem(label: 'Hisobotlar',path: '/reports',  asset: 'assets/icons/analytics.svg',        type: _AssetType.svg),
    _TabItem(label: 'Shaxsiy',   path: '/profile',  type: _AssetType.avatar),
  ];

  bool get _hideNavBar =>
      location.startsWith('/login') ||
      location.startsWith('/pin') ||
      location.startsWith('/select-role');

  int _currentIndex(List<_TabItem> tabs) {
    final i = tabs.indexWhere((t) => location.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RoleService.instance,
      builder: (context, _) {
        final colors = AppColors.of(context);
        final tabs = RoleService.instance.isAdmin
            ? _adminTabs
            : RoleService.instance.isManager
                ? _managerTabs
                : _workerTabs;
        final current = _currentIndex(tabs);

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
                        color: colors.shadow.withValues(alpha: 0.06),
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
                        children: List.generate(tabs.length, (i) {
                          final tab = tabs[i];
                          final isActive = i == current;
                          final iconColor = isActive ? colors.accentSub : colors.iconSub;

                          final Widget icon = switch (tab.type) {
                            _AssetType.avatar => AvatarIcon(isActive: isActive),
                            _AssetType.png => ColorFiltered(
                                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                                child: Image.asset(tab.asset!, width: 22, height: 22),
                              ),
                            _AssetType.svg => SvgPicture.asset(
                                tab.asset!,
                                width: 22,
                                height: 22,
                                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                              ),
                          };

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
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar tab icon
// ─────────────────────────────────────────────────────────────────────────────

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
        color: widget.isActive ? colors.accentDisabled : colors.backgroundElevation2,
        shape: BoxShape.circle,
        border: widget.isActive ? Border.all(color: activeColor, width: 1.5) : null,
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
