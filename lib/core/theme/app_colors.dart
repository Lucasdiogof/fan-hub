import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.brandDark,
    required this.brandDeep,
    required this.cta,
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

  /// Tom profundo da marca pra elementos especiais (hero, banners) — não
  /// usar como cor de fundo geral da UI. No Goiás é verde-escuro; em outro
  /// clube é a cor profunda que a identidade dele definir (ex.: o
  /// azul-marinho do escudo do Bragantino) — por isso o nome não carrega
  /// "green": um `ctaGreen` vermelho ficaria estranho de ler no código.
  final Color brandDark;
  final Color brandDeep;

  /// Cor de CTA de destaque (ex.: "Comprar ingresso", botão de entrar) —
  /// preenchimento sólido nos dois temas, sem borda. No dark theme é uma
  /// variante mais vívida que `primary`/`brandDark` de propósito (escolhido
  /// comparando variantes lado a lado) — é a cor de ação principal do app,
  /// então precisa se destacar mais que o resto da paleta sóbria do dark
  /// theme. Ver `matchCtaFilledStyle`/`ctaButtonStyle` em
  /// `app_button_styles.dart` e `AppPrimaryButton`.
  final Color cta;
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
    brandDark: Color(0xFF003712),
    brandDeep: Color(0xFF00280D),
    cta: Color(0xFF169447),
    gold: Color(0xFFA9822E),
    textPrimary: Color(0xFF121815),
    textSecondary: Color(0xFF5E6963),
    textHint: Color(0xFF98A19C),
    border: Color(0xFFE0E6E3),
    // Nunca vermelho em nenhum componente do app — âmbar/dourado (mesmo
    // tom do token `gold`) representa erro/falha em toda a UI.
    error: Color(0xFFA9822E),
    success: Color(0xFF278A52),
  );

  // Verdes bem mais escuros/sóbrios que antes — o dark theme deve lembrar
  // um verde-esmeralda quase preto, não um verde neon sobre fundo escuro.
  // primary/ctaGreen/success eram #29A85C/#1EB157/#4CC37A (vívidos demais
  // sobre um fundo já verde-escuro); darkGreen/deepGreen/gold/error não
  // mudaram — já estavam sóbrios.
  static const dark = AppColors(
    background: Color(0xFF09110C),
    surface: Color(0xFF111A14),
    surfaceRaised: Color(0xFF17231C),
    primary: Color(0xFF1F8A4D),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF17271C),
    brandDark: Color(0xFF003712),
    brandDeep: Color(0xFF00280D),
    cta: Color(0xFF2FA968),
    gold: Color(0xFFB8904A),
    textPrimary: Color(0xFFF4F7F5),
    textSecondary: Color(0xFFAAB5AF),
    textHint: Color(0xFF707B75),
    border: Color(0xFF26342B),
    error: Color(0xFFB8904A),
    success: Color(0xFF2D8B57),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? brandDark,
    Color? brandDeep,
    Color? cta,
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
      brandDark: brandDark ?? this.brandDark,
      brandDeep: brandDeep ?? this.brandDeep,
      cta: cta ?? this.cta,
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
      brandDark: Color.lerp(brandDark, other.brandDark, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      cta: Color.lerp(cta, other.cta, t)!,
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
