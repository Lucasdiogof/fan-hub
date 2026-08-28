import 'package:goias_app/shared/domain/player_position.dart';

/// Um slot no campo: a posição exigida (controla a elegibilidade) e onde
/// ele fica desenhado — x/y em fração (0..1), com o gol embaixo (y alto) e
/// o ataque em cima (y baixo).
class FormationSlot {
  const FormationSlot(this.position, this.x, this.y);

  final PlayerPosition position;
  final double x;
  final double y;
}

class Formation {
  const Formation({required this.id, required this.label, required this.slots});

  final String id;
  final String label;
  final List<FormationSlot> slots;
}

FormationSlot _s(PlayerPosition p, double x, double y) =>
    FormationSlot(p, x, y);

final List<Formation> formations = [
  Formation(
    id: '4-3-3',
    label: '4-3-3',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ld, 0.85, 0.76),
      _s(PlayerPosition.zag, 0.62, 0.80),
      _s(PlayerPosition.zag, 0.38, 0.80),
      _s(PlayerPosition.le, 0.15, 0.76),
      _s(PlayerPosition.mei, 0.72, 0.57),
      _s(PlayerPosition.vol, 0.5, 0.62),
      _s(PlayerPosition.mc, 0.28, 0.57),
      _s(PlayerPosition.pd, 0.82, 0.32),
      _s(PlayerPosition.ata, 0.5, 0.27),
      _s(PlayerPosition.pe, 0.18, 0.32),
    ],
  ),
  Formation(
    id: '4-2-3-1',
    label: '4-2-3-1',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ld, 0.85, 0.76),
      _s(PlayerPosition.zag, 0.62, 0.80),
      _s(PlayerPosition.zag, 0.38, 0.80),
      _s(PlayerPosition.le, 0.15, 0.76),
      _s(PlayerPosition.vol, 0.62, 0.64),
      _s(PlayerPosition.vol, 0.38, 0.64),
      _s(PlayerPosition.pd, 0.82, 0.46),
      _s(PlayerPosition.mei, 0.5, 0.48),
      _s(PlayerPosition.pe, 0.18, 0.46),
      _s(PlayerPosition.ata, 0.5, 0.27),
    ],
  ),
  Formation(
    id: '4-4-2',
    label: '4-4-2',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ld, 0.85, 0.76),
      _s(PlayerPosition.zag, 0.62, 0.80),
      _s(PlayerPosition.zag, 0.38, 0.80),
      _s(PlayerPosition.le, 0.15, 0.76),
      _s(PlayerPosition.pd, 0.84, 0.57),
      _s(PlayerPosition.mc, 0.60, 0.60),
      _s(PlayerPosition.mc, 0.40, 0.60),
      _s(PlayerPosition.pe, 0.16, 0.57),
      _s(PlayerPosition.ata, 0.60, 0.29),
      _s(PlayerPosition.sa, 0.40, 0.29),
    ],
  ),
  Formation(
    id: '4-5-1',
    label: '4-5-1',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ld, 0.85, 0.76),
      _s(PlayerPosition.zag, 0.62, 0.80),
      _s(PlayerPosition.zag, 0.38, 0.80),
      _s(PlayerPosition.le, 0.15, 0.76),
      _s(PlayerPosition.pd, 0.86, 0.55),
      _s(PlayerPosition.mc, 0.63, 0.60),
      _s(PlayerPosition.vol, 0.5, 0.64),
      _s(PlayerPosition.mc, 0.37, 0.60),
      _s(PlayerPosition.pe, 0.14, 0.55),
      _s(PlayerPosition.ata, 0.5, 0.29),
    ],
  ),
  Formation(
    id: '3-5-2',
    label: '3-5-2',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.zag, 0.72, 0.81),
      _s(PlayerPosition.zag, 0.5, 0.82),
      _s(PlayerPosition.zag, 0.28, 0.81),
      _s(PlayerPosition.ald, 0.88, 0.59),
      _s(PlayerPosition.mc, 0.64, 0.61),
      _s(PlayerPosition.vol, 0.5, 0.66),
      _s(PlayerPosition.mc, 0.36, 0.61),
      _s(PlayerPosition.ale, 0.12, 0.59),
      _s(PlayerPosition.ata, 0.60, 0.29),
      _s(PlayerPosition.sa, 0.40, 0.29),
    ],
  ),
  Formation(
    id: '4-1-4-1',
    label: '4-1-4-1',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ld, 0.85, 0.76),
      _s(PlayerPosition.zag, 0.62, 0.80),
      _s(PlayerPosition.zag, 0.38, 0.80),
      _s(PlayerPosition.le, 0.15, 0.76),
      _s(PlayerPosition.vol, 0.5, 0.66),
      _s(PlayerPosition.pd, 0.86, 0.52),
      _s(PlayerPosition.mc, 0.62, 0.48),
      _s(PlayerPosition.mc, 0.38, 0.48),
      _s(PlayerPosition.pe, 0.14, 0.52),
      _s(PlayerPosition.ata, 0.5, 0.27),
    ],
  ),
  Formation(
    id: '4-1-3-2',
    label: '4-1-3-2',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ld, 0.85, 0.76),
      _s(PlayerPosition.zag, 0.62, 0.80),
      _s(PlayerPosition.zag, 0.38, 0.80),
      _s(PlayerPosition.le, 0.15, 0.76),
      _s(PlayerPosition.vol, 0.5, 0.66),
      _s(PlayerPosition.pd, 0.80, 0.52),
      _s(PlayerPosition.mei, 0.5, 0.50),
      _s(PlayerPosition.pe, 0.20, 0.52),
      _s(PlayerPosition.ata, 0.60, 0.29),
      _s(PlayerPosition.sa, 0.40, 0.29),
    ],
  ),
  Formation(
    id: '4-3-1-2',
    label: '4-3-1-2',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ld, 0.85, 0.76),
      _s(PlayerPosition.zag, 0.62, 0.80),
      _s(PlayerPosition.zag, 0.38, 0.80),
      _s(PlayerPosition.le, 0.15, 0.76),
      _s(PlayerPosition.mc, 0.68, 0.62),
      _s(PlayerPosition.vol, 0.5, 0.66),
      _s(PlayerPosition.mc, 0.32, 0.62),
      _s(PlayerPosition.mei, 0.5, 0.46),
      _s(PlayerPosition.ata, 0.60, 0.27),
      _s(PlayerPosition.sa, 0.40, 0.27),
    ],
  ),
  Formation(
    id: '3-4-3',
    label: '3-4-3',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.zag, 0.72, 0.81),
      _s(PlayerPosition.zag, 0.5, 0.82),
      _s(PlayerPosition.zag, 0.28, 0.81),
      _s(PlayerPosition.ald, 0.88, 0.59),
      _s(PlayerPosition.mc, 0.62, 0.60),
      _s(PlayerPosition.vol, 0.38, 0.60),
      _s(PlayerPosition.ale, 0.12, 0.59),
      _s(PlayerPosition.pd, 0.80, 0.31),
      _s(PlayerPosition.ata, 0.5, 0.27),
      _s(PlayerPosition.pe, 0.20, 0.31),
    ],
  ),
  Formation(
    id: '3-4-1-2',
    label: '3-4-1-2',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.zag, 0.72, 0.81),
      _s(PlayerPosition.zag, 0.5, 0.82),
      _s(PlayerPosition.zag, 0.28, 0.81),
      _s(PlayerPosition.ald, 0.88, 0.62),
      _s(PlayerPosition.vol, 0.62, 0.64),
      _s(PlayerPosition.mc, 0.38, 0.64),
      _s(PlayerPosition.ale, 0.12, 0.62),
      _s(PlayerPosition.mei, 0.5, 0.46),
      _s(PlayerPosition.ata, 0.60, 0.27),
      _s(PlayerPosition.sa, 0.40, 0.27),
    ],
  ),
  Formation(
    id: '5-3-2',
    label: '5-3-2',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ald, 0.90, 0.75),
      _s(PlayerPosition.zag, 0.68, 0.82),
      _s(PlayerPosition.zag, 0.5, 0.83),
      _s(PlayerPosition.zag, 0.32, 0.82),
      _s(PlayerPosition.ale, 0.10, 0.75),
      _s(PlayerPosition.mc, 0.64, 0.60),
      _s(PlayerPosition.vol, 0.5, 0.62),
      _s(PlayerPosition.mc, 0.36, 0.60),
      _s(PlayerPosition.ata, 0.60, 0.27),
      _s(PlayerPosition.sa, 0.40, 0.27),
    ],
  ),
  Formation(
    id: '5-4-1',
    label: '5-4-1',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ald, 0.90, 0.75),
      _s(PlayerPosition.zag, 0.68, 0.82),
      _s(PlayerPosition.zag, 0.5, 0.83),
      _s(PlayerPosition.zag, 0.32, 0.82),
      _s(PlayerPosition.ale, 0.10, 0.75),
      _s(PlayerPosition.pd, 0.82, 0.53),
      _s(PlayerPosition.mc, 0.58, 0.57),
      _s(PlayerPosition.mc, 0.42, 0.57),
      _s(PlayerPosition.pe, 0.18, 0.53),
      _s(PlayerPosition.ata, 0.5, 0.27),
    ],
  ),
  Formation(
    id: '4-4-1-1',
    label: '4-4-1-1',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ld, 0.85, 0.76),
      _s(PlayerPosition.zag, 0.62, 0.80),
      _s(PlayerPosition.zag, 0.38, 0.80),
      _s(PlayerPosition.le, 0.15, 0.76),
      _s(PlayerPosition.pd, 0.84, 0.57),
      _s(PlayerPosition.mc, 0.60, 0.60),
      _s(PlayerPosition.mc, 0.40, 0.60),
      _s(PlayerPosition.pe, 0.16, 0.57),
      _s(PlayerPosition.mei, 0.5, 0.41),
      _s(PlayerPosition.ata, 0.5, 0.27),
    ],
  ),
  Formation(
    id: '4-2-2-2',
    label: '4-2-2-2',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ld, 0.85, 0.76),
      _s(PlayerPosition.zag, 0.62, 0.80),
      _s(PlayerPosition.zag, 0.38, 0.80),
      _s(PlayerPosition.le, 0.15, 0.76),
      _s(PlayerPosition.vol, 0.62, 0.66),
      _s(PlayerPosition.vol, 0.38, 0.66),
      _s(PlayerPosition.pd, 0.78, 0.46),
      _s(PlayerPosition.pe, 0.22, 0.46),
      _s(PlayerPosition.ata, 0.60, 0.27),
      _s(PlayerPosition.sa, 0.40, 0.27),
    ],
  ),
  Formation(
    id: '4-1-2-3',
    label: '4-1-2-3',
    slots: [
      _s(PlayerPosition.gol, 0.5, 0.93),
      _s(PlayerPosition.ld, 0.85, 0.76),
      _s(PlayerPosition.zag, 0.62, 0.80),
      _s(PlayerPosition.zag, 0.38, 0.80),
      _s(PlayerPosition.le, 0.15, 0.76),
      _s(PlayerPosition.vol, 0.5, 0.66),
      _s(PlayerPosition.mc, 0.62, 0.52),
      _s(PlayerPosition.mc, 0.38, 0.52),
      _s(PlayerPosition.pd, 0.82, 0.31),
      _s(PlayerPosition.ata, 0.5, 0.27),
      _s(PlayerPosition.pe, 0.18, 0.31),
    ],
  ),
];

Formation formationById(String id) => formations.firstWhere(
  (formation) => formation.id == id,
  orElse: () => formations.first,
);
