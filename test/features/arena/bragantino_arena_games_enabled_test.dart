// Habilitação de quiz/career_path/guess_player no Bragantino (2026-09-08) —
// prova que a rota/gate reage à mudança de `enabledArenaGames` com o
// CONFIG REAL do clube (não só o gate genérico já testado com fixture
// sintética em `capability_route_gate_test.dart`), e que `lineup` continua
// de fora (bloqueado por dado, não tocado nesta rodada).
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/capability_route_gate.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

void main() {
  group('enabledArenaGames do Bragantino', () {
    test('quiz e career_path habilitados; guess_player e lineup NÃO', () {
      final jogos = bragantinoClubConfig.capabilities.enabledArenaGames;
      expect(jogos, contains('quiz'));
      expect(jogos, contains('career_path'));
      expect(jogos, contains('player_identity'));
      expect(jogos, contains('tactical_identity'));
      expect(
        jogos,
        isNot(contains('guess_player')),
        reason:
            'BLOCKED em QA real: só 1/50 cards é data_status=verified '
            '(eligibleAsSecret), o sorteio do "segredo" seria sempre o '
            'mesmo jogador — nunca habilitar sem mais dado verificado.',
      );
      expect(
        jogos,
        isNot(contains('lineup')),
        reason:
            'bloqueado por dado (0/123 partidas publicáveis) — fora de '
            'escopo desta rodada, não tocar.',
      );
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

    test('Bragantino + guess_player continua bloqueado (BLOCKED em QA)', () {
      expect(
        capabilityGateRedirect('/arena/guess-player', capabilities),
        isNotNull,
      );
    });

    test('Bragantino + lineup continua bloqueado (dado insuficiente)', () {
      expect(capabilityGateRedirect('/arena/lineup', capabilities), isNotNull);
    });

    test('deep link não burla: /arena/guess-player nunca cai no jogo', () {
      final redirect = capabilityGateRedirect(
        '/arena/guess-player',
        capabilities,
      );
      expect(redirect, isNotNull);
      expect(redirect, isNot('/arena/guess-player'));
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
