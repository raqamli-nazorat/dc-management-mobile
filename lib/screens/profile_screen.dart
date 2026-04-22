import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/user_model.dart';
import 'package:dcmanagement/providers/theme_notifier.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/role_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _svgIcon(String path, Color color, {double size = 20}) =>
    SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

Widget _pngIcon(String path, Color color, {double size = 20}) =>
    ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: Image.asset(path, width: size, height: size),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _api = ApiService();
  late Future<UserModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<UserModel> _fetch() async {
    final token = await _auth.getToken();
    if (token == null) throw Exception('Token topilmadi');
    return _api.getMe(token);
  }

  Future<void> _logout() async {
    final colors = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.backgroundElevation1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Chiqish',
          style: TextStyle(fontWeight: FontWeight.w700, color: colors.textStrong),
        ),
        content: Text(
          'Hisobdan chiqmoqchimisiz?',
          style: TextStyle(color: colors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Bekor qilish', style: TextStyle(color: colors.textSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Chiqish', style: TextStyle(color: colors.errorSub)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      if (mounted) context.go('/login');
    }
  }

  String _formatMoney(String raw) {
    try {
      final val = double.parse(raw);
      final intPart = val.toStringAsFixed(0);
      final buffer = StringBuffer();
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) buffer.write(' ');
        buffer.write(intPart[i]);
        count++;
      }
      return buffer.toString().split('').reversed.join();
    } catch (_) {
      return raw;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Shaxsiy',
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      color: colors.textStrong,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<UserModel>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: colors.accentSub),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        snap.error.toString(),
                        style: TextStyle(color: colors.textSub),
                      ),
                    );
                  }
                  return ListenableBuilder(
                    listenable: RoleService.instance,
                    builder: (context, _) => _buildBody(snap.data!, colors),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(UserModel user, AppColors colors) {
    final rs = RoleService.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // ── Avatar ──────────────────────────────────────────────────
          _AvatarCard(user: user, colors: colors),

          const SizedBox(height: 12),

          // ── Admin: quick navigation grid ─────────────────────────────
          if (rs.isAdmin) ...[
            _AdminGrid(colors: colors),
            const SizedBox(height: 12),
          ],

          // ── Personal info ────────────────────────────────────────────
          _SectionCard(
            colors: colors,
            iconWidget: _pngIcon('assets/icons/users.svg', colors.iconSub),
            title: 'Shaxsiy ma\'lumotlar',
            children: [
              _DataRow(label: 'Telefon', value: user.phoneNumber.isEmpty ? '—' : user.phoneNumber, colors: colors),
              _divider(colors),
              _DataRow(label: 'Pasport seriyasi', value: user.passportSeries.isEmpty ? '—' : user.passportSeries, colors: colors),
              if (user.dateJoined != null && user.dateJoined!.isNotEmpty) ...[
                _divider(colors),
                _DataRow(label: 'Qo\'shilgan sana', value: _formatDate(user.dateJoined!), colors: colors),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // ── Finance (worker + manager) ────────────────────────────────
          if (rs.isWorker || rs.isManager) ...[
            _SectionCard(
              colors: colors,
              iconWidget: _svgIcon('assets/icons/briefcase-dollar.svg', colors.iconSub),
              title: 'Moliyaviy',
              children: [
                _DataRow(
                  label: 'Oylik maosh',
                  value: '${_formatMoney(user.fixedSalary)} so\'m',
                  colors: colors,
                ),
                _divider(colors),
                _DataRow(
                  label: 'Joriy balans',
                  value: '${_formatMoney(user.balance)} so\'m',
                  colors: colors,
                  highlight: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Worker quick links ────────────────────────────────────────
          if (rs.isWorker) ...[
            _QuickLinkTile(
              colors: colors,
              iconWidget: _svgIcon('assets/icons/briefcase-dollar.svg', colors.accentSub),
              title: 'Mening so\'rovlarim',
              subtitle: 'Xarajat so\'rovlarini ko\'rish',
              onTap: () => context.push('/my-requests'),
            ),
            const SizedBox(height: 12),
          ],

          // ── Manager quick links ───────────────────────────────────────
          if (rs.isManager) ...[
            _QuickLinkTile(
              colors: colors,
              iconWidget: _svgIcon('assets/icons/analytics.svg', colors.accentSub),
              title: 'Xarajat so\'rovlari',
              subtitle: 'Barcha so\'rovlarni ko\'rish va tasdiqlash',
              onTap: () => context.push('/finance/expense-requests'),
            ),
            const SizedBox(height: 12),
          ],

          // ── Role switcher ─────────────────────────────────────────────
          _RoleSwitcherSection(colors: colors),

          const SizedBox(height: 12),

          // ── Theme switcher ────────────────────────────────────────────
          _ThemeSwitcher(colors: colors),

          const SizedBox(height: 24),

          // ── Logout ────────────────────────────────────────────────────
          GestureDetector(
            onTap: _logout,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: colors.errorSub.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.errorSub.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: colors.errorSub),
                  const SizedBox(width: 8),
                  Text(
                    'Chiqish',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      color: colors.errorSub,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _divider(AppColors colors) => Divider(height: 20, color: colors.strokeSoft);
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar Card
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarCard extends StatelessWidget {
  final UserModel user;
  final AppColors colors;

  const _AvatarCard({required this.user, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.strokeSub),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colors.accentDisabled,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user.initials,
              style: TextStyle(
                fontSize: 28,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                color: colors.accentSub,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.username,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              color: colors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: colors.accentDisabled,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              RoleService.instance.roleLabel,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                color: colors.accentSub,
              ),
            ),
          ),
          if (user.isActive != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: user.isActive! ? colors.successSub : colors.errorSub,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  user.isActive! ? 'Faol' : 'Nofaol',
                  style: TextStyle(
                    fontSize: 12,
                    color: user.isActive! ? colors.successSub : colors.errorSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Quick Navigation Grid
// ─────────────────────────────────────────────────────────────────────────────

class _AdminGrid extends StatelessWidget {
  final AppColors colors;

  const _AdminGrid({required this.colors});

  @override
  Widget build(BuildContext context) {
    final items = [
      _GridItem(
        title: 'Foydalanuvchilar',
        icon: _pngIcon('assets/icons/users.svg', colors.accentSub, size: 24),
        onTap: () => context.go('/users'),
      ),
      _GridItem(
        title: 'Loyihalar',
        icon: _svgIcon('assets/icons/folder.svg', colors.accentSub, size: 24),
        onTap: () => context.go('/projects'),
      ),
      _GridItem(
        title: 'Moliya',
        icon: _svgIcon('assets/icons/briefcase-dollar.svg', colors.accentSub, size: 24),
        onTap: () => context.go('/finance'),
      ),
      _GridItem(
        title: 'Hisobotlar',
        icon: _svgIcon('assets/icons/analytics.svg', colors.accentSub, size: 24),
        onTap: () => context.go('/reports'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: items.map((item) => _GridCell(item: item, colors: colors)).toList(),
    );
  }
}

class _GridItem {
  final String title;
  final Widget icon;
  final VoidCallback onTap;
  const _GridItem({required this.title, required this.icon, required this.onTap});
}

class _GridCell extends StatelessWidget {
  final _GridItem item;
  final AppColors colors;
  const _GridCell({required this.item, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeSub),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.accentDisabled,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: item.icon,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  color: colors.textStrong,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final AppColors colors;
  final Widget iconWidget;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.colors,
    required this.iconWidget,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSub),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.backgroundElevation2,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: iconWidget,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    color: colors.textSub,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.strokeSub),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Row
// ─────────────────────────────────────────────────────────────────────────────

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final AppColors colors;
  final bool highlight;

  const _DataRow({
    required this.label,
    required this.value,
    required this.colors,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colors.textSub,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Manrope',
            color: highlight ? colors.accentSub : colors.textStrong,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Link Tile
// ─────────────────────────────────────────────────────────────────────────────

class _QuickLinkTile extends StatelessWidget {
  final AppColors colors;
  final Widget iconWidget;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLinkTile({
    required this.colors,
    required this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeSub),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.accentDisabled,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: iconWidget,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w600,
                      color: colors.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: colors.textSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.iconSub, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role Switcher
// ─────────────────────────────────────────────────────────────────────────────

class _RoleSwitcherSection extends StatelessWidget {
  final AppColors colors;
  const _RoleSwitcherSection({required this.colors});

  String _roleLabel(String r) {
    switch (r.toLowerCase()) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Menejer';
      case 'accountant':
        return 'Hisobchi';
      case 'observer':
        return 'Nazoratchi';
      case 'employee':
        return 'Xodim';
      default:
        return r[0].toUpperCase() + r.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RoleService.instance,
      builder: (context, _) {
        return FutureBuilder<List<String>>(
          future: AuthService().getUserRoles(),
          builder: (context, snap) {
            final roles = snap.data ?? [];
            final currentRole = RoleService.instance.role ?? '';

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.backgroundElevation1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.strokeSub),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.backgroundElevation2,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: _pngIcon('assets/icons/users.svg', colors.iconSub),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Rol boshqaruvi',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w700,
                            color: colors.textSub,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: colors.strokeSub),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Faol rol',
                                  style: TextStyle(fontSize: 12, color: colors.textSoft),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentRole.isNotEmpty ? _roleLabel(currentRole) : 'Tanlanmagan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w700,
                                    color: colors.textStrong,
                                  ),
                                ),
                              ],
                            ),
                            if (roles.length > 1)
                              GestureDetector(
                                onTap: () => _showRolePicker(context, roles, currentRole),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: colors.accentDisabled,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Almashtirish',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w700,
                                      color: colors.accentSub,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (roles.length > 1) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: roles.map((r) {
                              final isActive = r == currentRole;
                              return GestureDetector(
                                onTap: () async {
                                  if (!isActive) await RoleService.instance.setRole(r);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isActive ? colors.accentSub : colors.backgroundElevation2,
                                    borderRadius: BorderRadius.circular(20),
                                    border: isActive ? null : Border.all(color: colors.strokeSub),
                                  ),
                                  child: Text(
                                    _roleLabel(r),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? colors.textWhite : colors.textSub,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRolePicker(BuildContext context, List<String> roles, String currentRole) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rolni tanlang',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textStrong,
              ),
            ),
            const SizedBox(height: 16),
            ...roles.map((r) {
              final isActive = r == currentRole;
              return GestureDetector(
                onTap: () async {
                  Navigator.of(context).pop();
                  if (!isActive) await RoleService.instance.setRole(r);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isActive ? colors.accentSub : colors.backgroundElevation2,
                    borderRadius: BorderRadius.circular(14),
                    border: isActive ? null : Border.all(color: colors.strokeSub),
                  ),
                  child: Row(
                    children: [
                      _pngIcon(
                        'assets/icons/users.svg',
                        isActive ? colors.textWhite : colors.iconSub,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _roleLabel(r),
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isActive ? colors.textWhite : colors.textStrong,
                        ),
                      ),
                      if (isActive) ...[
                        const Spacer(),
                        Icon(Icons.check_rounded, color: colors.textWhite, size: 18),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme Switcher
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeSwitcher extends StatelessWidget {
  final AppColors colors;
  const _ThemeSwitcher({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, _) {
        final current = ThemeNotifier.instance.mode;
        return Container(
          decoration: BoxDecoration(
            color: colors.backgroundElevation1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.strokeSub),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.backgroundElevation2,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: _pngIcon('assets/icons/dashboard.svg', colors.iconSub),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Ko\'rinish',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        color: colors.textSub,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.strokeSub),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    _ThemeOption(
                      colors: colors,
                      label: 'Kunduz',
                      icon: Icons.wb_sunny_rounded,
                      selected: current == ThemeMode.light,
                      onTap: () => ThemeNotifier.instance.setMode(ThemeMode.light),
                    ),
                    _ThemeOption(
                      colors: colors,
                      label: 'Avtomatik',
                      icon: Icons.brightness_auto_rounded,
                      selected: current == ThemeMode.system,
                      onTap: () => ThemeNotifier.instance.setMode(ThemeMode.system),
                    ),
                    _ThemeOption(
                      colors: colors,
                      label: 'Tungi',
                      icon: Icons.nightlight_round,
                      selected: current == ThemeMode.dark,
                      onTap: () => ThemeNotifier.instance.setMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final AppColors colors;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.colors,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.accentSub : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : colors.iconSub),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : colors.textSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
