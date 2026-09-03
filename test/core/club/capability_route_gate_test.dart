import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/capability_route_gate.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

import 'synthetic_club_config.dart';

/// M4.2A — `capabilityGateRedirect` é uma função PURA (sem `BuildContext`/
/// GoRouter), testável sozinha: prova que TODA navegação (não só um card
/// escondido) pra uma feature desligada cai no destino genérico — isso é o
/// que faz "deep link não burla o gate" ser uma garantia estrutural, não
/// uma esperança de que ninguém esqueceu de esconder um botão.
void main() {
  group('Goiás (todas as capabilities true) — nunca bloqueado', () {
    final capabilities = goiasClubConfig.capabilities;

    for (final path in [
      '/',
      '/arena',
      '/arena/ranking',
      '/arena/quiz',
      '/arena/quiz/play',
      '/arena/lineup',
      '/arena/career-path',
      '/arena/guess-player',
      '/arena/tactical-identity',
      '/arena/tactical-identity/play',
      '/arena/player-identity',
      '/arena/passport',
      '/arena/passport/ranking',
      '/store',
      '/store/product/123',
      '/membership/plans',
      '/tickets',
      '/tickets/my',
      '/crowd-lineup',
      '/news',
      '/news/article',
      '/squad',
      '/squad/123',
      '/profile/notifications',
    ]) {
      test('$path -> null (liberado)', () {
        expect(capabilityGateRedirect(path, capabilities), isNull);
      });
    }
  });

  group('club-b sintético — bloqueado exatamente onde a capability é false', () {
    final capabilities = syntheticClubBConfig.capabilities;

    test('hasPassport=false: /arena/passport e sub-rotas bloqueadas', () {
      expect(
        capabilityGateRedirect('/arena/passport', capabilities),
        featureUnavailableRoute,
      );
      expect(
        capabilityGateRedirect('/arena/passport/ranking', capabilities),
        featureUnavailableRoute,
      );
    });

    test('hasStore=false: /store e sub-rotas bloqueadas', () {
      expect(
        capabilityGateRedirect('/store', capabilities),
        featureUnavailableRoute,
      );
      expect(
        capabilityGateRedirect('/store/product/123', capabilities),
        featureUnavailableRoute,
      );
      expect(
        capabilityGateRedirect('/store/checkout', capabilities),
        featureUnavailableRoute,
      );
    });

    test('hasMembership=false: /membership e sub-rotas bloqueadas', () {
      expect(
        capabilityGateRedirect('/membership/plans', capabilities),
        featureUnavailableRoute,
      );
      expect(
        capabilityGateRedirect('/membership/my', capabilities),
        featureUnavailableRoute,
      );
    });

    test('hasTickets=false: /tickets e sub-rotas bloqueadas', () {
      expect(
        capabilityGateRedirect('/tickets', capabilities),
        featureUnavailableRoute,
      );
      expect(
        capabilityGateRedirect('/tickets/my', capabilities),
        featureUnavailableRoute,
      );
    });

    test('hasCrowdLineup=false: /crowd-lineup bloqueada', () {
      expect(
        capabilityGateRedirect('/crowd-lineup', capabilities),
        featureUnavailableRoute,
      );
    });

    test('hasNews=false: /news bloqueada', () {
      expect(
        capabilityGateRedirect('/news', capabilities),
        featureUnavailableRoute,
      );
      expect(
        capabilityGateRedirect('/news/article', capabilities),
        featureUnavailableRoute,
      );
    });

    test(
      'enabledArenaGames = {quiz}: só /arena/quiz liberado, os outros 5 jogos bloqueados',
      () {
        expect(capabilityGateRedirect('/arena/quiz', capabilities), isNull);
        expect(
          capabilityGateRedirect('/arena/quiz/play', capabilities),
          isNull,
        );
        for (final blocked in [
          '/arena/lineup',
          '/arena/career-path',
          '/arena/guess-player',
          '/arena/tactical-identity',
          '/arena/player-identity',
        ]) {
          expect(
            capabilityGateRedirect(blocked, capabilities),
            featureUnavailableRoute,
            reason: blocked,
          );
        }
      },
    );

    test(
      '/arena (hub) e /arena/ranking liberados — tem ao menos 1 jogo (quiz)',
      () {
        expect(capabilityGateRedirect('/arena', capabilities), isNull);
        expect(capabilityGateRedirect('/arena/ranking', capabilities), isNull);
      },
    );

    test('Squad e Notificações NUNCA gateadas, mesmo pro clube sintético', () {
      expect(capabilityGateRedirect('/squad', capabilities), isNull);
      expect(capabilityGateRedirect('/squad/123', capabilities), isNull);
      expect(
        capabilityGateRedirect('/profile/notifications', capabilities),
        isNull,
      );
    });

    test('nunca redireciona a própria rota de indisponível (sem loop)', () {
      expect(
        capabilityGateRedirect(featureUnavailableRoute, capabilities),
        isNull,
      );
    });
  });

  group('FABRICADO — hub do Arena cai se NENHUM jogo estiver habilitado', () {
    test('enabledArenaGames vazio -> /arena e /arena/ranking bloqueados', () {
      const emptyArenaCapabilities = ClubCapabilities(
        hasMembership: false,
        hasStore: false,
        hasTickets: false,
        hasCrowdLineup: false,
        hasPassport: false,
        hasNews: false,
        hasSocial: false,
        enabledArenaGames: {},
      );
      expect(
        capabilityGateRedirect('/arena', emptyArenaCapabilities),
        featureUnavailableRoute,
      );
      expect(
        capabilityGateRedirect('/arena/ranking', emptyArenaCapabilities),
        featureUnavailableRoute,
      );
    });
  });

  group('FABRICADO — colisão de prefixo nunca confunde /arena com /arena/passport', () {
    test(
      'clube com jogos habilitados mas hasPassport=false: /arena liberado, /arena/passport bloqueado',
      () {
        const capabilities = ClubCapabilities(
          hasMembership: false,
          hasStore: false,
          hasTickets: false,
          hasCrowdLineup: false,
          hasPassport: false,
          hasNews: false,
          hasSocial: false,
          enabledArenaGames: {'quiz'},
        );
        expect(capabilityGateRedirect('/arena', capabilities), isNull);
        expect(
          capabilityGateRedirect('/arena/passport', capabilities),
          featureUnavailableRoute,
        );
      },
    );
  });
}
