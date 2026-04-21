import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';

// ── ThrottleCountdown ─────────────────────────────────────────────────────────
// Shown when the API returns 429 Too Many Requests.
// Pass the remaining [seconds] from the parent's countdown timer.

class ThrottleCountdown extends StatelessWidget {
  final int seconds;
  final AppColors colors;

  const ThrottleCountdown({
    super.key,
    required this.seconds,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.errorSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.access_time_rounded,
                color: colors.errorSub,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Juda ko'p so'rov yuborildi",
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: colors.textStrong,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Iltimos qayta urinib ko'ring",
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textSub,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: colors.backgroundElevation2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.strokeSub),
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$seconds',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: colors.errorSub,
                      ),
                    ),
                    TextSpan(
                      text: ' soniya',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ErrorRetry ────────────────────────────────────────────────────────────────
// Generic error state with a "Qayta urinish" button.

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppColors colors;

  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.errorSub, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w500,
                color: colors.textSub,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentSub,
                foregroundColor: colors.textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Qayta urinish',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
