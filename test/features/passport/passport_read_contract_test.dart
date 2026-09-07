// Trava o CONTRATO DE LEITURA do Passaporte: exatamente quais chaves o
// `PassportMatch.fromMap` espera receber da RPC. Isso existe porque o
// Bragantino roda num projeto Supabase SEPARADO — quem for escrever as
// RPCs de lá precisa devolver estes nomes, e não os nomes crus da tabela.
//
// É também a rede de segurança do bug já conhecido do Goiás: a RPC
// `passport_matches_for_year` de lá devolve `goias_is_home`/`goias_score`,
// que o app NÃO lê (ele lê `club_is_home`/`club_score`), então esses dois
// campos chegam nulos em produção hoje.
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';

/// Uma linha como a RPC precisa devolvê-la.
Map<String, dynamic> row({Map<String, dynamic> overrides = const {}}) => {
  'id': 'pb_ogol_10779896',
  'season': 2025,
  'match_date': '2025-05-05',
  'match_time': '20:00:00',
  'kickoff_at': null,
  'status': 'FINISHED',
  'competition': 'Brasileirão Série A',
  'competition_code': 'BRASILEIRAO_A',
  'round': null,
  'opponent': 'Mirassol',
  'club_is_home': true,
  'neutral_site': false,
  'home_team': 'Red Bull Bragantino',
  'away_team': 'Mirassol',
  'home_score': 2,
  'away_score': 1,
  'club_score': 2,
  'opponent_score': 1,
  'score_display': '2–1',
  'outcome': 'WIN',
  'venue_name': 'Estádio Municipal Cícero de Souza Marques',
  'venue_city': 'Bragança Paulista',
  'attended': false,
  ...overrides,
};

void main() {
  group('contrato de leitura da RPC', () {
    test('mapeia a linha completa sem perder campo', () {
      final match = PassportMatch.fromMap(row());

      expect(match.id, 'pb_ogol_10779896');
      expect(match.season, 2025);
      expect(match.clubIsHome, isTrue);
      expect(match.clubScore, 2);
      expect(match.opponentScore, 1);
      expect(match.venueName, contains('Cícero de Souza Marques'));
      expect(match.venueCity, 'Bragança Paulista');
      expect(match.outcome, PassportOutcome.win);
      expect(match.status, PassportMatchStatus.finished);
    });

    test(
      'o estádio TEM que vir como venue_name — "stadium" cru não é lido',
      () {
        final match = PassportMatch.fromMap(
          row(overrides: {'venue_name': null})..['stadium'] = 'Nabi Abi Chedid',
        );
        expect(
          match.venueName,
          isNull,
          reason:
              'a RPC do Bragantino precisa fazer "stadium as venue_name"; '
              'sem o alias o app mostra a partida sem estádio',
        );
      },
    );

    test('mando/placar TÊM que vir como club_is_home/club_score', () {
      // Exatamente o formato que a RPC do Goiás devolve hoje (nomes
      // crus da coluna) — o app lê nulo nos dois.
      final legacy = row()
        ..remove('club_is_home')
        ..remove('club_score')
        ..['goias_is_home'] = true
        ..['goias_score'] = 2;

      final match = PassportMatch.fromMap(legacy);
      expect(match.clubIsHome, isNull);
      expect(match.clubScore, isNull);
    });
  });

  group('campos parcialmente desconhecidos não quebram nem viram invenção', () {
    test('horário desconhecido continua nulo', () {
      final match = PassportMatch.fromMap(
        row(overrides: {'match_time': null, 'kickoff_at': null}),
      );
      expect(match.matchTime, isNull);
      expect(match.kickoffAt, isNull);
    });

    test('estádio não confirmado continua nulo, sem placeholder', () {
      final match = PassportMatch.fromMap(
        row(overrides: {'venue_name': null, 'venue_city': null}),
      );
      expect(match.venueName, isNull);
      expect(match.venueCity, isNull);
    });

    test('rodada ausente é nullable', () {
      expect(
        PassportMatch.fromMap(row(overrides: {'round': null})).round,
        isNull,
      );
    });

    test('status fora do enum vira unknown em vez de estourar', () {
      final match = PassportMatch.fromMap(
        row(overrides: {'status': 'ALGO_NOVO'}),
      );
      expect(match.status, PassportMatchStatus.unknown);
    });

    test('partida não encerrada não tem placar nem resultado', () {
      final match = PassportMatch.fromMap(
        row(
          overrides: {
            'status': 'SCHEDULED',
            'home_score': null,
            'away_score': null,
            'club_score': null,
            'opponent_score': null,
            'score_display': null,
            'outcome': null,
          },
        ),
      );
      expect(match.isFinished, isFalse);
      expect(match.outcome, isNull);
      expect(match.clubScore, isNull);
    });
  });

  group('presença só em partida já jogada', () {
    test('encerrada e no passado pode marcar', () {
      final match = PassportMatch.fromMap(row());
      expect(match.canMarkAttendance, isTrue);
    });

    test('agendada não pode marcar', () {
      final match = PassportMatch.fromMap(
        row(overrides: {'status': 'SCHEDULED'}),
      );
      expect(match.canMarkAttendance, isFalse);
    });

    test('adiada não pode marcar', () {
      final match = PassportMatch.fromMap(
        row(overrides: {'status': 'POSTPONED'}),
      );
      expect(match.canMarkAttendance, isFalse);
    });

    test('data futura não pode marcar nem marcada como encerrada', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final match = PassportMatch.fromMap(
        row(
          overrides: {
            'match_date': future.toIso8601String().substring(0, 10),
            'season': future.year,
          },
        ),
      );
      expect(match.status, PassportMatchStatus.finished);
      expect(match.canMarkAttendance, isFalse);
    });
  });
}
