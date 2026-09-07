// Adivinhe a Escalação — isolamento multiclube + contrato do pool do
// Bragantino. Hoje o Bragantino NÃO tem desafio publicável (falta formação
// e posição por jogador na fonte, ver tooling/bragantino_lineup), então o
// que estes testes travam é justamente isso: o jogo fica escondido e, se
// alguém forçar a rota, nada do Goiás aparece no lugar.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/arena/games/lineup/data/lineup_match_repository.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_matches.dart';

void main() {
  group('capability — o jogo só aparece pra quem tem conteúdo', () {
    test('Goiás tem lineup habilitado no Arena', () {
      expect(
        goiasClubConfig.capabilities.enabledArenaGames,
        contains('lineup'),
      );
    });

    test(
      'Bragantino NÃO tem lineup habilitado enquanto não houver desafio',
      () {
        expect(
          bragantinoClubConfig.capabilities.enabledArenaGames,
          isNot(contains('lineup')),
        );
      },
    );
  });

  group('fallback offline nunca cruza de clube', () {
    test('só o Goiás tem fallback local de partidas', () {
      expect(orderedLineupMatchesFallback.forClub('goias'), isNotNull);
      expect(orderedLineupMatchesFallback.forClub('bragantino'), isNull);
    });

    test('o fallback do Goiás continua com as 31 partidas dele', () {
      expect(orderedLineupMatchesFallback.forClub('goias'), hasLength(31));
      expect(orderedLineupMatches, hasLength(31));
    });

    test('toda partida do Goiás tem exatamente 11 titulares', () {
      for (final match in orderedLineupMatches) {
        expect(match.players, hasLength(11), reason: match.id);
      }
    });
  });

  group('pool do Bragantino (LINEUP_SHORTLIST_V2) — contrato de dados', () {
    final pool =
        jsonDecode(
              File(
                'tooling/bragantino_passport/source/lineup_shortlist_v2.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final recent =
        (pool['recent_lineups'] as Map<String, dynamic>)['matches'] as List;
    final historical =
        (pool['historical_lineups'] as Map<String, dynamic>)['matches'] as List;

    test('toda partida do pool tem exatamente 11 titulares', () {
      for (final match in recent) {
        final xi = (match as Map<String, dynamic>)['starting_xi'] as List;
        expect(xi, hasLength(11), reason: match['source_match_id'] as String);
      }
    });

    test(
      'reserva que entrou não é contado como titular (semântica do parser)',
      () {
        // Identidade é o `player_id` da fonte, NUNCA o nome: existe pelo
        // menos um caso real de dois atletas diferentes com o mesmo
        // apelido no mesmo jogo (Vitinho #28 titular e Vitinho #50 do
        // banco, em 2024-11-02 contra o Cuiabá) — comparar por nome
        // acusaria um falso positivo aí.
        // Parte das fichas antigas do oGol não traz `data-player-id` (o
        // parser guarda `null` em vez de inventar um) — nesses casos a
        // identidade usada é nome+camisa, que também separa o homônimo.
        String identity(Map<String, dynamic> player) =>
            player['player_id'] as String? ??
            '${player['name']}#${player['number']}';

        for (final match in recent) {
          final map = match as Map<String, dynamic>;
          final xiIds = (map['starting_xi'] as List)
              .cast<Map<String, dynamic>>()
              .map(identity)
              .toSet();
          final subs = (map['used_substitutes'] as List)
              .cast<Map<String, dynamic>>();
          for (final sub in subs) {
            expect(
              xiIds,
              isNot(contains(identity(sub))),
              reason:
                  '${sub['name']} entrou durante o jogo, não pode estar no XI '
                  'de ${map['source_match_id']}',
            );
          }
        }
      },
    );

    test(
      'homônimo no mesmo jogo é dado real, não duplicata a ser "corrigida"',
      () {
        final match = recent.cast<Map<String, dynamic>>().firstWhere(
          (m) => m['source_match_id'] == '9985987',
        );
        final starter = (match['starting_xi'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((p) => p['name'] == 'Vitinho');
        final substitute = (match['used_substitutes'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((p) => p['name'] == 'Vitinho');

        expect(starter['player_id'], isNot(substitute['player_id']));
        expect(starter['number'], isNot(substitute['number']));
      },
    );

    test('camisas do XI ficam na faixa válida, sem duplicata na partida', () {
      for (final match in recent) {
        final map = match as Map<String, dynamic>;
        final numbers = (map['starting_xi'] as List)
            .cast<Map<String, dynamic>>()
            .map((p) => p['number'] as int)
            .toList();
        expect(
          numbers.toSet(),
          hasLength(11),
          reason: 'camisa repetida em ${map['source_match_id']}',
        );
        for (final number in numbers) {
          expect(number, inInclusiveRange(1, 99));
        }
      }
    });

    test('a correção manual de camisa continua aplicada e documentada', () {
      final corrected = recent
          .cast<Map<String, dynamic>>()
          .where((m) => m['manual_corrections'] != null)
          .toList();
      expect(
        corrected,
        isNotEmpty,
        reason: 'a correção 300 -> 1 precisa continuar registrada',
      );
      for (final match in corrected) {
        final note = match['manual_corrections'] as String;
        expect(note, isNotEmpty);
        // provenance: a nota tem que dizer o que mudou, não só "corrigido".
        expect(note, contains('300'));
        final numbers = (match['starting_xi'] as List)
            .cast<Map<String, dynamic>>()
            .map((p) => p['number'] as int);
        expect(numbers, isNot(contains(300)));
      }
    });

    test(
      'HISTORICAL_LINEUPS: 15 partidas curadas em 2026-09-07 (XI nominal '
      'validado, sem número de camisa/formação forjados)',
      () {
        expect(historical, hasLength(15));
        expect(
          (pool['historical_lineups']
              as Map<String, dynamic>)['research_status'],
          'CURATED_NO_FORMATION_YET',
        );
        for (final match in historical) {
          final map = match as Map<String, dynamic>;
          final xi = (map['starting_xi'] as List).cast<Map<String, dynamic>>();
          expect(xi, hasLength(11), reason: map['source_match_id'] as String);
          // Nenhum número de camisa inventado — todo mundo fica null até
          // existir fonte real por partida.
          for (final player in xi) {
            expect(player['number'], isNull, reason: player['name'] as String);
          }
        }
      },
    );

    test('nenhuma partida do pool referencia o Goiás', () {
      for (final match in recent) {
        final map = match as Map<String, dynamic>;
        expect(map['opponent'], isNot(equals('Goiás')));
        expect(
          (map['source_url'] as String).toLowerCase(),
          isNot(contains('goias')),
        );
      }
    });
  });

  group('relatório de elegibilidade — nada é publicado sem formação', () {
    final reportFile = File(
      'tooling/bragantino_lineup/out/eligibility_report.json',
    );

    test('o relatório existe e cobre o pool inteiro (123 RECENT + 15 HISTORICAL)', () {
      expect(reportFile.existsSync(), isTrue);
      final report =
          jsonDecode(reportFile.readAsStringSync()) as Map<String, dynamic>;
      expect(report['avaliadas'], 138);
      expect(report['rejeitadas'], report['avaliadas']);
    });

    test('zero publicáveis hoje, com motivo explícito registrado', () {
      final report =
          jsonDecode(reportFile.readAsStringSync()) as Map<String, dynamic>;
      expect(report['publicaveis'], 0);
      final reasons = report['motivos'] as Map<String, dynamic>;
      expect(reasons['SEM_FORMACAO'], 138);
      expect(reasons['SEM_POSICAO_POR_JOGADOR'], 138);
    });
  });
}
