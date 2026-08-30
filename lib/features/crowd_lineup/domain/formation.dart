import 'package:goias_app/shared/domain/player_position.dart';

/// Linha tática de um slot — usada pela engine de layout (ver
/// `LineupLayoutEngine`) pra agrupar slots com segurança (nunca mais por
/// proximidade heurística de `y`) e pra travar a ordem "ataque acima do
/// meio, meio acima da defesa, defesa acima do goleiro" em teste. A ordem
/// dos valores no enum É a ordem tática do campo (ataque primeiro).
enum TacticalLine { attack, attackingMid, midfield, defensiveMid, defense, keeper }

/// `y` alvo de cada linha tática — ponto de partida único pra toda formação;
/// pequenos desvios por formação (ex.: losango precisando de uma linha a
/// mais no mesmo espaço) são aplicados localmente, nunca inventados do zero.
const Map<TacticalLine, double> tacticalLineY = {
  TacticalLine.attack: 0.19,
  TacticalLine.attackingMid: 0.31,
  TacticalLine.midfield: 0.44,
  TacticalLine.defensiveMid: 0.56,
  TacticalLine.defense: 0.70,
  TacticalLine.keeper: 0.88,
};

/// Distribui [count] jogadores igualmente espaçados dentro de
/// `[0.5 - halfSpan, 0.5 + halfSpan]` — a regra objetiva de distribuição
/// horizontal pedida: quantos jogadores existem na linha (via `count`) e o
/// espaço necessário pro papel tático daquela linha (via `halfSpan`, curado
/// uma vez por PAPEL — back-4, back-3, ala aberto, half-space etc. — e
/// reaproveitado por todas as formações que têm aquele papel, nunca
/// reinventado formação a formação). `count == 1` sempre centraliza.
List<double> distributeLine(int count, double halfSpan) {
  if (count <= 1) return const [0.5];
  final step = (2 * halfSpan) / (count - 1);
  return List.generate(count, (i) => 0.5 - halfSpan + step * i);
}

// Half-spans curados por PAPEL tático (reaproveitados por várias formações):
const _backFour = 0.36; // linha de 4 (defesa ou ataque totalmente aberto)
const _backThree = 0.22; // trio de zagueiros centrais
const _backFive = 0.40; // linha de 5 com alas na função de lateral
const _flatMidFour = 0.36; // meio-campo em linha de 4 (ME/MC/MC/MD)
const _centralPair = 0.12; // dupla central colada (2 VOL ou 2 MC sem linha acima)
const _deepPair = 0.20; // dupla central com uma linha acima dela (ex.: losango)
const _halfSpace = 0.15; // dupla em half-space (nunca aberta feito ponta)
const _frontThree = 0.32; // ponta/centroavante/ponta
const _wingBack = 0.38; // alas avançados de linha de 3 (não são laterais de 4/5)
const _trio = 0.22; // trio central (MC/VOL/MC ou zagueiros)

class FormationSlot {
  const FormationSlot(this.position, this.x, this.y, this.line);

  final PlayerPosition position;
  final double x;
  final double y;
  final TacticalLine line;
}

class Formation {
  const Formation({required this.id, required this.label, required this.slots});

  final String id;
  final String label;
  final List<FormationSlot> slots;
}

FormationSlot _slot(PlayerPosition p, double x, TacticalLine line) =>
    FormationSlot(p, x, tacticalLineY[line]!, line);

/// Uma linha inteira de uma vez: distribui [positions] com `distributeLine`
/// no `halfSpan` do papel tático e monta os slots já com `y`/`line` corretos.
List<FormationSlot> _line(
  List<PlayerPosition> positions,
  TacticalLine line,
  double halfSpan,
) {
  final xs = distributeLine(positions.length, halfSpan);
  return [for (var i = 0; i < positions.length; i++) _slot(positions[i], xs[i], line)];
}

