import 'package:flutter/material.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/passport/domain/passport_level.dart';

/// Label e visual (moldura/selo) de cada [PassportLevel] — o único lugar
/// que sabe como um nível se parece, pra `PassportCoverV2` nunca precisar
/// de um `if`/`switch` de nível espalhado no meio do layout. A capa do
/// Passaporte é fixa nos dois temas (ver `PassportCoverV2`), então as
/// cores aqui vêm de `AppColors.light` mesmo — nunca de `context.colors`.
class PassportLevelStyle {
  const PassportLevelStyle({
    required this.borderColor,
    required this.borderWidth,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  final Color borderColor;
  final double borderWidth;
  final Color badgeBackground;
  final Color badgeForeground;
}

String passportLevelLabel(AppLocalizations l10n, PassportLevel level) =>
    switch (level) {
      PassportLevel.primeirosPassos => l10n.passportLevelStarter,
      PassportLevel.torcedorPresente => l10n.passportLevelPresent,
      PassportLevel.esmeraldinoDeArquibancada => l10n.passportLevelBleacher,
      PassportLevel.verdaoRaiz => l10n.passportLevelRoots,
      PassportLevel.lendaEsmeraldina => l10n.passportLevelLegend,
    };

/// Progressão discreta: alpha/espessura da borda sobem nível a nível, e só
/// o nível máximo troca de cor de verdade (dourado) — o "acento dourado"
/// pedido, sem exagerar.
PassportLevelStyle passportLevelStyleFor(PassportLevel level) {
  final green = AppColors.light.primary;
  final gold = AppColors.light.gold;
  return switch (level) {
    PassportLevel.primeirosPassos => PassportLevelStyle(
      borderColor: Colors.white.withValues(alpha: 0.14),
      borderWidth: 1,
      badgeBackground: Colors.white.withValues(alpha: 0.12),
      badgeForeground: Colors.white,
    ),
    PassportLevel.torcedorPresente => PassportLevelStyle(
      borderColor: Colors.white.withValues(alpha: 0.28),
      borderWidth: 1.2,
      badgeBackground: Colors.white.withValues(alpha: 0.16),
      badgeForeground: Colors.white,
    ),
    PassportLevel.esmeraldinoDeArquibancada => PassportLevelStyle(
      borderColor: green.withValues(alpha: 0.55),
      borderWidth: 1.4,
      badgeBackground: green.withValues(alpha: 0.28),
      badgeForeground: Colors.white,
    ),
    PassportLevel.verdaoRaiz => PassportLevelStyle(
      borderColor: green.withValues(alpha: 0.85),
      borderWidth: 1.8,
      badgeBackground: green.withValues(alpha: 0.4),
      badgeForeground: Colors.white,
    ),
    PassportLevel.lendaEsmeraldina => PassportLevelStyle(
      borderColor: gold.withValues(alpha: 0.75),
      borderWidth: 2,
      badgeBackground: gold.withValues(alpha: 0.22),
      badgeForeground: gold,
    ),
  };
}
