import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/bragantino_player_identity_references.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_engine.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_reference_sets.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_references.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/bragantino_tactical_coach_references.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_coach_reference_sets.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_coach_references.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

import '../../core/club/synthetic_club_config.dart';

/// Converte uma referência no vetor de atributos equivalente, pra medir
/// distância entre DUAS referências usando `PlayerIdentityEngine.distanceTo`
/// — o mesmo z-score e a mesma RMS que o jogo usa de verdade, nunca uma
/// reimplementação da fórmula aqui.
PlayerIdentityAttributes _asAttributes(PlayerIdentityReference r) =>
    PlayerIdentityAttributes(
      creativity: r.creativity,
      definition: r.definition,
      leadership: r.leadership,
      intensity: r.intensity,
      technique: r.technique,
      tactics: r.tactics,
    );

({double min, double median, double max, String closestPair}) _playerSpread(
  List<PlayerIdentityReference> refs,
) {
  final engine = PlayerIdentityEngine(refs);
  final pairs = <(double, String)>[];
  for (var a = 0; a < refs.length; a++) {
    for (var b = a + 1; b < refs.length; b++) {
      pairs.add((
        engine.distanceTo(_asAttributes(refs[a]), refs[b]),
        '${refs[a].name} × ${refs[b].name}',
      ));
    }
  }
  pairs.sort((x, y) => x.$1.compareTo(y.$1));
  return (
    min: pairs.first.$1,
    median: pairs[pairs.length ~/ 2].$1,
    max: pairs.last.$1,
    closestPair: pairs.first.$2,
  );
}

/// Pesos espelhados de `TacticalIdentityEngine._weightedDistance` (privado).
/// Os dois datasets são medidos com ESTA mesma função, e o teste compara um
/// com o outro — se a métrica do motor mudar, os dois se movem juntos e a
/// comparação continua significando a mesma coisa.
const _wAxis = 0.225;
const _wHidden = 0.1375;

({double min, double median, double max, String closestPair}) _coachSpread(
  List<TacticalCoachReference> refs,
) {
  List<double> valuesOf(double Function(TacticalCoachReference) pick) =>
      refs.map(pick).toList();
  (double, double) stats(List<double> v) {
    final mean = v.reduce((a, b) => a + b) / v.length;
    final variance =
        v.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
        v.length;
    final sd = math.sqrt(variance);
    return (mean, sd == 0 ? 1.0 : sd);
  }

  final dims = <double Function(TacticalCoachReference)>[
    (c) => c.x,
    (c) => c.y,
    (c) => c.pressing.toDouble(),
    (c) => c.blockHeight.toDouble(),
    (c) => c.risk.toDouble(),
    (c) => c.structuralFluidity.toDouble(),
  ];
  final weights = [_wAxis, _wAxis, _wHidden, _wHidden, _wHidden, _wHidden];
  final st = dims.map((d) => stats(valuesOf(d))).toList();

  final pairs = <(double, String)>[];
  for (var a = 0; a < refs.length; a++) {
    for (var b = a + 1; b < refs.length; b++) {
      var sum = 0.0;
      for (var d = 0; d < dims.length; d++) {
        final za = (dims[d](refs[a]) - st[d].$1) / st[d].$2;
        final zb = (dims[d](refs[b]) - st[d].$1) / st[d].$2;
        sum += weights[d] * (za - zb) * (za - zb);
      }
      pairs.add((
        math.sqrt(sum),
        '${refs[a].coach} ${refs[a].period} × ${refs[b].coach} ${refs[b].period}',
      ));
    }
  }
  pairs.sort((x, y) => x.$1.compareTo(y.$1));
  return (
    min: pairs.first.$1,
    median: pairs[pairs.length ~/ 2].$1,
    max: pairs.last.$1,
    closestPair: pairs.first.$2,
  );
}

