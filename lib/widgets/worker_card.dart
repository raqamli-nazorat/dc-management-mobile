import 'package:flutter/material.dart';
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/user_model.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const UserCard({super.key, required this.user, this.onTap});

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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeSub),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.accentDisabled,
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colors.accentSub,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.textStrong,
                        ),
                      ),
                      Text(
                        user.phoneNumber,
                        style: TextStyle(fontSize: 12, color: colors.textSub),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accentDisabled,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.accentSub,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(context, 'Maosh:', _formatMoney(user.fixedSalary)),
            _infoRow(context, 'Balans:', _formatMoney(user.balance)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label ',
            style: TextStyle(fontSize: 13, color: colors.textSub),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}
