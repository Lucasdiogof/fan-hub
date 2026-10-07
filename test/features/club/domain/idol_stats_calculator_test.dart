import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/club/domain/idol_stats_calculator.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';

import '../idol_stats_fixtures.dart';

({int appearances, int? goals, int counted}) run(
  List<IdolMatchRecord> records,
) {
  final stats = computeIdolStats(
    tracking: tadeuTracking,
    clubTeamId: clubTeamId,
    records: records,
  );
  return (
    appearances: stats.appearances,
    goals: stats.goals,
    counted: stats.countedMatches,
  );
}

void main() {
  group('baseline do Tadeu (dado histórico auditado)', () {
    test('é 406 jogos / 13 gols até Novorizontino x Goiás (01/10/2026)', () {
      final b = tadeuTracking.baseline;
      expect(b.appearances, 406);
      expect(b.goals, 13);
      expect(b.throughMatchId, baselineMatchId);
      expect(b.throughDate, '2026-10-01');
      expect(tadeuTracking.providerPlayerId, 48597);
    });
  });

  group('jogos', () {
    test('1) só baseline: nenhuma partida posterior => 406', () {
      final r = run([]);
      expect(r.appearances, 406);
      expect(r.goals, 13);
    });

    test('2) titular em partida posterior => 407', () {
      final r = run([
        record(id: 'onef-1', kickoff: after1, starters: [tadeuStarter]),
      ]);
      expect(r.appearances, 407);
      expect(r.counted, 1);
    });

    test('3) começou no banco e entrou => 407', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [starter('Outro Goleiro', 111)],
          events: [sub('Tadeu')],
        ),
      ]);
      expect(r.appearances, 407);
    });

    test('4) relacionado mas não entrou => 406', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [starter('Outro Goleiro', 111)],
          events: [sub('Um Zagueiro')],
        ),
      ]);
      expect(r.appearances, 406);
      expect(r.counted, 0);
    });

    test('5) a partida que fecha o baseline NÃO é contada de novo', () {
      final r = run([
        record(
          id: baselineMatchId,
          kickoff: DateTime.utc(2026, 10, 2),
          starters: [tadeuStarter],
          home: false,
        ),
      ]);
      expect(r.appearances, 406);
    });

    test(
      '5b) partida anterior ao baseline (ou no mesmo horário) nunca entra',
      () {
        final r = run([
          record(
            id: 'onef-velha',
            kickoff: DateTime.utc(2026, 9, 26, 21, 30),
            starters: [tadeuStarter],
          ),
          record(
            id: 'onef-mesmo-horario',
            kickoff: DateTime.utc(2026, 10, 2),
            starters: [tadeuStarter],
          ),
        ]);
        expect(r.appearances, 406);
      },
    );

    test(
      '6) idempotência: o mesmo conjunto processado de novo não muda nada',
      () {
        final records = [
          record(id: 'onef-1', kickoff: after1, starters: [tadeuStarter]),
        ];
        expect(run(records).appearances, 407);
        expect(run(records).appearances, 407);
        expect(run([...records, ...records, ...records]).appearances, 407);
        // 50 vezes a mesma partida continua 407, nunca 456.
        expect(run(List.generate(50, (_) => records.first)).appearances, 407);
      },
    );

    test('7) múltiplas partidas: 3 aparições válidas => 409', () {
      final r = run([
        record(id: 'onef-1', kickoff: after1, starters: [tadeuStarter]),
        record(
          id: 'onef-2',
          kickoff: after2,
          starters: [starter('Outro', 111)],
          events: [sub('Tadeu')],
        ),
        record(
          id: 'onef-3',
          kickoff: after3,
          starters: [tadeuStarter],
          home: false,
        ),
        // Esta ele não jogou:
        record(
          id: 'onef-4',
          kickoff: DateTime.utc(2026, 10, 26, 21, 30),
          starters: [starter('Outro', 111)],
        ),
      ]);
      expect(r.appearances, 409);
      expect(r.counted, 3);
    });

    test('a ordem em que as partidas chegam não altera o resultado', () {
      final a = record(id: 'onef-1', kickoff: after1, starters: [tadeuStarter]);
      final b = record(id: 'onef-2', kickoff: after2, starters: [tadeuStarter]);
      expect(run([a, b]).appearances, run([b, a]).appearances);
    });

    test(
      'só partida FINALIZADA conta (agendada, ao vivo, adiada, cancelada)',
      () {
        for (final status in [
          MatchStatus.scheduled,
          MatchStatus.live,
          MatchStatus.halftime,
          MatchStatus.postponed,
          MatchStatus.cancelled,
          MatchStatus.suspended,
          MatchStatus.unknown,
        ]) {
          final r = run([
            record(
              id: 'onef-1',
              kickoff: after1,
              status: status,
              starters: [tadeuStarter],
            ),
          ]);
          expect(r.appearances, 406, reason: status.name);
        }
      },
    );

    test('prévia de escalação com Tadeu titular em jogo AGENDADO não conta '
        '(caso real de 06/10: status scheduled, 0 eventos)', () {
      final r = run([
        record(
          id: 'onef-2669548',
          kickoff: after1,
          status: MatchStatus.scheduled,
          starters: [tadeuStarter],
        ),
      ]);
      expect(r.appearances, 406);
    });

    test(
      'sem escalação publicada e sem evento: sem evidência => não conta',
      () {
        final r = run([
          record(id: 'onef-1', kickoff: after1, withLineups: false),
        ]);
        expect(r.appearances, 406);
      },
    );
  });

  group('identidade', () {
    test(
      'titular é reconhecido pelo ID, mesmo com o nome escrito diferente',
      () {
        final r = run([
          record(
            id: 'onef-1',
            kickoff: after1,
            starters: [starter('Tadeu Antônio Ferreira', 48597)],
          ),
        ]);
        expect(r.appearances, 407);
      },
    );

    test('jogador de mesmo nome com OUTRO ID não é o Tadeu', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [starter('Tadeu', 777)],
        ),
      ]);
      expect(r.appearances, 406);
    });

    test('homônimo com outro ID na escalação invalida entrada por nome', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [starter('Tadeu', 777)],
          events: [sub('Tadeu')],
        ),
      ]);
      expect(r.appearances, 406);
    });

    test('sem ID na escalação (foto genérica), cai no nome exato', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [starter('Tadeu', null)],
        ),
      ]);
      expect(r.appearances, 407);
    });

    test('Tadeu do ADVERSÁRIO (outro lado) nunca conta', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [starter('Outro', 111)],
          events: [sub('Tadeu', side: MatchEventSide.away)],
        ),
      ]);
      expect(r.appearances, 406);
    });

    test('partida em que o Goiás nem joga é ignorada', () {
      final base = record(id: 'x', kickoff: after1, starters: [tadeuStarter]);
      final stranger = IdolMatchRecord(
        match: Match(
          id: 'x',
          competition: 'Outra',
          round: '1',
          homeTeam: base.match.awayTeam,
          awayTeam: base.match.awayTeam,
          stadium: '',
          kickoff: after1,
          status: MatchStatus.finished,
        ),
        events: const [],
        lineups: base.lineups,
      );
      expect(run([stranger]).appearances, 406);
    });
  });

  group('substituição: ID prevalece, nome é fallback seguro', () {
    final others = [starter('Outro Goleiro', 111)];

    test(
      'reserva entra com o ID correto => conta (mesmo com nome diferente)',
      () {
        final r = run([
          record(
            id: 'onef-1',
            kickoff: after1,
            starters: others,
            events: [subWithId('Tadeu A. Ferreira', 48597)],
          ),
        ]);
        expect(r.appearances, 407);
      },
    );

    test('mesmo NOME com ID diferente não conta', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: others,
          events: [subWithId('Tadeu', 777)],
        ),
      ]);
      expect(r.appearances, 406);
    });

    test('substituição do ADVERSÁRIO com o ID dele não conta', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: others,
          events: [subWithId('Tadeu', 48597, side: MatchEventSide.away)],
        ),
      ]);
      expect(r.appearances, 406);
    });

    test('o ID prevalece sobre o nome: nome certo + ID de outro => não conta; '
        'nome estranho + ID certo => conta', () {
      expect(
        run([
          record(
            id: 'a',
            kickoff: after1,
            starters: others,
            events: [subWithId('Tadeu', 555)],
          ),
        ]).appearances,
        406,
      );
      expect(
        run([
          record(
            id: 'b',
            kickoff: after1,
            starters: others,
            events: [subWithId('Fulano Qualquer', 48597)],
          ),
        ]).appearances,
        407,
      );
    });

    test(
      'payload antigo (sem ID no evento) segue pelo fallback do nome exato',
      () {
        final r = run([
          record(
            id: 'onef-1',
            kickoff: after1,
            starters: others,
            events: [sub('Tadeu')],
          ),
        ]);
        expect(r.appearances, 407);
      },
    );

    test('fallback por nome é exato: pedaço de nome ou parecido NÃO conta', () {
      for (final name in ['Tade', 'Tadeu Silva', 'Tadeus', 'Tadeu Antônio']) {
        final r = run([
          record(
            id: 'onef-1',
            kickoff: after1,
            starters: others,
            events: [sub(name)],
          ),
        ]);
        expect(r.appearances, 406, reason: name);
      }
    });

    test('fallback por nome continua exigindo o lado do Goiás e unicidade '
        '(homônimo com outro ID na escalação invalida)', () {
      final adversario = run([
        record(
          id: 'a',
          kickoff: after1,
          starters: others,
          events: [sub('Tadeu', side: MatchEventSide.away)],
        ),
      ]);
      expect(adversario.appearances, 406);
      final homonimo = run([
        record(
          id: 'b',
          kickoff: after1,
          starters: [starter('Tadeu', 777)],
          events: [sub('Tadeu')],
        ),
      ]);
      expect(homonimo.appearances, 406);
    });
  });

  group('gols', () {
    test('8) baseline + gols posteriores do jogador', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [tadeuStarter],
          events: [
            goal('Tadeu', detail: 'Pênalti'),
            goal('Tadeu'),
          ],
        ),
      ]);
      expect(r.goals, 15);
      expect(r.appearances, 407);
    });

    test('gol contra, gol do adversário e gol de outro jogador não contam', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [tadeuStarter],
          events: [
            goal('Tadeu', detail: 'Contra'),
            goal('Tadeu', side: MatchEventSide.away),
            goal('Outro Jogador'),
          ],
        ),
      ]);
      expect(r.goals, 13);
    });

    test('evento que não é gol (cartão, pênalti perdido) não conta', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [tadeuStarter],
          events: const [
            MatchEvent(
              minute: "10'",
              side: MatchEventSide.home,
              type: MatchEventType.yellowCard,
              player: 'Tadeu',
            ),
            MatchEvent(
              minute: "80'",
              side: MatchEventSide.home,
              type: MatchEventType.other,
              player: 'Tadeu',
              detail: 'Pênalti perdido',
            ),
          ],
        ),
      ]);
      expect(r.goals, 13);
    });

    test('gol em partida em que ele não jogou não conta', () {
      final r = run([
        record(
          id: 'onef-1',
          kickoff: after1,
          starters: [starter('Outro', 111)],
          events: [goal('Tadeu')],
        ),
      ]);
      expect(r.goals, 13);
      expect(r.appearances, 406);
    });

    test('gol idempotente: partida repetida não duplica o gol', () {
      final one = record(
        id: 'onef-1',
        kickoff: after1,
        starters: [tadeuStarter],
        events: [goal('Tadeu')],
      );
      expect(run([one, one, one]).goals, 14);
    });
  });

  group('data de referência', () {
    test('sem partida posterior fica a data do baseline', () {
      final stats = computeIdolStats(
        tracking: tadeuTracking,
        clubTeamId: clubTeamId,
        records: const [],
      );
      expect(stats.asOfDate, '2026-10-01');
    });

    test(
      'avança até a última partida posterior verificada (mesmo sem ele)',
      () {
        final stats = computeIdolStats(
          tracking: tadeuTracking,
          clubTeamId: clubTeamId,
          records: [
            record(id: 'onef-1', kickoff: after1, starters: [starter('X', 1)]),
          ],
        );
        expect(stats.asOfDate, '2026-10-06');
        expect(stats.appearances, 406);
      },
    );
  });
}
