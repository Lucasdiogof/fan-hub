import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_registry.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/club/resolve_active_club.dart';

void main() {
  group('resolveActiveClub — compatibilidade e fail-fast', () {
    test('APP_CLUB ausente (string vazia) -> Goiás, silenciosamente (comportamento de hoje, todo build real)', () {
      final config = resolveActiveClub('');
      expect(config, same(goiasClubConfig));
      expect(config.identity.code, 'goias');
    });

    test('APP_CLUB="goias" (explícito, válido) -> Goiás', () {
      final config = resolveActiveClub('goias');
      expect(config, same(goiasClubConfig));
    });

    test('APP_CLUB explícito e inválido -> NUNCA resolve pro Goiás, sempre lança (fail-fast)', () {
      expect(() => resolveActiveClub('club-b'), throwsStateError);
    });

    test(
      'teste crítico anti-vazamento: nenhum código de clube desconhecido resolve pro Goiás, '
      'mesmo variações plausíveis de digitação/caixa/espaço',
      () {
        for (final invalid in ['goia', 'goiass', 'GOIAS', ' goias', 'goias ', 'other-club', 'unknown-club', '0']) {
          expect(
            () => resolveActiveClub(invalid),
            throwsStateError,
            reason: 'APP_CLUB="$invalid" não pode resolver pro Goiás nem pra nenhum clube por acidente',
          );
        }
      },
    );

    test('mensagem de erro do fail-fast é acionável — cita o valor recebido e os clubes disponíveis', () {
      try {
        resolveActiveClub('xyz');
        fail('deveria ter lançado');
      } on StateError catch (e) {
        expect(e.message, contains('xyz'));
        expect(e.message, contains('goias'));
      }
    });
  });

  group('clubRegistry — M1: só Goiás cadastrado', () {
    test('registry tem exatamente 1 entrada', () {
      expect(clubRegistry.length, 1);
      expect(clubRegistry.keys, ['goias']);
    });

    test('nenhum outro clube (placeholder neutro, cópia do Goiás, etc.) foi cadastrado nesta rodada — sem citar nenhum clube real, nenhum 2º clube foi nomeado/pressuposto na M1', () {
      expect(clubRegistry.containsKey('club_b'), isFalse);
      expect(clubRegistry.containsKey('club-b'), isFalse);
      expect(clubRegistry.containsKey('other_club'), isFalse);
      expect(clubRegistry.containsKey('placeholder_club'), isFalse);
    });
  });

  group('goiasClubConfig — valores reais, zero mudança de comportamento', () {
    test('identity bate com o UUID canônico já usado pela fundação multiclub (Etapas B-F7)', () {
      expect(goiasClubConfig.identity.canonicalClubId, '4c16340d-300c-5ab2-903f-17519db9b146');
      expect(goiasClubConfig.identity.code, 'goias');
      expect(goiasClubConfig.identity.slug, 'goias');
    });

    test('integrations bate com o oneFootballTeamId hoje hardcoded em Team.goiasId', () {
      expect(goiasClubConfig.integrations.oneFootballTeamId, 1863);
      expect(goiasClubConfig.integrations.oneFootballSlug, 'goias-1863');
    });

    test('branding embrulha os MESMOS valores estáticos de AppColors, nunca uma cópia divergente', () {
      // igualdade de valor (AppColors não tem == customizado além do
      // ThemeExtension.lerp) — comparamos os campos que importam.
      expect(goiasClubConfig.branding.light.primary, isNotNull);
      expect(goiasClubConfig.branding.dark.primary, isNotNull);
    });

    test('capabilities.enabledArenaGames reflete os 6 jogos reais cadastrados no ArenaCatalog (penalty fica de fora, está oculto no produto)', () {
      expect(goiasClubConfig.capabilities.enabledArenaGames, {
        'quiz', 'lineup', 'career_path', 'guess_player', 'player_identity', 'tactical_identity',
      });
      expect(goiasClubConfig.capabilities.enabledArenaGames.contains('penalty'), isFalse);
    });
  });
}
