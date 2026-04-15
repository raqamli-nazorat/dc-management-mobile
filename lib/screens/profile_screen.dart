import 'package:cached_network_image/cached_network_image.dart';
import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/user_model.dart';
import 'package:dcmanagement/providers/theme_notifier.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:dcmanagement/services/pin_session.dart';
import 'package:dcmanagement/services/storage_service.dart';
import 'package:dcmanagement/widgets/pin_setup_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _SignOutDialog(),
    );
    if (confirmed == true && mounted) {
      PinSession.instance.reset();
      await _auth.signOut();
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      body: SafeArea(
        child: FutureBuilder<UserModel>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: colors.accentSub),
              );
            }
            if (snap.hasError) {
              return _ErrorRetry(
                message: snap.error.toString(),
                onRetry: () => setState(() => _future = _fetch()),
              );
            }
            return _ProfileBody(
              user: snap.data!,
              onSignOut: _signOut,
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final UserModel user;
  final VoidCallback onSignOut;
  const _ProfileBody({required this.user, required this.onSignOut});

  String _formatMoney(String raw) {
    try {
      final val = double.parse(raw);
      final isNeg = val < 0;
      final abs = val.abs().toStringAsFixed(0);
      final formatted = abs.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[0]} ',
      );
      return "${isNeg ? '-' : ''}$formatted so'm";
    } catch (_) {
      return raw;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd.MM.yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page title ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Mening Profilim',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textStrong,
              ),
            ),
          ),

          // ── Header card ──────────────────────────────────────────────────
          _card(
            colors: colors,
            child: Column(
              children: [
                _Avatar(user: user, radius: 40),
                const SizedBox(height: 12),
                Text(
                  user.username,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textStrong,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (user.isActive ?? true)
                            ? const Color(0xFFDCFCE7)
                            : colors.errorSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: (user.isActive ?? true)
                                  ? const Color(0xFF22C55E)
                                  : colors.errorSub,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            (user.isActive ?? true) ? 'Faol' : 'Faol emas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: (user.isActive ?? true)
                                  ? const Color(0xFF16A34A)
                                  : colors.errorSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Change password warning ───────────────────────────────────────
          if (user.changePassword == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_reset_rounded,
                      color: Color(0xFFEA580C), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Xavfsizlik uchun parolingizni yangilash tavsiya etiladi.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Contact ───────────────────────────────────────────────────────
          _SectionTitle(title: 'Aloqa', colors: colors),
          _card(
            colors: colors,
            child: _InfoRow(
              icon: Icons.phone_rounded,
              label: 'Telefon',
              value: user.phoneNumber.isEmpty ? '—' : user.phoneNumber,
              colors: colors,
            ),
          ),

          const SizedBox(height: 12),

          // ── Financials ───────────────────────────────────────────────────
          _SectionTitle(title: 'Moliyaviy', colors: colors),
          _card(
            colors: colors,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.payments_rounded,
                  label: 'Maosh',
                  value: _formatMoney(user.fixedSalary),
                  colors: colors,
                ),
                Divider(height: 20, color: colors.strokeSoft),
                _InfoRow(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Balans',
                  value: _formatMoney(user.balance),
                  colors: colors,
                  valueColor: double.tryParse(user.balance) != null &&
                          double.parse(user.balance) < 0
                      ? const Color(0xFFE02D2D)
                      : const Color(0xFF22C55E),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Account ───────────────────────────────────────────────────────
          _SectionTitle(title: 'Hisob', colors: colors),
          _card(
            colors: colors,
            child: _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: "Ro'yxatdan o'tgan sana",
              value: _formatDate(user.dateJoined),
              colors: colors,
            ),
          ),

          const SizedBox(height: 12),

          // ── Theme toggle ─────────────────────────────────────────────────
          _SectionTitle(title: "Ko'rinish", colors: colors),
          _ThemeToggle(),

          const SizedBox(height: 12),

          // ── PIN code ─────────────────────────────────────────────────────
          _SectionTitle(title: 'Xavfsizlik', colors: colors),
          _PinSection(),

          const SizedBox(height: 20),

          // ── Sign out ─────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: Icon(Icons.logout_rounded, color: colors.errorSub),
              label: Text(
                'Chiqish',
                style: TextStyle(color: colors.errorSub),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.errorSub),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _card({required AppColors colors, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSub),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme toggle — 3-way segmented control
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, _) {
        final colors = AppColors.of(context);
        final current = ThemeNotifier.instance.mode;

        return Container(
          decoration: BoxDecoration(
            color: colors.backgroundElevation1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.strokeSub),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _ThemeOption(
                mode: ThemeMode.system,
                icon: Icons.brightness_auto_rounded,
                label: 'Sistema',
                current: current,
                colors: colors,
              ),
              _ThemeOption(
                mode: ThemeMode.light,
                icon: Icons.light_mode_rounded,
                label: 'Kunduz',
                current: current,
                colors: colors,
              ),
              _ThemeOption(
                mode: ThemeMode.dark,
                icon: Icons.dark_mode_rounded,
                label: 'Kech',
                current: current,
                colors: colors,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final ThemeMode mode;
  final IconData icon;
  final String label;
  final ThemeMode current;
  final AppColors colors;

  const _ThemeOption({
    required this.mode,
    required this.icon,
    required this.label,
    required this.current,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == current;

    return Expanded(
      child: GestureDetector(
        onTap: () => ThemeNotifier.instance.setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : colors.iconSub,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : colors.textSub,
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
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  const _Avatar({required this.user, required this.radius});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (user.avatar != null && user.avatar!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colors.accentDisabled,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: user.avatar!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _initials(colors),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.accentDisabled,
      child: _initials(colors),
    );
  }

  Widget _initials(AppColors colors) => Text(
        user.initials,
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w600,
          color: colors.accentSub,
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final AppColors colors;
  const _SectionTitle({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.textSoft,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColors colors;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
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
              Text(
                label,
                style: TextStyle(fontSize: 12, color: colors.textSoft),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? colors.textStrong,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN section
// ─────────────────────────────────────────────────────────────────────────────

class _PinSection extends StatefulWidget {
  const _PinSection();

  @override
  State<_PinSection> createState() => _PinSectionState();
}

class _PinSectionState extends State<_PinSection> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool(StorageService.pinEnabledKey) ?? false;
      _loading = false;
    });
  }

  Future<void> _onToggle(bool value) async {
    if (value) {
      // Turn ON — ask user to set a PIN
      final pin = await PinSetupSheet.show(context);
      if (pin == null) return; // user cancelled
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageService.pinKey, pin);
      await prefs.setBool(StorageService.pinEnabledKey, true);
      setState(() => _enabled = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN kod muvaffaqiyatli o\'rnatildi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Turn OFF — remove PIN
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageService.pinKey);
      await prefs.setBool(StorageService.pinEnabledKey, false);
      setState(() => _enabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.strokeSub),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.backgroundElevation2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.pin_outlined,
              size: 18,
              color: colors.iconSub,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PIN kod',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textStrong,
                  ),
                ),
                Text(
                  _loading
                      ? '...'
                      : _enabled
                          ? 'Yoqilgan — ilova himoyalangan'
                          : 'O\'chirilgan',
                  style: TextStyle(fontSize: 12, color: colors.textSoft),
                ),
              ],
            ),
          ),
          if (_loading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.accentSub,
              ),
            )
          else
            Switch(
              value: _enabled,
              onChanged: _onToggle,
              activeColor: colors.accentSub,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.errorSub),
            const SizedBox(height: 12),
            Text(
              "Profil yuklanmadi",
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: colors.textStrong),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSub),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta urinish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSub,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AlertDialog(
      backgroundColor: colors.backgroundElevation1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Chiqishni tasdiqlang',
        style: TextStyle(color: colors.textStrong, fontWeight: FontWeight.w600),
      ),
      content: Text(
        'Hisobdan chiqmoqchimisiz?',
        style: TextStyle(color: colors.textSub),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Bekor qilish', style: TextStyle(color: colors.textSub)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Chiqish',
              style: TextStyle(
                  color: colors.errorSub, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
