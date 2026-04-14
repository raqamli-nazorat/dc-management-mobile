import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  // ── Base ──────────────────────────────────────────────────────────────
  final Color white;
  final Color black;

  // ── Background ────────────────────────────────────────────────────────
  final Color backgroundBase;
  final Color backgroundElevation1;
  final Color backgroundElevation1Alt;
  final Color backgroundElevation2;
  final Color backgroundElevation2Alt;
  final Color backgroundElevation3;
  final Color backgroundElevation3Alt;

  // ── Accent ────────────────────────────────────────────────────────────
  final Color accentStrong;
  final Color accentSub;
  final Color accentSoft;
  final Color accentDisabled;
  final Color accentWhite;

  // ── Text ──────────────────────────────────────────────────────────────
  final Color textStrong;
  final Color textSub;
  final Color textSoft;
  final Color textDisabled;
  final Color textWhite;
  final Color textAccent;
  final Color textInWhite;
  final Color textInDark;

  // ── Stroke ────────────────────────────────────────────────────────────
  final Color strokeStrong;
  final Color strokeSub;
  final Color strokeSoft;
  final Color strokeAccent;
  final Color strokeWhite;

  // ── Icon ──────────────────────────────────────────────────────────────
  final Color iconStrong;
  final Color iconSub;
  final Color iconSoft;
  final Color iconDisabled;
  final Color iconWhite;
  final Color iconAccent;
  final Color iconInWhite;
  final Color iconInBlack;

  // ── Error ─────────────────────────────────────────────────────────────
  final Color errorStrong;
  final Color errorSub;
  final Color errorSoft;
  final Color errorDisabled;

  const AppColors({
    required this.white,
    required this.black,
    required this.backgroundBase,
    required this.backgroundElevation1,
    required this.backgroundElevation1Alt,
    required this.backgroundElevation2,
    required this.backgroundElevation2Alt,
    required this.backgroundElevation3,
    required this.backgroundElevation3Alt,
    required this.accentStrong,
    required this.accentSub,
    required this.accentSoft,
    required this.accentDisabled,
    required this.accentWhite,
    required this.textStrong,
    required this.textSub,
    required this.textSoft,
    required this.textDisabled,
    required this.textWhite,
    required this.textAccent,
    required this.textInWhite,
    required this.textInDark,
    required this.strokeStrong,
    required this.strokeSub,
    required this.strokeSoft,
    required this.strokeAccent,
    required this.strokeWhite,
    required this.iconStrong,
    required this.iconSub,
    required this.iconSoft,
    required this.iconDisabled,
    required this.iconWhite,
    required this.iconAccent,
    required this.iconInWhite,
    required this.iconInBlack,
    required this.errorStrong,
    required this.errorSub,
    required this.errorSoft,
    required this.errorDisabled,
  });

  factory AppColors.light() => const AppColors(
        white: Color(0xFFFFFFFF),
        black: Color(0xFF000000),
        backgroundBase: Color(0xFFFFFFFF),
        backgroundElevation1: Color(0xFFF8F9FC),
        backgroundElevation1Alt: Color(0xFFF1F3F9),
        backgroundElevation2: Color(0xFFE9ECF5),
        backgroundElevation2Alt: Color(0xFFE2E6F2),
        backgroundElevation3: Color(0xFFDADFF0),
        backgroundElevation3Alt: Color(0xFFD2D8EC),
        accentStrong: Color(0xFF3F57B3),
        accentSub: Color(0xFF526ED3),
        accentSoft: Color(0xFF7F95E6),
        accentDisabled: Color(0xFFE9EEFF),
        accentWhite: Color(0xFFFFFFFF),
        textStrong: Color(0xFF1A1D2E),
        textSub: Color(0xFF5B6078),
        textSoft: Color(0xFF8F95A8),
        textDisabled: Color(0xFFB6BCCB),
        textWhite: Color(0xFFFFFFFF),
        textAccent: Color(0xFF526ED3),
        textInWhite: Color(0xFFFFFFFF),
        textInDark: Color(0xFF000000),
        strokeStrong: Color(0xFFD0D5E2),
        strokeSub: Color(0xFFE2E6F2),
        strokeSoft: Color(0xFFEEF1F7),
        strokeAccent: Color(0xFF526ED3),
        strokeWhite: Color(0xFFFFFFFF),
        iconStrong: Color(0xFF1A1D2E),
        iconSub: Color(0xFF5B6078),
        iconSoft: Color(0xFF9AA1B5),
        iconDisabled: Color(0xFFC5CAD8),
        iconWhite: Color(0xFFFFFFFF),
        iconAccent: Color(0xFF526ED3),
        iconInWhite: Color(0xFFFFFFFF),
        iconInBlack: Color(0xFF000000),
        errorStrong: Color(0xFFE02D2D),
        errorSub: Color(0xFFFA5252),
        errorSoft: Color(0xFFFFF2F2),
        errorDisabled: Color(0xFFF8D7DA),
      );

  factory AppColors.dark() => const AppColors(
        white: Color(0xFF000000),
        black: Color(0xFFFFFFFF),
        backgroundBase: Color(0xFF111111),
        backgroundElevation1: Color(0xFF191A1A),
        backgroundElevation1Alt: Color(0xFF222323),
        backgroundElevation2: Color(0xFF292A2A),
        backgroundElevation2Alt: Color(0xFF303131),
        backgroundElevation3: Color(0xFF3A3B3B),
        backgroundElevation3Alt: Color(0xFF474848),
        accentStrong: Color(0xFF3F57B3),
        accentSub: Color(0xFF526ED3),
        accentSoft: Color(0xFF7F95E6),
        accentDisabled: Color(0xFFE9EEFF),
        accentWhite: Color(0xFFFFFFFF),
        textStrong: Color(0xFFFFFFFF),
        textSub: Color(0xFFC2C8E0),
        textSoft: Color(0xFF8E95B5),
        textDisabled: Color(0xFF5C627D),
        textWhite: Color(0xFFFFFFFF),
        textAccent: Color(0xFF7F95E6),
        textInWhite: Color(0xFFFFFFFF),
        textInDark: Color(0xFF000000),
        strokeStrong: Color(0xFF191A1A),
        strokeSub: Color(0xFF292A2A),
        strokeSoft: Color(0xFF474848),
        strokeAccent: Color(0xFF7F95E6),
        strokeWhite: Color(0xFFFFFFFF),
        iconStrong: Color(0xFFFFFFFF),
        iconSub: Color(0xFFC2C8E0),
        iconSoft: Color(0xFF8E95B5),
        iconDisabled: Color(0xFF5C627D),
        iconWhite: Color(0xFFFFFFFF),
        iconAccent: Color(0xFF7F95E6),
        iconInWhite: Color(0xFFFFFFFF),
        iconInBlack: Color(0xFF000000),
        errorStrong: Color(0xFFE02D2D),
        errorSub: Color(0xFFFA5252),
        errorSoft: Color(0xFFFFF2F2),
        errorDisabled: Color(0xFFF8D7DA),
      );

  /// Access from anywhere: `Theme.of(context).extension<AppColors>()!`
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? white,
    Color? black,
    Color? backgroundBase,
    Color? backgroundElevation1,
    Color? backgroundElevation1Alt,
    Color? backgroundElevation2,
    Color? backgroundElevation2Alt,
    Color? backgroundElevation3,
    Color? backgroundElevation3Alt,
    Color? accentStrong,
    Color? accentSub,
    Color? accentSoft,
    Color? accentDisabled,
    Color? accentWhite,
    Color? textStrong,
    Color? textSub,
    Color? textSoft,
    Color? textDisabled,
    Color? textWhite,
    Color? textAccent,
    Color? textInWhite,
    Color? textInDark,
    Color? strokeStrong,
    Color? strokeSub,
    Color? strokeSoft,
    Color? strokeAccent,
    Color? strokeWhite,
    Color? iconStrong,
    Color? iconSub,
    Color? iconSoft,
    Color? iconDisabled,
    Color? iconWhite,
    Color? iconAccent,
    Color? iconInWhite,
    Color? iconInBlack,
    Color? errorStrong,
    Color? errorSub,
    Color? errorSoft,
    Color? errorDisabled,
  }) =>
      AppColors(
        white: white ?? this.white,
        black: black ?? this.black,
        backgroundBase: backgroundBase ?? this.backgroundBase,
        backgroundElevation1: backgroundElevation1 ?? this.backgroundElevation1,
        backgroundElevation1Alt:
            backgroundElevation1Alt ?? this.backgroundElevation1Alt,
        backgroundElevation2: backgroundElevation2 ?? this.backgroundElevation2,
        backgroundElevation2Alt:
            backgroundElevation2Alt ?? this.backgroundElevation2Alt,
        backgroundElevation3: backgroundElevation3 ?? this.backgroundElevation3,
        backgroundElevation3Alt:
            backgroundElevation3Alt ?? this.backgroundElevation3Alt,
        accentStrong: accentStrong ?? this.accentStrong,
        accentSub: accentSub ?? this.accentSub,
        accentSoft: accentSoft ?? this.accentSoft,
        accentDisabled: accentDisabled ?? this.accentDisabled,
        accentWhite: accentWhite ?? this.accentWhite,
        textStrong: textStrong ?? this.textStrong,
        textSub: textSub ?? this.textSub,
        textSoft: textSoft ?? this.textSoft,
        textDisabled: textDisabled ?? this.textDisabled,
        textWhite: textWhite ?? this.textWhite,
        textAccent: textAccent ?? this.textAccent,
        textInWhite: textInWhite ?? this.textInWhite,
        textInDark: textInDark ?? this.textInDark,
        strokeStrong: strokeStrong ?? this.strokeStrong,
        strokeSub: strokeSub ?? this.strokeSub,
        strokeSoft: strokeSoft ?? this.strokeSoft,
        strokeAccent: strokeAccent ?? this.strokeAccent,
        strokeWhite: strokeWhite ?? this.strokeWhite,
        iconStrong: iconStrong ?? this.iconStrong,
        iconSub: iconSub ?? this.iconSub,
        iconSoft: iconSoft ?? this.iconSoft,
        iconDisabled: iconDisabled ?? this.iconDisabled,
        iconWhite: iconWhite ?? this.iconWhite,
        iconAccent: iconAccent ?? this.iconAccent,
        iconInWhite: iconInWhite ?? this.iconInWhite,
        iconInBlack: iconInBlack ?? this.iconInBlack,
        errorStrong: errorStrong ?? this.errorStrong,
        errorSub: errorSub ?? this.errorSub,
        errorSoft: errorSoft ?? this.errorSoft,
        errorDisabled: errorDisabled ?? this.errorDisabled,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      white: Color.lerp(white, other.white, t)!,
      black: Color.lerp(black, other.black, t)!,
      backgroundBase: Color.lerp(backgroundBase, other.backgroundBase, t)!,
      backgroundElevation1:
          Color.lerp(backgroundElevation1, other.backgroundElevation1, t)!,
      backgroundElevation1Alt:
          Color.lerp(backgroundElevation1Alt, other.backgroundElevation1Alt, t)!,
      backgroundElevation2:
          Color.lerp(backgroundElevation2, other.backgroundElevation2, t)!,
      backgroundElevation2Alt:
          Color.lerp(backgroundElevation2Alt, other.backgroundElevation2Alt, t)!,
      backgroundElevation3:
          Color.lerp(backgroundElevation3, other.backgroundElevation3, t)!,
      backgroundElevation3Alt:
          Color.lerp(backgroundElevation3Alt, other.backgroundElevation3Alt, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentSub: Color.lerp(accentSub, other.accentSub, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentDisabled: Color.lerp(accentDisabled, other.accentDisabled, t)!,
      accentWhite: Color.lerp(accentWhite, other.accentWhite, t)!,
      textStrong: Color.lerp(textStrong, other.textStrong, t)!,
      textSub: Color.lerp(textSub, other.textSub, t)!,
      textSoft: Color.lerp(textSoft, other.textSoft, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textWhite: Color.lerp(textWhite, other.textWhite, t)!,
      textAccent: Color.lerp(textAccent, other.textAccent, t)!,
      textInWhite: Color.lerp(textInWhite, other.textInWhite, t)!,
      textInDark: Color.lerp(textInDark, other.textInDark, t)!,
      strokeStrong: Color.lerp(strokeStrong, other.strokeStrong, t)!,
      strokeSub: Color.lerp(strokeSub, other.strokeSub, t)!,
      strokeSoft: Color.lerp(strokeSoft, other.strokeSoft, t)!,
      strokeAccent: Color.lerp(strokeAccent, other.strokeAccent, t)!,
      strokeWhite: Color.lerp(strokeWhite, other.strokeWhite, t)!,
      iconStrong: Color.lerp(iconStrong, other.iconStrong, t)!,
      iconSub: Color.lerp(iconSub, other.iconSub, t)!,
      iconSoft: Color.lerp(iconSoft, other.iconSoft, t)!,
      iconDisabled: Color.lerp(iconDisabled, other.iconDisabled, t)!,
      iconWhite: Color.lerp(iconWhite, other.iconWhite, t)!,
      iconAccent: Color.lerp(iconAccent, other.iconAccent, t)!,
      iconInWhite: Color.lerp(iconInWhite, other.iconInWhite, t)!,
      iconInBlack: Color.lerp(iconInBlack, other.iconInBlack, t)!,
      errorStrong: Color.lerp(errorStrong, other.errorStrong, t)!,
      errorSub: Color.lerp(errorSub, other.errorSub, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      errorDisabled: Color.lerp(errorDisabled, other.errorDisabled, t)!,
    );
  }
}
