import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/user_model.dart';
import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    this.onTap,
  });

  final UserModel user;
  final VoidCallback? onTap;

  String _formatNumber(String raw) {
    final value = double.tryParse(raw);
    if (value == null) return raw;
    // Format: 12 000 000,00
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('\u00A0'); // non-breaking space
      buffer.write(intPart[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()},${decPart}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final initials = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeSub, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name/lavozim + checkmark
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.strokeSub,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textSub,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + Lavozim
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Ism sharifi:  ',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSub,
                              ),
                            ),
                            TextSpan(
                              text: user.username,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textStrong,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Lavozimi:  ',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSub,
                              ),
                            ),
                            TextSpan(
                              text: user.role.isNotEmpty ? _capitalize(user.role) : '—',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.textStrong,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Rol
            _InfoRow(
              label: 'Rol:',
              value: user.role.isNotEmpty ? user.role : '—',
              colors: colors,
              valueBold: true,
            ),

            // Oylik maoshi
            _InfoRow(
              label: 'Oylik maoshi:',
              value: _formatNumber(user.fixedSalary),
              colors: colors,
              valueBold: true,
            ),

            // Balansi + checkmark
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    label: 'Balansi:',
                    value: _formatNumber(user.balance ?? '0'),
                    colors: colors,
                    valueBold: true,
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.successStrong.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check,
                    color: colors.successStrong,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final AppColors colors;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(
                fontSize: 13,
                color: colors.textSub,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: valueBold ? FontWeight.w700 : FontWeight.w400,
                color: colors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}