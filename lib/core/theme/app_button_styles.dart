import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// CTA principal (ex.: "Ingressos"/"Comprar ingresso"/"Salvar ingresso") — verde
/// sólido preenchido ([AppColors.ctaGreen]), sem borda, nos dois temas.
/// [forceDark] é pra fundos sempre escuros independente do tema do app
/// (ex.: Hero da Home) — usa a paleta `AppColors.dark` fixa em vez de
/// `context.colors`, que mudaria com o tema do app.
ButtonStyle matchCtaFilledStyle(
  BuildContext context, {
  double minHeight = 46,
  bool? forceDark,
}) {
  final isDark = forceDark ?? (Theme.of(context).brightness == Brightness.dark);
  final fill = isDark ? AppColors.dark.ctaGreen : AppColors.light.ctaGreen;
  return ElevatedButton.styleFrom(
    backgroundColor: fill,
    foregroundColor: Colors.white,
    disabledBackgroundColor: fill.withValues(alpha: 0.5),
    disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
    minimumSize: Size.fromHeight(minHeight),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    ),
  );
}

/// Par do [matchCtaFilledStyle] pro botão secundário (ex.: "Detalhes do
/// jogo") — contorno colorido + texto colorido, sem preenchimento, em vez
/// do contorno branco/cinza fraco de antes.
ButtonStyle matchCtaOutlineStyle(
  BuildContext context, {
  double minHeight = 46,
  bool? forceDark,
}) {
  final isDark = forceDark ?? (Theme.of(context).brightness == Brightness.dark);
  final accent = isDark ? AppColors.dark.ctaGreen : AppColors.light.ctaGreen;
  final text = isDark ? const Color(0xFF4FCB8A) : AppColors.light.primary;
  return OutlinedButton.styleFrom(
    foregroundColor: text,
    disabledForegroundColor: text.withValues(alpha: 0.5),
    side: BorderSide(color: accent, width: 1.5),
    minimumSize: Size.fromHeight(minHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    ),
  );
}
