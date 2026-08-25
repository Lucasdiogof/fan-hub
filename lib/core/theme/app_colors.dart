import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.darkGreen,
    required this.deepGreen,
    required this.ctaGreen,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.error,
    required this.success,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color primary;
  final Color onPrimary;
  final Color secondary;

  /// Verdes mais escuros para elementos especiais (hero, banners) — não usar
  /// como cor de fundo geral da UI.
  final Color darkGreen;
  final Color deepGreen;

  /// Verde vívido reservado para CTAs de destaque sobre fundos escuros
  /// (ex.: "Comprar ingresso" no Hero) — mais aceso que [success], que fica
  /// reservado para estados de confirmação.
  final Color ctaGreen;
  final Color gold;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color error;
  final Color success;

  static const light = AppColors(
    background: Color(0xFFF6F8F7),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    primary: Color(0xFF004C1B),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFFE6F0E9),
    darkGreen: Color(0xFF003712),
    deepGreen: Color(0xFF00280D),
    ctaGreen: Color(0xFF169447),
    gold: Color(0xFFC79A3D),
    textPrimary: Color(0xFF121815),
    textSecondary: Color(0xFF5E6963),
    textHint: Color(0xFF98A19C),
    border: Color(0xFFE0E6E3),
    // Nunca vermelho em nenhum componente do app — âmbar/dourado (mesmo
    // tom do token `gold`) representa erro/falha em toda a UI.
    error: Color(0xFFC79A3D),
    success: Color(0xFF278A52),
  );

  static const dark = AppColors(
    background: Color(0xFF09110C),
    surface: Color(0xFF111A14),
    surfaceRaised: Color(0xFF17231C),
    primary: Color(0xFF29A85C),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF17271C),
    darkGreen: Color(0xFF003712),
    deepGreen: Color(0xFF00280D),
    ctaGreen: Color(0xFF1EB157),
    gold: Color(0xFFD9B25C),
    textPrimary: Color(0xFFF4F7F5),
    textSecondary: Color(0xFFAAB5AF),
    textHint: Color(0xFF707B75),
    border: Color(0xFF26342B),
    error: Color(0xFFD9B25C),
    success: Color(0xFF4CC37A),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? darkGreen,
    Color? deepGreen,
    Color? ctaGreen,
    Color? gold,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? error,
    Color? success,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      darkGreen: darkGreen ?? this.darkGreen,
      deepGreen: deepGreen ?? this.deepGreen,
      ctaGreen: ctaGreen ?? this.ctaGreen,
      gold: gold ?? this.gold,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      darkGreen: Color.lerp(darkGreen, other.darkGreen, t)!,
      deepGreen: Color.lerp(deepGreen, other.deepGreen, t)!,
      ctaGreen: Color.lerp(ctaGreen, other.ctaGreen, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
