import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Shared label + value text row used across list cards.
/// [valueBold] defaults to true (w900); set false for w500.
class InfoRow extends StatelessWidget {
  final AppColors colors;
  final String label;
  final String value;
  final bool valueBold;

  const InfoRow({
    super.key,
    required this.colors,
    required this.label,
    required this.value,
    this.valueBold = true,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: colors.textSub,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: valueBold ? FontWeight.w900 : FontWeight.w500,
              fontSize: 13,
              color: colors.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}
