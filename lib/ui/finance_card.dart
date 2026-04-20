// widgets/finance_card.dart
import 'package:dcmanagement/colors/app_colors.dart';
import 'package:flutter/material.dart';

class FinanceCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isWide;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;
  final double? cardHeight;
  final double? imageWidth;
  final double? imageHeight;
  final VoidCallback? onTap;

  const FinanceCard({
    super.key,
    required this.title,
    required this.imagePath,
    this.isWide = false,
    this.fontSize,
    this.fontWeight,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.cardHeight,
    this.imageWidth,
    this.imageHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final double imgW = imageWidth ?? (isWide ? 90.0 : 70.0);
    final double imgH = imageHeight ?? (isWide ? 90.0 : 70.0);
    final double height = cardHeight ?? (isWide ? 110.0 : 90.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.backgroundElevation2Alt,
          borderRadius: BorderRadius.circular(borderRadius ?? 18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize ?? 15,
                    fontWeight: fontWeight ?? FontWeight.w700,
                    color: textColor ?? colors.textStrong,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              Image.asset(
                imagePath,
                width: imgW,
                height: imgH,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}