import 'package:dcmanagement/colors/app_colors.dart';
import 'package:dcmanagement/models/ledger_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LedgerCard extends StatelessWidget {
  final LedgerModel entry;
  final VoidCallback? onTap;

  const LedgerCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final double amountValue = double.tryParse(entry.amount) ?? 0;

    final formattedAmount = NumberFormat(
      "#,##0",
      "uz_UZ",
    ).format(amountValue).replaceAll(',', ' ');

    final date = DateFormat('dd.MM.yyyy').format(entry.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.backgroundElevation1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.strokeSub),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.backgroundBase,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                entry.description.isNotEmpty
                    ? entry.description[0].toUpperCase()
                    : 'A',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textSub,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Main text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ism sharifi: ${entry.description}",
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textStrong,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Turi: ${_getType()}",
                    style: TextStyle(fontSize: 13, color: colors.textSub),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "Miqdor: ",
                        style: TextStyle(fontSize: 14, color: colors.textSub),
                      ),
                      Text(
                        formattedAmount,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textStrong,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Sana: $date",
                    style: TextStyle(fontSize: 12, color: colors.textSub),
                  ),
                ],
              ),
            ),
            // Right check icon - exact match to image
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.successStrong,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check, size: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  String _getType() {
    if (entry.expense != null) return 'Xizmatlar';
    if (entry.payroll != null) return 'Ish haqi';
    return 'Savdo';
  }
}
