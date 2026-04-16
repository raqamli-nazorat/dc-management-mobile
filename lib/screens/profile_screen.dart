import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/user_model.dart';
import 'package:dcmanagement/providers/theme_notifier.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
        title: Text('Chiqish',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: colors.textStrong)),
        content: Text('Hisobdan chiqmoqchimisiz?',
            style: TextStyle(color: colors.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Bekor qilish',
                style: TextStyle(color: colors.textSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Chiqish',
                style: TextStyle(color: Color(0xFFEF4444))),
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
      final parts = val.toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final decPart = parts[1];
      final buffer = StringBuffer();
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) buffer.write('\u00A0');
        buffer.write(intPart[i]);
        count++;
      }
      return '${buffer.toString().split('').reversed.join()},$decPart';
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
                        child: CircularProgressIndicator(
                            color: colors.accentSub));
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text(snap.error.toString(),
                            style: TextStyle(color: colors.textSub)));
                  }
                  return _buildBody(snap.data!, colors);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(UserModel user, AppColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Avatar card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.backgroundElevation1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.strokeSub),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.accentDisabled,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      fontSize: 26,
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
                    fontWeight: FontWeight.w700,
                    color: colors.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accentDisabled,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.accentSub,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Info
          _InfoCard(colors: colors, children: [
            _InfoRow(
              icon: LucideIcons.phone,
              label: 'Telefon',
              value: user.phoneNumber.isEmpty ? '—' : user.phoneNumber,
              colors: colors,
            ),
            Divider(height: 20, color: colors.strokeSoft),
            _InfoRow(
              icon: LucideIcons.badgeCheck,
              label: 'Pasport',
              value: user.passportSeries.isEmpty ? '—' : user.passportSeries,
              colors: colors,
            ),
          ]),

          const SizedBox(height: 12),

          // Financials
          _InfoCard(colors: colors, children: [
            _InfoRow(
              icon: LucideIcons.banknote,
              label: 'Oylik maosh',
              value: _formatMoney(user.fixedSalary),
              colors: colors,
            ),
            Divider(height: 20, color: colors.strokeSoft),
            _InfoRow(
              icon: LucideIcons.wallet,
              label: 'Balans',
              value: _formatMoney(user.balance),
              colors: colors,
            ),
          ]),

          const SizedBox(height: 12),

          // Theme switcher
          _ThemeSwitcher(colors: colors),

          const SizedBox(height: 24),

          // Logout
          GestureDetector(
            onTap: _logout,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.logOut, size: 18, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text(
                    'Chiqish',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.backgroundElevation1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.strokeSub),
          ),
          child: Row(
            children: [
              _ThemeOption(
                colors: colors,
                icon: LucideIcons.sun,
                label: 'Kunduz',
                selected: current == ThemeMode.light,
                onTap: () =>
                    ThemeNotifier.instance.setMode(ThemeMode.light),
              ),
              _ThemeOption(
                colors: colors,
                icon: LucideIcons.monitor,
                label: 'Avtomatik',
                selected: current == ThemeMode.system,
                onTap: () =>
                    ThemeNotifier.instance.setMode(ThemeMode.system),
              ),
              _ThemeOption(
                colors: colors,
                icon: LucideIcons.moon,
                label: 'Tungi',
                selected: current == ThemeMode.dark,
                onTap: () =>
                    ThemeNotifier.instance.setMode(ThemeMode.dark),
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

  static const _accent = Color(0xFF5B6EF5);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : colors.iconSub,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
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

// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final AppColors colors;
  final List<Widget> children;
  const _InfoCard({required this.colors, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSub),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColors colors;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.backgroundElevation2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colors.iconSub),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: colors.textSoft)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textStrong,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}