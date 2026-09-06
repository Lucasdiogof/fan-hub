import 'package:flutter/material.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/passport/domain/passport_level.dart';

/// Label e visual (moldura/selo/textura) de cada [PassportLevel] — o único
/// lugar que sabe como um nível se parece, pra `PassportCoverV2` nunca
/// precisar de um `if`/`switch` de nível espalhado no meio do layout. A
/// capa do Passaporte é fixa nos dois temas (ver `PassportCoverV2`), então
/// as cores aqui vêm de `AppColors.light` mesmo — nunca de `context.colors`.
///
/// A progressão entre níveis é deliberadamente sobre REFINAMENTO, não
/// brilho: cada campo sobe em pequenos incrementos (opacidade, riqueza da
/// textura) — nunca um salto brusco de um nível pro outro. O dourado só
/// aparece de verdade a partir de `verdaoRaiz`, sempre como ACENTO (linha
/// fina, borda de selo, ícone) — a base do card continua verde em todos os
/// 5 níveis. A espessura da borda (ver [passportCoverBorderWidth]) é fixa
/// pra qualquer nível — variar isso mudaria o tamanho do card em px e
/// violaria a regra de "estrutura nunca muda, só decoração".
class PassportLevelStyle {
  const PassportLevelStyle({
    required this.borderColor,
    required this.innerBorderColor,
    required this.accentLineColor,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.badgeBorderColor,
    required this.badgeIcon,
    required this.watermarkOpacity,
    required this.textureOpacity,
  });

  /// Borda externa do card.
  final Color borderColor;

  /// Segunda linha, um pouco pra dentro da borda externa — o "moldura
  /// dupla muito sutil" pedido a partir do nível 3. `null` = só uma linha.
  final Color? innerBorderColor;

  /// Linha fina no topo do card — o acento dourado que aparece a partir do
  /// nível 4 (`verdaoRaiz`). `null` = sem linha.
  final Color? accentLineColor;

  final Color badgeBackground;
  final Color badgeForeground;
  final Color badgeBorderColor;

  /// Ícone pequeno antes do texto do selo — só a partir do nível 3, nunca
  /// nos dois primeiros (o pedido explícito era "praticamente sem efeito
  /// premium" pro nível 1). `null` = sem ícone.
  final IconData? badgeIcon;

  /// Opacidade da marca d'água do escudo no canto do card — sobe muito
  /// pouco por nível (nunca deixa de ser "baixíssima opacidade").
  final double watermarkOpacity;

  /// Opacidade das linhas diagonais de textura (inspiradas em
  /// arquibancada/campo) — 0 nos dois primeiros níveis.
  final double textureOpacity;
}

/// Espessura da borda do card — mesma em todo nível, ver o porquê na
/// docstring de [PassportLevelStyle].
const passportCoverBorderWidth = 1.4;

String passportLevelLabel(AppLocalizations l10n, PassportLevel level) =>
    switch (level) {
      PassportLevel.primeirosPassos => l10n.passportLevelStarter,
      PassportLevel.torcedorPresente => l10n.passportLevelPresent,
      PassportLevel.esmeraldinoDeArquibancada => l10n.passportLevelBleacher,
      PassportLevel.verdaoRaiz => l10n.passportLevelRoots,
      PassportLevel.lendaEsmeraldina => l10n.passportLevelLegend,
    };

PassportLevelStyle passportLevelStyleFor(PassportLevel level) {
  final green = AppColors.light.primary;
  final gold = AppColors.light.gold;
  return switch (level) {
    PassportLevel.primeirosPassos => PassportLevelStyle(
      borderColor: AppColors.light.brandDark.withValues(alpha: 0.9),
      innerBorderColor: null,
      accentLineColor: null,
      badgeBackground: Colors.white.withValues(alpha: 0.1),
      badgeForeground: Colors.white.withValues(alpha: 0.85),
      badgeBorderColor: Colors.white.withValues(alpha: 0.16),
      badgeIcon: null,
      watermarkOpacity: 0.04,
      textureOpacity: 0,
    ),
    PassportLevel.torcedorPresente => PassportLevelStyle(
      borderColor: green.withValues(alpha: 0.5),
      innerBorderColor: null,
      accentLineColor: null,
      badgeBackground: green.withValues(alpha: 0.22),
      badgeForeground: Colors.white,
      badgeBorderColor: green.withValues(alpha: 0.4),
      badgeIcon: null,
      watermarkOpacity: 0.048,
      textureOpacity: 0,
    ),
    PassportLevel.esmeraldinoDeArquibancada => PassportLevelStyle(
      borderColor: green.withValues(alpha: 0.68),
      innerBorderColor: green.withValues(alpha: 0.28),
      accentLineColor: null,
      badgeBackground: green.withValues(alpha: 0.34),
      badgeForeground: Colors.white,
      badgeBorderColor: green.withValues(alpha: 0.55),
      badgeIcon: Icons.star_border_rounded,
      watermarkOpacity: 0.056,
      textureOpacity: 0.03,
    ),
    PassportLevel.verdaoRaiz => PassportLevelStyle(
      borderColor: green.withValues(alpha: 0.85),
      innerBorderColor: green.withValues(alpha: 0.32),
      accentLineColor: gold.withValues(alpha: 0.5),
      badgeBackground: green.withValues(alpha: 0.42),
      badgeForeground: Colors.white,
      badgeBorderColor: gold.withValues(alpha: 0.5),
      badgeIcon: Icons.star_half_rounded,
      watermarkOpacity: 0.064,
      textureOpacity: 0.038,
    ),
    PassportLevel.lendaEsmeraldina => PassportLevelStyle(
      borderColor: gold.withValues(alpha: 0.8),
      innerBorderColor: gold.withValues(alpha: 0.34),
      accentLineColor: gold.withValues(alpha: 0.85),
      badgeBackground: gold.withValues(alpha: 0.24),
      badgeForeground: gold,
      badgeBorderColor: gold.withValues(alpha: 0.7),
      badgeIcon: Icons.star_rounded,
      watermarkOpacity: 0.074,
      textureOpacity: 0.045,
    ),
  };
}
