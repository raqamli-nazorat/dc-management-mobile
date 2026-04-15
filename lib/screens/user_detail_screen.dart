import 'package:cached_network_image/cached_network_image.dart';
import 'package:dcmanagement/api/api.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/user_model.dart';
import 'package:dcmanagement/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
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
    return _api.getUserDetail(token, widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundBase,
      appBar: AppBar(
        backgroundColor: colors.backgroundBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: colors.iconStrong),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Foydalanuvchi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.textStrong,
          ),
        ),
      ),
      body: FutureBuilder<UserModel>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colors.accentSub),
            );
          }
          if (snap.hasError) {
            final err = snap.error;
            if (err is ApiException && err.statusCode == 403) {
              return _NoPermissionView(onBack: () => context.pop());
            }
            return _ErrorView(
              message: snap.error.toString(),
              onRetry: () => setState(() => _future = _fetch()),
            );
          }
          return _DetailBody(user: snap.data!);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final UserModel user;
  const _DetailBody({required this.user});

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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Faol',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSub,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

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

          // ── Identity ─────────────────────────────────────────────────────
          _SectionTitle(title: 'Shaxsiy ma\'lumotlar', colors: colors),
          _card(
            colors: colors,
            child: _InfoRow(
              icon: Icons.badge_rounded,
              label: 'Pasport',
              value: user.passportSeries.isEmpty ? '—' : user.passportSeries,
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

          // ── Organization ─────────────────────────────────────────────────
          _SectionTitle(title: 'Tashkilot', colors: colors),
          _card(
            colors: colors,
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Viloyat ID',
                  value: user.region.toString(),
                  colors: colors,
                ),
                Divider(height: 20, color: colors.strokeSoft),
                _InfoRow(
                  icon: Icons.category_rounded,
                  label: 'Yo\'nalish ID',
                  value: user.direction.toString(),
                  colors: colors,
                ),
              ],
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
            errorWidget: (_, __, ___) => Text(
              user.initials,
              style: TextStyle(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.w600,
                color: colors.accentSub,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.accentDisabled,
      child: Text(
        user.initials,
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w600,
          color: colors.accentSub,
        ),
      ),
    );
  }
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

class _NoPermissionView extends StatelessWidget {
  final VoidCallback onBack;
  const _NoPermissionView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 52, color: colors.textSoft),
            const SizedBox(height: 14),
            Text(
              'Ruxsat yo\'q',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textStrong),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu foydalanuvchi ma\'lumotlarini ko\'rish uchun ruxsatingiz yo\'q.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSub),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: const Text('Orqaga'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

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
              "Ma'lumot yuklanmadi",
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