/// Seleção de 12 formações conhecidas e visualmente distintas. Cada formação
/// é montada como uma lista de LINHAS (`_line`), não de slots soltos — a
/// posição horizontal vem sempre de `distributeLine` com o half-span do
/// papel tático daquela linha (comentado em cada uma), nunca digitada à mão
/// slot a slot. `y` vem de `tacticalLineY`, então nunca diverge entre
/// formações — retunar uma banda inteira é uma mudança em um lugar só.
final List<Formation> formations = [
  Formation(
    id: '4-3-3',
    label: '4-3-3',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.le,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.ld,
      ], TacticalLine.defense, _backFour),
      _slot(PlayerPosition.vol, 0.5, TacticalLine.defensiveMid),
      ..._line(
        [PlayerPosition.mc, PlayerPosition.mc],
        TacticalLine.midfield,
        _centralPair,
      ),
      ..._line([
        PlayerPosition.pe,
        PlayerPosition.ata,
        PlayerPosition.pd,
      ], TacticalLine.attack, _frontThree),
    ],
  ),
  Formation(
    id: '4-2-3-1',
    label: '4-2-3-1',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.le,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.ld,
      ], TacticalLine.defense, _backFour),
      ..._line(
        [PlayerPosition.vol, PlayerPosition.vol],
        TacticalLine.midfield,
        _centralPair,
      ),
      ..._line([
        PlayerPosition.pe,
        PlayerPosition.mei,
        PlayerPosition.pd,
      ], TacticalLine.attackingMid, _frontThree),
      _slot(PlayerPosition.ata, 0.5, TacticalLine.attack),
    ],
  ),
  Formation(
    id: '4-2-2-2',
    label: '4-2-2-2',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.le,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.ld,
      ], TacticalLine.defense, _backFour),
      ..._line(
        [PlayerPosition.vol, PlayerPosition.vol],
        TacticalLine.midfield,
        _centralPair,
      ),
      // Half-space, nunca aberto feito ponta — é isto que diferencia este
      // 4-2-2-2 de um 4-2-4 visualmente.
      ..._line(
        [PlayerPosition.mei, PlayerPosition.mei],
        TacticalLine.attackingMid,
        _halfSpace,
      ),
      ..._line(
        [PlayerPosition.ata, PlayerPosition.ata],
        TacticalLine.attack,
        _halfSpace,
      ),
    ],
  ),
  Formation(
    id: '4-4-2',
    label: '4-4-2',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.le,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.ld,
      ], TacticalLine.defense, _backFour),
      // Meio-campistas de lado (não pontas) — ME/MD, na mesma linha dos MC.
      ..._line([
        PlayerPosition.me,
        PlayerPosition.mc,
        PlayerPosition.mc,
        PlayerPosition.md,
      ], TacticalLine.midfield, _flatMidFour),
      ..._line(
        [PlayerPosition.ata, PlayerPosition.ata],
        TacticalLine.attack,
        _halfSpace,
      ),
    ],
  ),
  Formation(
    id: '4-1-2-1-2',
    label: '4-1-2-1-2',
    slots: [
      // Losango tem 6 linhas (gol, defesa, vol, dupla de MC, meia, dupla de
      // ataque) — uma a mais que a maioria das outras formações — no MESMO
      // espaço vertical. `TacticalLine.defensiveMid`/`midfield`/`attackingMid`
      // cobrem as 3 camadas centrais sem precisar espremer nada à mão.
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.le,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.ld,
      ], TacticalLine.defense, _backFour),
      _slot(PlayerPosition.vol, 0.5, TacticalLine.defensiveMid),
      ..._line(
        [PlayerPosition.mc, PlayerPosition.mc],
        TacticalLine.midfield,
        _deepPair,
      ),
      _slot(PlayerPosition.mei, 0.5, TacticalLine.attackingMid),
      ..._line(
        [PlayerPosition.ata, PlayerPosition.ata],
        TacticalLine.attack,
        _halfSpace,
      ),
    ],
  ),
  Formation(
    id: '4-1-4-1',
    label: '4-1-4-1',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.le,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.ld,
      ], TacticalLine.defense, _backFour),
      // O "1" isolado na frente da defesa — mais baixo que a linha de 4 do
      // meio, nunca colado nela.
      _slot(PlayerPosition.vol, 0.5, TacticalLine.defensiveMid),
      ..._line([
        PlayerPosition.me,
        PlayerPosition.mc,
        PlayerPosition.mc,
        PlayerPosition.md,
      ], TacticalLine.midfield, _flatMidFour),
      _slot(PlayerPosition.ata, 0.5, TacticalLine.attack),
    ],
  ),
  Formation(
    id: '4-2-4',
    label: '4-2-4',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.le,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.ld,
      ], TacticalLine.defense, _backFour),
      ..._line(
        [PlayerPosition.mc, PlayerPosition.mc],
        TacticalLine.midfield,
        _centralPair,
      ),
      // Quatro praticamente na mesma linha de frente — é isto que
      // diferencia visualmente do 4-2-2-2, cujos avançados ficam nos
      // half-spaces bem mais recuados.
      ..._line([
        PlayerPosition.pe,
        PlayerPosition.ata,
        PlayerPosition.ata,
        PlayerPosition.pd,
      ], TacticalLine.attack, _backFour),
    ],
  ),
  Formation(
    id: '3-5-2',
    label: '3-5-2',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.zag,
      ], TacticalLine.defense, _backThree),
      _slot(PlayerPosition.ale, 0.5 - _wingBack, TacticalLine.midfield),
      ..._line(
        [PlayerPosition.mc, PlayerPosition.mc],
        TacticalLine.midfield,
        _deepPair,
      ),
      _slot(PlayerPosition.ald, 0.5 + _wingBack, TacticalLine.midfield),
      _slot(PlayerPosition.vol, 0.5, TacticalLine.defensiveMid),
      ..._line(
        [PlayerPosition.ata, PlayerPosition.ata],
        TacticalLine.attack,
        _halfSpace,
      ),
    ],
  ),
  Formation(
    id: '3-4-3',
    label: '3-4-3',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.zag,
      ], TacticalLine.defense, _backThree),
      _slot(PlayerPosition.ale, 0.5 - _wingBack, TacticalLine.midfield),
      ..._line(
        [PlayerPosition.mc, PlayerPosition.mc],
        TacticalLine.midfield,
        _deepPair,
      ),
      _slot(PlayerPosition.ald, 0.5 + _wingBack, TacticalLine.midfield),
      ..._line([
        PlayerPosition.pe,
        PlayerPosition.ata,
        PlayerPosition.pd,
      ], TacticalLine.attack, _frontThree),
    ],
  ),
  Formation(
    id: '3-4-2-1',
    label: '3-4-2-1',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.zag,
      ], TacticalLine.defense, _backThree),
      _slot(PlayerPosition.ale, 0.5 - _wingBack, TacticalLine.midfield),
      ..._line(
        [PlayerPosition.mc, PlayerPosition.mc],
        TacticalLine.midfield,
        _deepPair,
      ),
      _slot(PlayerPosition.ald, 0.5 + _wingBack, TacticalLine.midfield),
      // Half-space de novo, não PE/PD.
      ..._line(
        [PlayerPosition.mei, PlayerPosition.mei],
        TacticalLine.attackingMid,
        _halfSpace,
      ),
      _slot(PlayerPosition.ata, 0.5, TacticalLine.attack),
    ],
  ),
  Formation(
    id: '5-3-2',
    label: '5-3-2',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      // Linha de 5 de verdade — ala aqui é lateral da defesa, não um
      // wing-back avançado como nas formações de linha de 3 acima.
      ..._line([
        PlayerPosition.ale,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.ald,
      ], TacticalLine.defense, _backFive),
      ..._line([
        PlayerPosition.mc,
        PlayerPosition.vol,
        PlayerPosition.mc,
      ], TacticalLine.midfield, _trio),
      ..._line(
        [PlayerPosition.ata, PlayerPosition.ata],
        TacticalLine.attack,
        _halfSpace,
      ),
    ],
  ),
  Formation(
    id: '5-4-1',
    label: '5-4-1',
    slots: [
      _slot(PlayerPosition.gol, 0.5, TacticalLine.keeper),
      ..._line([
        PlayerPosition.ale,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.zag,
        PlayerPosition.ald,
      ], TacticalLine.defense, _backFive),
      ..._line([
        PlayerPosition.me,
        PlayerPosition.mc,
        PlayerPosition.mc,
        PlayerPosition.md,
      ], TacticalLine.midfield, _flatMidFour),
      _slot(PlayerPosition.ata, 0.5, TacticalLine.attack),
    ],
  ),
];

