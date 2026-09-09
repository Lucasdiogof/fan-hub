import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// CTA principal (ex.: "Ingressos"/"Comprar ingresso"/"Salvar ingresso") —
/// preenchido sólido no `cta` do CLUBE ATIVO, sem borda, nos dois temas.
/// [forceDark] é pra fundos sempre escuros independente do tema do app
/// (ex.: Hero da Home) — usa a paleta escura do clube ativo fixa em vez de
/// `context.colors`, que mudaria com o tema do app. Nunca `AppColors.dark`/
/// `.light` diretamente — essas constantes estáticas são sempre a paleta do
/// Goiás, vazariam a cor errada pra qualquer outro clube.
ButtonStyle matchCtaFilledStyle(
  BuildContext context, {
  double minHeight = 46,
  bool? forceDark,
}) {
  final isDark = forceDark ?? (Theme.of(context).brightness == Brightness.dark);
  final branding = sl<ClubConfig>().branding;
  final fill = isDark ? branding.dark.cta : branding.light.cta;
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

/// Botão branco preenchido pra usar sobre fundos escuros/coloridos sólidos
/// (ex.: banner promocional da Goiás Store) — inverso do
/// [matchCtaFilledStyle]: fundo branco, texto verde institucional, mesmo
/// nos dois temas do app (o fundo onde ele fica em cima já é escuro
/// sempre, então o botão não muda com o tema). `ElevatedButton` já resolve
/// hover/foco/toque sozinho a partir de `foregroundColor`.
ButtonStyle whiteFilledOnDarkStyle({double minHeight = 44}) {
  final text = sl<ClubConfig>().branding.light.primary;
  return ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: text,
    disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
    disabledForegroundColor: text.withValues(alpha: 0.6),
    minimumSize: Size(0, minHeight),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    ),
  );
}

/// CTA de conversão direta ("Comprar agora") — dourado do design system com
/// texto verde muito escuro pra contraste acessível, reservado pra destacar a
/// compra das outras ações verdes da tela. Usa os tokens `gold`/`deepGreen`
/// do tema (nada hardcoded), então adapta claro/escuro sozinho.
ButtonStyle goldFilledStyle(BuildContext context, {double minHeight = 52}) {
  final colors = context.colors;
  return ElevatedButton.styleFrom(
    backgroundColor: colors.gold,
    foregroundColor: colors.brandDeep,
    disabledBackgroundColor: colors.gold.withValues(alpha: 0.45),
    disabledForegroundColor: colors.brandDeep.withValues(alpha: 0.5),
    minimumSize: Size.fromHeight(minHeight),
    elevation: 0,
    textStyle: const TextStyle(fontWeight: FontWeight.w800),
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
  final branding = sl<ClubConfig>().branding;
  final accent = isDark ? branding.dark.cta : branding.light.cta;
  final text = isDark ? branding.dark.cta : branding.light.primary;
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
