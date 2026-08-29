import 'package:flutter/widgets.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';

enum PlayerPosition {
  gol,
  zag,
  ld,
  le,
  ald,
  ale,
  vol,
  mc,
  mei,
  md,
  me,
  pd,
  pe,
  sa,
  ata,
}

extension PlayerPositionLabel on PlayerPosition {
  String short(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      PlayerPosition.gol => l10n.playerPositionGolShort,
      PlayerPosition.zag => l10n.playerPositionZagShort,
      PlayerPosition.ld => l10n.playerPositionLdShort,
      PlayerPosition.le => l10n.playerPositionLeShort,
      PlayerPosition.ald => l10n.playerPositionAldShort,
      PlayerPosition.ale => l10n.playerPositionAleShort,
      PlayerPosition.vol => l10n.playerPositionVolShort,
      PlayerPosition.mc => l10n.playerPositionMcShort,
      PlayerPosition.mei => l10n.playerPositionMeiShort,
      PlayerPosition.md => l10n.playerPositionMdShort,
      PlayerPosition.me => l10n.playerPositionMeShort,
      PlayerPosition.pd => l10n.playerPositionPdShort,
      PlayerPosition.pe => l10n.playerPositionPeShort,
      PlayerPosition.sa => l10n.playerPositionSaShort,
      PlayerPosition.ata => l10n.playerPositionAtaShort,
    };
  }

  String full(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      PlayerPosition.gol => l10n.playerPositionGolFull,
      PlayerPosition.zag => l10n.playerPositionZagFull,
      PlayerPosition.ld => l10n.playerPositionLdFull,
      PlayerPosition.le => l10n.playerPositionLeFull,
      PlayerPosition.ald => l10n.playerPositionAldFull,
      PlayerPosition.ale => l10n.playerPositionAleFull,
      PlayerPosition.vol => l10n.playerPositionVolFull,
      PlayerPosition.mc => l10n.playerPositionMcFull,
      PlayerPosition.mei => l10n.playerPositionMeiFull,
      PlayerPosition.md => l10n.playerPositionMdFull,
      PlayerPosition.me => l10n.playerPositionMeFull,
      PlayerPosition.pd => l10n.playerPositionPdFull,
      PlayerPosition.pe => l10n.playerPositionPeFull,
      PlayerPosition.sa => l10n.playerPositionSaFull,
      PlayerPosition.ata => l10n.playerPositionAtaFull,
    };
  }
}

PlayerPosition? playerPositionFromCode(String code) {
  for (final position in PlayerPosition.values) {
    if (position.name == code) return position;
  }
  return null;
}