/// Formações que já saíram da seleção oferecida (nunca aparecem no
/// `FormationSelector` nem entram na disputa de "formação mais votada" pra
/// votos novos) mas que precisam continuar resolvendo corretamente pra
/// votos REAIS já salvos no Supabase com esses ids — sem isto,
/// `formationById` cairia no fallback (`4-3-3`) e reinterpretaria o
/// `slotIndex` de um voto antigo com as posições erradas. Mantidas com suas
/// coordenadas originais (nunca renderizadas pra ninguém escalar de novo,
/// então não passam pela engine/bandas novas — baixo risco, alto custo
/// mexer em dado histórico sem necessidade).
final List<Formation> _legacyFormations = [
  const Formation(
    id: '4-5-1',
    label: '4-5-1',
    slots: [
      FormationSlot(PlayerPosition.gol, 0.5, 0.93, TacticalLine.keeper),
      FormationSlot(PlayerPosition.ld, 0.85, 0.76, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.62, 0.80, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.38, 0.80, TacticalLine.defense),
      FormationSlot(PlayerPosition.le, 0.15, 0.76, TacticalLine.defense),
      FormationSlot(PlayerPosition.pd, 0.86, 0.55, TacticalLine.midfield),
      FormationSlot(PlayerPosition.mc, 0.63, 0.60, TacticalLine.midfield),
      FormationSlot(PlayerPosition.vol, 0.5, 0.64, TacticalLine.defensiveMid),
      FormationSlot(PlayerPosition.mc, 0.37, 0.60, TacticalLine.midfield),
      FormationSlot(PlayerPosition.pe, 0.14, 0.55, TacticalLine.midfield),
      FormationSlot(PlayerPosition.ata, 0.5, 0.29, TacticalLine.attack),
    ],
  ),
  const Formation(
    id: '4-1-3-2',
    label: '4-1-3-2',
    slots: [
      FormationSlot(PlayerPosition.gol, 0.5, 0.93, TacticalLine.keeper),
      FormationSlot(PlayerPosition.ld, 0.85, 0.76, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.62, 0.80, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.38, 0.80, TacticalLine.defense),
      FormationSlot(PlayerPosition.le, 0.15, 0.76, TacticalLine.defense),
      FormationSlot(PlayerPosition.vol, 0.5, 0.66, TacticalLine.defensiveMid),
      FormationSlot(PlayerPosition.pd, 0.80, 0.52, TacticalLine.midfield),
      FormationSlot(PlayerPosition.mei, 0.5, 0.50, TacticalLine.attackingMid),
      FormationSlot(PlayerPosition.pe, 0.20, 0.52, TacticalLine.midfield),
      FormationSlot(PlayerPosition.ata, 0.60, 0.29, TacticalLine.attack),
      FormationSlot(PlayerPosition.sa, 0.40, 0.29, TacticalLine.attack),
    ],
  ),
  const Formation(
    id: '4-3-1-2',
    label: '4-3-1-2',
    slots: [
      FormationSlot(PlayerPosition.gol, 0.5, 0.93, TacticalLine.keeper),
      FormationSlot(PlayerPosition.ld, 0.85, 0.76, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.62, 0.80, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.38, 0.80, TacticalLine.defense),
      FormationSlot(PlayerPosition.le, 0.15, 0.76, TacticalLine.defense),
      FormationSlot(PlayerPosition.mc, 0.68, 0.62, TacticalLine.midfield),
      FormationSlot(PlayerPosition.vol, 0.5, 0.66, TacticalLine.defensiveMid),
      FormationSlot(PlayerPosition.mc, 0.32, 0.62, TacticalLine.midfield),
      FormationSlot(PlayerPosition.mei, 0.5, 0.46, TacticalLine.attackingMid),
      FormationSlot(PlayerPosition.ata, 0.60, 0.27, TacticalLine.attack),
      FormationSlot(PlayerPosition.sa, 0.40, 0.27, TacticalLine.attack),
    ],
  ),
  const Formation(
    id: '3-4-1-2',
    label: '3-4-1-2',
    slots: [
      FormationSlot(PlayerPosition.gol, 0.5, 0.93, TacticalLine.keeper),
      FormationSlot(PlayerPosition.zag, 0.72, 0.81, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.5, 0.82, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.28, 0.81, TacticalLine.defense),
      FormationSlot(PlayerPosition.ald, 0.88, 0.62, TacticalLine.midfield),
      FormationSlot(PlayerPosition.vol, 0.62, 0.64, TacticalLine.defensiveMid),
      FormationSlot(PlayerPosition.mc, 0.38, 0.64, TacticalLine.midfield),
      FormationSlot(PlayerPosition.ale, 0.12, 0.62, TacticalLine.midfield),
      FormationSlot(PlayerPosition.mei, 0.5, 0.46, TacticalLine.attackingMid),
      FormationSlot(PlayerPosition.ata, 0.60, 0.27, TacticalLine.attack),
      FormationSlot(PlayerPosition.sa, 0.40, 0.27, TacticalLine.attack),
    ],
  ),
  const Formation(
    id: '4-4-1-1',
    label: '4-4-1-1',
    slots: [
      FormationSlot(PlayerPosition.gol, 0.5, 0.93, TacticalLine.keeper),
      FormationSlot(PlayerPosition.ld, 0.85, 0.76, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.62, 0.80, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.38, 0.80, TacticalLine.defense),
      FormationSlot(PlayerPosition.le, 0.15, 0.76, TacticalLine.defense),
      FormationSlot(PlayerPosition.pd, 0.84, 0.57, TacticalLine.midfield),
      FormationSlot(PlayerPosition.mc, 0.60, 0.60, TacticalLine.midfield),
      FormationSlot(PlayerPosition.mc, 0.40, 0.60, TacticalLine.midfield),
      FormationSlot(PlayerPosition.pe, 0.16, 0.57, TacticalLine.midfield),
      FormationSlot(PlayerPosition.mei, 0.5, 0.41, TacticalLine.attackingMid),
      FormationSlot(PlayerPosition.ata, 0.5, 0.27, TacticalLine.attack),
    ],
  ),
  const Formation(
    id: '4-1-2-3',
    label: '4-1-2-3',
    slots: [
      FormationSlot(PlayerPosition.gol, 0.5, 0.93, TacticalLine.keeper),
      FormationSlot(PlayerPosition.ld, 0.85, 0.76, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.62, 0.80, TacticalLine.defense),
      FormationSlot(PlayerPosition.zag, 0.38, 0.80, TacticalLine.defense),
      FormationSlot(PlayerPosition.le, 0.15, 0.76, TacticalLine.defense),
      FormationSlot(PlayerPosition.vol, 0.5, 0.66, TacticalLine.defensiveMid),
      FormationSlot(PlayerPosition.mc, 0.62, 0.52, TacticalLine.midfield),
      FormationSlot(PlayerPosition.mc, 0.38, 0.52, TacticalLine.midfield),
      FormationSlot(PlayerPosition.pd, 0.82, 0.31, TacticalLine.attackingMid),
      FormationSlot(PlayerPosition.ata, 0.5, 0.27, TacticalLine.attack),
      FormationSlot(PlayerPosition.pe, 0.18, 0.31, TacticalLine.attackingMid),
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
