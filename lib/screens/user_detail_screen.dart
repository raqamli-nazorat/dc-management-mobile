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

    try {
      return await _api.getUserDetail(token, widget.userId);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        return await _api.getMe(token);
      }
      rethrow;
    }
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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: colors.iconStrong,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Foydalanuvchining ma'lumotlari",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
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

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year;
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d.$m.$y  $h:$min';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Center(child: _Avatar(user: user, radius: 48)),
          const SizedBox(height: 20),

          // Ism Sharifi
          _FieldLabel(label: 'Ism Sharifi', colors: colors),
          _FieldBox(value: user.username, colors: colors),
          const SizedBox(height: 12),

          // Yaratilgan vaqt
          _FieldLabel(label: 'Yaratilgan vaqt', colors: colors),
          _FieldBox(value: _formatDate(user.dateJoined), colors: colors),
          const SizedBox(height: 12),

          // Oylik maosh + Balansi (2 column)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Oylik maosh', colors: colors),
                    _FieldBox(
                      value: _formatMoney(user.fixedSalary),
                      colors: colors,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Balansi', colors: colors),
                    _FieldBox(
                      value: _formatMoney(user.balance),
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Viloyat + Tuman (2 column)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Viloyat', colors: colors),
                    _DropdownBox(
                      value: user.region != null
                          ? 'Viloyat ${user.region}'
                          : "Noma'lum",
                      colors: colors,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Tuman', colors: colors),
                    _DropdownBox(
                      value: user.direction != null
                          ? 'Tuman ${user.direction}'
                          : "Noma'lum",
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Passport ma'lumotlari
          _FieldLabel(label: "Passport ma'lumotlari", colors: colors),
          Container(
            decoration: BoxDecoration(
              color: colors.backgroundElevation1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.strokeSub),
            ),
            child: Row(
              children: [
                // Seriya (AA)
                Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: colors.strokeSub, width: 1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.passportSeries.length >= 2
                        ? user.passportSeries.substring(0, 2)
                        : user.passportSeries.isEmpty
                        ? '—'
                        : user.passportSeries,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textStrong,
                    ),
                  ),
                ),
                // Raqam
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      user.passportSeries.length > 2
                          ? user.passportSeries.substring(2)
                          : '—',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.textStrong,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Passport rasmi
          _FieldLabel(label: 'Passport rasmi', colors: colors),
          _PassportImageBox(user: user, colors: colors),
          const SizedBox(height: 12),

          // Lavozimi
          _RoleRow(
            dotColor: colors.successStrong,
            label: 'Lavozimi',
            value: user.roleLabel,
            colors: colors,
          ),
          const SizedBox(height: 10),

          // Rolli
          _RoleRow(
            dotColor: AppColors.of(context).errorSub,
            label: 'Rolli',
            value: user.role.isEmpty ? 'Tanlash' : user.roleLabel,
            isPlaceholder: user.role.isEmpty,
            colors: colors,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final AppColors colors;
  const _FieldLabel({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colors.textSub,
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final String value;
  final AppColors colors;
  const _FieldBox({required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.strokeSub),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colors.textStrong,
        ),
      ),
    );
  }
}

class _DropdownBox extends StatelessWidget {
  final String value;
  final AppColors colors;
  const _DropdownBox({required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.strokeSub),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textStrong,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: colors.iconSub,
          ),
        ],
      ),
    );
  }
}

class _PassportImageBox extends StatelessWidget {
  final UserModel user;
  final AppColors colors;
  const _PassportImageBox({required this.user, required this.colors});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        user.passportImage != null && user.passportImage!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.strokeSub, style: BorderStyle.solid),
      ),
      child: hasImage
          ? Row(
              children: [
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 18,
                  color: colors.iconSub,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Ma'lumot.pdf",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textStrong,
                    ),
                  ),
                ),
                Text(
                  '1487 Kb',
                  style: TextStyle(fontSize: 12, color: colors.textSoft),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file_outlined,
                  size: 18,
                  color: colors.textSoft,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fayl yuklanmagan',
                  style: TextStyle(fontSize: 13, color: colors.textSoft),
                ),
              ],
            ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;
  final bool isPlaceholder;
  final AppColors colors;

  const _RoleRow({
    required this.dotColor,
    required this.label,
    required this.value,
    required this.colors,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.backgroundElevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.strokeSub),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textStrong,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: colors.backgroundBase,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.strokeSub),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isPlaceholder ? colors.textSoft : colors.textStrong,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: colors.iconSub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  const _Avatar({required this.user, required this.radius});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (user.avatar != null && user.avatar!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius * 0.4),
        child: CachedNetworkImage(
          imageUrl: user.avatar!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              _InitialsAvatar(user: user, radius: radius, colors: colors),
        ),
      );
    }

    return _InitialsAvatar(user: user, radius: radius, colors: colors);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  final AppColors colors;
  const _InitialsAvatar({
    required this.user,
    required this.radius,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: colors.accentDisabled,
        borderRadius: BorderRadius.circular(radius * 0.4),
      ),
      alignment: Alignment.center,
      child: Text(
        user.initials,
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w700,
          color: colors.accentSub,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
                color: colors.textStrong,
              ),
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
                fontWeight: FontWeight.w600,
                color: colors.textStrong,
              ),
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
  