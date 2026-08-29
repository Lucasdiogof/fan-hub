import 'package:goias_app/shared/domain/player_position.dart';

/// Um slot no campo: a posição TÁTICA exigida (controla a elegibilidade —
/// nunca a posição do jogador escalado nele, ver `PositionCompatibilityService`)
/// e onde ele fica desenhado — x/y em fração (0..1), x=0 esquerda/x=1
/// direita, y=0 ataque (gol adversário) e y=1 nossa defesa/goleiro.
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

/// Seleção de 12 formações conhecidas e visualmente distintas — cada slot
/// tem sua própria coordenada curada (nunca calculada por "linha do meio
/// pra baixo" genérico), porque a mesma quantidade de jogadores numa linha
/// pode representar táticas bem diferentes (ex.: os dois avançados do
/// 4-2-2-2 ficam nos half-spaces, não abertos feito pontas de um 4-2-4).
///
/// Bandas de `y` — uma escada gradual da defesa até o ataque, sem saltos
/// grandes entre uma linha e a próxima (evita tanto o time "muito recuado"
/// quanto um vão vazio gigante entre o meio e o ataque):
/// goleiro ~0.91, defesa (linha de 4 ou de 5) ~0.70,
/// ala/wing-back de linha de 3 ~0.44, VOL (pivô duplo sem MC acima) ~0.52,
/// MC (par acima de um VOL isolado) ~0.38, VOL isolado (quando há MC acima)
/// ~0.56, meia ofensivo/half-space ~0.30, ataque/pontas ~0.18-0.20.
final List<Formation> formations = [
  Formation(
    id: '4-3-3',
    label: '4-3-3',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.le, 0.14, 0.70),
      _s(PlayerPosition.zag, 0.38, 0.70),
      _s(PlayerPosition.zag, 0.62, 0.70),
      _s(PlayerPosition.ld, 0.86, 0.70),
      _s(PlayerPosition.vol, 0.50, 0.53),
      _s(PlayerPosition.mc, 0.30, 0.38),
      _s(PlayerPosition.mc, 0.70, 0.38),
      _s(PlayerPosition.pe, 0.18, 0.20),
      _s(PlayerPosition.ata, 0.50, 0.20),
      _s(PlayerPosition.pd, 0.82, 0.20),
    ],
  ),
  Formation(
    id: '4-2-3-1',
    label: '4-2-3-1',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.le, 0.14, 0.70),
      _s(PlayerPosition.zag, 0.38, 0.70),
      _s(PlayerPosition.zag, 0.62, 0.70),
      _s(PlayerPosition.ld, 0.86, 0.70),
      _s(PlayerPosition.vol, 0.38, 0.52),
      _s(PlayerPosition.vol, 0.62, 0.52),
      _s(PlayerPosition.pe, 0.18, 0.32),
      _s(PlayerPosition.mei, 0.50, 0.32),
      _s(PlayerPosition.pd, 0.82, 0.32),
      _s(PlayerPosition.ata, 0.50, 0.18),
    ],
  ),
  Formation(
    id: '4-2-2-2',
    label: '4-2-2-2',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.le, 0.14, 0.70),
      _s(PlayerPosition.zag, 0.38, 0.70),
      _s(PlayerPosition.zag, 0.62, 0.70),
      _s(PlayerPosition.ld, 0.86, 0.70),
      _s(PlayerPosition.vol, 0.38, 0.52),
      _s(PlayerPosition.vol, 0.62, 0.52),
      // Half-space, nunca aberto feito ponta — é isto que diferencia este
      // 4-2-2-2 de um 4-2-4 visualmente.
      _s(PlayerPosition.mei, 0.35, 0.32),
      _s(PlayerPosition.mei, 0.65, 0.32),
      _s(PlayerPosition.ata, 0.37, 0.20),
      _s(PlayerPosition.ata, 0.63, 0.20),
    ],
  ),
  Formation(
    id: '4-4-2',
    label: '4-4-2',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.le, 0.14, 0.70),
      _s(PlayerPosition.zag, 0.38, 0.70),
      _s(PlayerPosition.zag, 0.62, 0.70),
      _s(PlayerPosition.ld, 0.86, 0.70),
      // Meio-campistas de lado (não pontas) — ME/MD, na mesma linha dos MC,
      // nunca na altura do ataque, senão viram pontas visualmente.
      _s(PlayerPosition.me, 0.14, 0.42),
      _s(PlayerPosition.mc, 0.38, 0.42),
      _s(PlayerPosition.mc, 0.62, 0.42),
      _s(PlayerPosition.md, 0.86, 0.42),
      _s(PlayerPosition.ata, 0.37, 0.20),
      _s(PlayerPosition.ata, 0.63, 0.20),
    ],
  ),
  Formation(
    id: '4-1-2-1-2',
    label: '4-1-2-1-2',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.le, 0.14, 0.70),
      _s(PlayerPosition.zag, 0.38, 0.70),
      _s(PlayerPosition.zag, 0.62, 0.70),
      _s(PlayerPosition.ld, 0.86, 0.70),
      _s(PlayerPosition.vol, 0.50, 0.56),
      // Mais abertos que o VOL, mas ainda no corredor central.
      _s(PlayerPosition.mc, 0.30, 0.42),
      _s(PlayerPosition.mc, 0.70, 0.42),
      _s(PlayerPosition.mei, 0.50, 0.30),
      _s(PlayerPosition.ata, 0.37, 0.20),
      _s(PlayerPosition.ata, 0.63, 0.20),
    ],
  ),
  Formation(
    id: '4-1-4-1',
    label: '4-1-4-1',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.le, 0.14, 0.70),
      _s(PlayerPosition.zag, 0.38, 0.70),
      _s(PlayerPosition.zag, 0.62, 0.70),
      _s(PlayerPosition.ld, 0.86, 0.70),
      // O "1" isolado na frente da defesa — mais baixo que a linha de 4 do
      // meio, nunca colado nela.
      _s(PlayerPosition.vol, 0.50, 0.56),
      _s(PlayerPosition.me, 0.14, 0.40),
      _s(PlayerPosition.mc, 0.38, 0.40),
      _s(PlayerPosition.mc, 0.62, 0.40),
      _s(PlayerPosition.md, 0.86, 0.40),
      _s(PlayerPosition.ata, 0.50, 0.20),
    ],
  ),
  Formation(
    id: '4-2-4',
    label: '4-2-4',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.le, 0.14, 0.70),
      _s(PlayerPosition.zag, 0.38, 0.70),
      _s(PlayerPosition.zag, 0.62, 0.70),
      _s(PlayerPosition.ld, 0.86, 0.70),
      _s(PlayerPosition.mc, 0.38, 0.44),
      _s(PlayerPosition.mc, 0.62, 0.44),
      // Quatro praticamente na mesma linha de frente — é isto que
      // diferencia visualmente do 4-2-2-2, cujos avançados ficam nos
      // half-spaces bem mais recuados.
      _s(PlayerPosition.pe, 0.15, 0.20),
      _s(PlayerPosition.ata, 0.39, 0.20),
      _s(PlayerPosition.ata, 0.61, 0.20),
      _s(PlayerPosition.pd, 0.85, 0.20),
    ],
  ),
  Formation(
    id: '3-5-2',
    label: '3-5-2',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.zag, 0.28, 0.70),
      _s(PlayerPosition.zag, 0.50, 0.70),
      _s(PlayerPosition.zag, 0.72, 0.70),
      _s(PlayerPosition.ale, 0.12, 0.44),
      _s(PlayerPosition.mc, 0.36, 0.47),
      _s(PlayerPosition.vol, 0.50, 0.50),
      _s(PlayerPosition.mc, 0.64, 0.47),
      _s(PlayerPosition.ald, 0.88, 0.44),
      _s(PlayerPosition.ata, 0.37, 0.20),
      _s(PlayerPosition.ata, 0.63, 0.20),
    ],
  ),
  Formation(
    id: '3-4-3',
    label: '3-4-3',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.zag, 0.28, 0.70),
      _s(PlayerPosition.zag, 0.50, 0.70),
      _s(PlayerPosition.zag, 0.72, 0.70),
      _s(PlayerPosition.ale, 0.12, 0.44),
      _s(PlayerPosition.mc, 0.38, 0.44),
      _s(PlayerPosition.mc, 0.62, 0.44),
      _s(PlayerPosition.ald, 0.88, 0.44),
      _s(PlayerPosition.pe, 0.18, 0.20),
      _s(PlayerPosition.ata, 0.50, 0.20),
      _s(PlayerPosition.pd, 0.82, 0.20),
    ],
  ),
  Formation(
    id: '3-4-2-1',
    label: '3-4-2-1',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.zag, 0.28, 0.70),
      _s(PlayerPosition.zag, 0.50, 0.70),
      _s(PlayerPosition.zag, 0.72, 0.70),
      _s(PlayerPosition.ale, 0.12, 0.44),
      _s(PlayerPosition.mc, 0.38, 0.44),
      _s(PlayerPosition.mc, 0.62, 0.44),
      _s(PlayerPosition.ald, 0.88, 0.44),
      // Half-space de novo, não PE/PD.
      _s(PlayerPosition.mei, 0.35, 0.32),
      _s(PlayerPosition.mei, 0.65, 0.32),
      _s(PlayerPosition.ata, 0.50, 0.18),
    ],
  ),
  Formation(
    id: '5-3-2',
    label: '5-3-2',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      // Linha de 5 de verdade — ala aqui é lateral da defesa, não um wing-back
      // avançado como nas formações de linha de 3 acima.
      _s(PlayerPosition.ale, 0.10, 0.70),
      _s(PlayerPosition.zag, 0.32, 0.70),
      _s(PlayerPosition.zag, 0.50, 0.70),
      _s(PlayerPosition.zag, 0.68, 0.70),
      _s(PlayerPosition.ald, 0.90, 0.70),
      _s(PlayerPosition.mc, 0.36, 0.47),
      _s(PlayerPosition.vol, 0.50, 0.50),
      _s(PlayerPosition.mc, 0.64, 0.47),
      _s(PlayerPosition.ata, 0.37, 0.20),
      _s(PlayerPosition.ata, 0.63, 0.20),
    ],
  ),
  Formation(
    id: '5-4-1',
    label: '5-4-1',
    slots: [
      _s(PlayerPosition.gol, 0.50, 0.91),
      _s(PlayerPosition.ale, 0.10, 0.70),
      _s(PlayerPosition.zag, 0.32, 0.70),
      _s(PlayerPosition.zag, 0.50, 0.70),
      _s(PlayerPosition.zag, 0.68, 0.70),
      _s(PlayerPosition.ald, 0.90, 0.70),
      _s(PlayerPosition.me, 0.15, 0.42),
      _s(PlayerPosition.mc, 0.38, 0.42),
      _s(PlayerPosition.mc, 0.62, 0.42),
      _s(PlayerPosition.md, 0.85, 0.42),
      _s(PlayerPosition.ata, 0.50, 0.20),
    ],
  ),
];

/// Formações que já saíram da seleção oferecida (nunca aparecem no
/// `FormationSelector` nem entram na disputa de "formação mais votada" pra
/// votos novos) mas que precisam continuar resolvendo corretamente pra
/// votos REAIS já salvos no Supabase com esses ids — sem isto,
/// `formationById` cairia no fallback (`4-3-3`) e reinterpretaria o
/// `slotIndex` de um voto antigo com as posições erradas, tanto pro dono do
/// voto reabrindo a própria escalação quanto pro agregado da torcida.
final List<Formation> _legacyFormations = [
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

Formation formationById(String id) {
  for (final formation in formations) {
    if (formation.id == id) return formation;
  }
  for (final formation in _legacyFormations) {
    if (formation.id == id) return formation;
  }
  return formations.first;
}
