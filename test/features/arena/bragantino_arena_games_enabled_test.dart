// Habilitação de jogos no Bragantino (2026-09-08: quiz/career_path;
// 2026-09-11: guess_player/lineup) — prova que a rota/gate reage à mudança
// de `enabledArenaGames` com o CONFIG REAL do clube (não só o gate genérico
// já testado com fixture sintética em `capability_route_gate_test.dart`).
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/capability_route_gate.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

void main() {
  group('enabledArenaGames do Bragantino', () {
    test('quiz, career_path, guess_player e lineup habilitados (reauditoria '
        '2026-09-11: 50/50 guess_players verified+elegíveis, 31/31 lineup_matches '
        'com 11 jogadores completos)', () {
      final jogos = bragantinoClubConfig.capabilities.enabledArenaGames;
      expect(jogos, contains('quiz'));
      expect(jogos, contains('career_path'));
      expect(jogos, contains('player_identity'));
      expect(jogos, contains('tactical_identity'));
      expect(jogos, contains('guess_player'));
      expect(jogos, contains('lineup'));
    });
  });

  group('gate de rota — config REAL do Bragantino pós-habilitação', () {
    final capabilities = bragantinoClubConfig.capabilities;

    test('Bragantino + quiz enabled -> /arena/quiz libera', () {
      expect(capabilityGateRedirect('/arena/quiz', capabilities), isNull);
    });

    test('Bragantino + career_path enabled -> /arena/career-path libera', () {
      expect(
        capabilityGateRedirect('/arena/career-path', capabilities),
        isNull,
      );
    });

    test('Bragantino + guess_player enabled -> /arena/guess-player libera', () {
      expect(
        capabilityGateRedirect('/arena/guess-player', capabilities),
        isNull,
      );
    });

    test('Bragantino + lineup enabled -> /arena/lineup libera', () {
      expect(capabilityGateRedirect('/arena/lineup', capabilities), isNull);
    });
  });

  group('Goiás — comportamento atual preservado, nenhuma regressão', () {
    final capabilities = goiasClubConfig.capabilities;

    for (final path in [
      '/arena/quiz',
      '/arena/career-path',
      '/arena/guess-player',
      '/arena/lineup',
    ]) {
      test('$path continua liberado', () {
        expect(capabilityGateRedirect(path, capabilities), isNull);
      });
    }
  });
}