void main() {
  group('isolamento entre clubes', () {
    test('cada clube resolve o próprio dataset de jogadores', () {
      expect(
        playerIdentityReferenceSets.forClub('goias'),
        same(playerIdentityReferences),
      );
      expect(
        playerIdentityReferenceSets.forClub('bragantino'),
        same(bragantinoPlayerIdentityReferences),
      );
    });

    test('cada clube resolve o próprio dataset de técnicos', () {
      expect(
        tacticalCoachReferenceSets.forClub('goias'),
        same(tacticalCoachReferences),
      );
      expect(
        tacticalCoachReferenceSets.forClub('bragantino'),
        same(bragantinoTacticalCoachReferences),
      );
    });

    test('clube sem dataset lança, nunca cai no do Goiás', () {
      expect(
        () => playerIdentityEngineForClub(syntheticClubBConfig),
        throwsStateError,
      );
      expect(
        () => tacticalIdentityEngineForClub(syntheticClubBConfig),
        throwsStateError,
      );
    });

    test('o engine do Bragantino carrega SÓ referências do Bragantino', () {
      final ids = playerIdentityEngineForClub(
        bragantinoClubConfig,
      ).references.map((r) => r.id).toSet();
      final doGoias = playerIdentityReferences.map((r) => r.id).toSet();
      expect(ids.intersection(doGoias), isEmpty);

      final coaches = tacticalIdentityEngineForClub(
        bragantinoClubConfig,
      ).references.map((c) => c.id).toSet();
      expect(
        coaches.intersection(tacticalCoachReferences.map((c) => c.id).toSet()),
        isEmpty,
      );
    });

    test('o dataset do Goiás não mudou nada', () {
      // Se alguém "recalibrar" o Goiás junto com o Bragantino, isto quebra.
      expect(playerIdentityReferences, hasLength(21));
      expect(tacticalCoachReferences, hasLength(12));
      final harlei = playerIdentityReferences.firstWhere(
        (r) => r.id == 'harlei',
      );
      expect(
        [
          harlei.creativity,
          harlei.definition,
          harlei.leadership,
          harlei.intensity,
          harlei.technique,
          harlei.tactics,
        ],
        [27, 16, 87, 45, 34, 80],
      );
      expect(
        playerIdentityEngineForClub(goiasClubConfig).references,
        same(playerIdentityReferences),
      );
    });
  });

  group('integridade do dataset de jogadores do Bragantino', () {
    const refs = bragantinoPlayerIdentityReferences;

    test('21 referências, ids e nomes únicos', () {
      // Ampliado de 10 para 21 em 2026-09-10, igualando o Goiás — ver o
      // comentário no topo de bragantino_player_identity_references.dart.
      expect(refs, hasLength(21));
      expect(refs.map((r) => r.id).toSet(), hasLength(refs.length));
      expect(refs.map((r) => r.name).toSet(), hasLength(refs.length));
    });

    test('toda dimensão fica em 0–100 e o período nunca é vazio', () {
      for (final r in refs) {
        for (final d in PlayerIdentityDimension.values) {
          expect(r[d], inInclusiveRange(0, 100), reason: '${r.name} / $d');
        }
        expect(r.period.trim(), isNotEmpty, reason: r.name);
        expect(['high', 'medium', 'low'], contains(r.confidence));
      }
    });

    test('nenhum vestígio do Goiás nos textos', () {
      for (final r in refs) {
        final blob = '${r.id} ${r.name} ${r.period}'.toLowerCase();
        for (final termo in ['goiás', 'goias', 'esmeraldin', 'verdão']) {
          expect(blob, isNot(contains(termo)), reason: r.name);
        }
      }
    });

    test('médias por dimensão acompanham a distribuição do questionário', () {
      // O motor compara por z-score contra as estatísticas do próprio
      // dataset, e o comentário de calibragem do Goiás explica o risco: uma
      // cartela centrada MUITO acima do que o questionário produz enviesa a
      // comparação. O Goiás fica entre 50,0 e 54,8. O Bragantino, com o
      // elenco atual mais técnico (Cuello, Claudinho, Artur, Tiba, Lucas
      // Evangelista), fica um pouco acima disso em `technique` — faixa
      // alargada pra 62 pra caber esse perfil editorial sem afrouxar as
      // outras 5 dimensões.
      for (final d in PlayerIdentityDimension.values) {
        final mean =
            refs.map((r) => r[d]).reduce((a, b) => a + b) / refs.length;
        expect(
          mean,
          inInclusiveRange(40, 62),
          reason: '$d fora da faixa de calibragem: $mean',
        );
      }
    });

    test('perfis suficientemente distintos entre si', () {
      final braga = _playerSpread(refs);
      final goias = _playerSpread(playerIdentityReferences);

      expect(
        braga.min,
        greaterThanOrEqualTo(0.45),
        reason: 'par mais próximo: ${braga.closestPair} (${braga.min})',
      );
      // E menos aglomerado que o próprio Goiás, que é o material de
      // comparação real (mínima 0,290 em Harlei × Tadeu).
      expect(braga.min, greaterThan(goias.min));
      expect(braga.median, greaterThan(1.0));
    });
  });

  group('integridade do dataset de técnicos do Bragantino', () {
    const refs = bragantinoTacticalCoachReferences;

    test('12 referências, ids e rótulos únicos', () {
      // Ampliado de 6 para 12 em 2026-09-10, igualando o Goiás — ver o
      // comentário no topo de bragantino_tactical_coach_references.dart.
      expect(refs, hasLength(12));
      expect(refs.map((c) => c.id).toSet(), hasLength(refs.length));
      // Técnico pode repetir em passagens diferentes, então o rótulo único é
      // o par técnico+período.
      expect(
        refs.map((c) => '${c.coach}|${c.period}').toSet(),
        hasLength(refs.length),
      );
    });

    test('eixos em -100..100 e auxiliares em 0–100', () {
      for (final c in refs) {
        expect(c.x, inInclusiveRange(-100, 100), reason: c.coach);
        expect(c.y, inInclusiveRange(-100, 100), reason: c.coach);
        for (final v in [
          c.pressing,
          c.blockHeight,
          c.risk,
          c.structuralFluidity,
        ]) {
          expect(v, inInclusiveRange(0, 100), reason: c.coach);
        }
        expect(c.period.trim(), isNotEmpty);
        expect(['high', 'medium', 'low'], contains(c.confidence));
      }
    });

    test('nenhum vestígio do Goiás nos textos', () {
      for (final c in refs) {
        final blob = '${c.id} ${c.coach} ${c.period}'.toLowerCase();
        for (final termo in ['goiás', 'goias', 'esmeraldin', 'verdão']) {
          expect(blob, isNot(contains(termo)), reason: c.coach);
        }
      }
    });

    test('técnicos distinguíveis entre si', () {
      final braga = _coachSpread(refs);
      final goias = _coachSpread(tacticalCoachReferences);

      expect(
        braga.min,
        greaterThanOrEqualTo(0.45),
        reason: 'par mais próximo: ${braga.closestPair} (${braga.min})',
      );
      expect(braga.min, greaterThan(goias.min));
    });

    test('os dois eixos são realmente usados, não uma nuvem só', () {
      // Um dataset em que todo mundo cai no mesmo quadrante deixaria o mapa
      // 2D sem função nenhuma.
      expect(
        refs.where((c) => c.x < 0),
        isNotEmpty,
        reason: 'ninguém de posse',
      );
      expect(
        refs.where((c) => c.x > 0),
        isNotEmpty,
        reason: 'ninguém vertical',
      );
      expect(
        refs.where((c) => c.y < 0),
        isNotEmpty,
        reason: 'ninguém dogmático',
      );
      expect(
        refs.where((c) => c.y > 0),
        isNotEmpty,
        reason: 'ninguém pragmático',
      );
    });
  });

  group('os jogos de identidade do Bragantino', () {
    test('enabledArenaGames inclui os dois após a revisão de 2026-09-08', () {
      final jogos = bragantinoClubConfig.capabilities.enabledArenaGames;
      expect(jogos, contains('player_identity'));
      expect(jogos, contains('tactical_identity'));
    });
  });
}
