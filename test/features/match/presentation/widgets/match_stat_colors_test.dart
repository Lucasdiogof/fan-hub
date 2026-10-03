import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/match_stat_colors.dart';

const _goiasId = 1863; // goiasClubConfig.integrations.oneFootballTeamId

Team _team(int id, String name, Color color) =>
    Team(id: id, name: name, shortName: name, color: color);

void main() {
  final clubConfig = goiasClubConfig;
  final light = AppTheme.light().extension<AppColors>()!;
  final dark = AppTheme.dark().extension<AppColors>()!;

  MatchStatColors resolve(Team home, Team away, {bool useDark = false}) =>
      MatchStatColors.resolve(
        homeTeam: home,
        awayTeam: away,
        clubConfig: clubConfig,
        colors: useDark ? dark : light,
        brightness: useDark ? Brightness.dark : Brightness.light,
      );

  double distance(Color a, Color b) {
    final dr = (a.r - b.r) * 255;
    final dg = (a.g - b.g) * 255;
    final db = (a.b - b.b) * 255;
    return dr * dr + dg * dg + db * db;
  }

  final goias = _team(_goiasId, 'Goiás', const Color(0xFF004C1B));

  group('clube ativo sempre no verde', () {
    for (final useDark in [false, true]) {
      final colors = useDark ? dark : light;
      final theme = useDark ? 'escuro' : 'claro';

      test('Goiás mandante ($theme)', () {
        final result = resolve(
          goias,
          _team(2, 'Náutico', const Color(0xFFD2003C)),
          useDark: useDark,
        );
        expect(result.home, colors.primary);
        expect(result.away, isNot(colors.primary));
      });

      test('Goiás visitante ($theme): o verde continua sendo dele', () {
        final result = resolve(
          _team(2, 'Náutico', const Color(0xFFD2003C)),
          goias,
          useDark: useDark,
        );
        expect(result.away, colors.primary);
        expect(result.home, isNot(colors.primary));
      });
    }
  });

  group('cores divergentes', () {
    test('adversário verde colide com o nosso verde: não repete a cor', () {
      final result = resolve(
        goias,
        _team(3, 'Time Verde FC', const Color(0xFF0A5A24)),
      );
      expect(result.home, light.primary);
      expect(distance(result.home, result.away), greaterThan(60 * 60));
    });

    test('dois times vermelhos (sem o clube ativo) ficam diferentes', () {
      const red = Color(0xFFC8102E);
      for (final useDark in [false, true]) {
        final result = resolve(
          _team(10, 'Time Vermelho A', red),
          _team(11, 'Time Vermelho B', red),
          useDark: useDark,
        );
        expect(
          distance(result.home, result.away),
          greaterThan(80 * 80),
          reason: 'useDark=$useDark',
        );
      }
    });

    test('cor invisível sobre o card (branco) não é usada', () {
      final result = resolve(
        goias,
        _team(4, 'Time Branco', const Color(0xFFFFFFFF)),
      );
      expect(result.away, isNot(const Color(0xFFFFFFFF)));
    });

    test('cor escura demais no tema escuro é clareada para aparecer', () {
      final result = resolve(
        goias,
        _team(5, 'Time Preto', const Color(0xFF050505)),
        useDark: true,
      );
      expect(result.away.computeLuminance(), greaterThan(0.02));
    });

    test('sempre devolve duas cores, mesmo com tudo igual', () {
      const gray = Color(0xFF808080);
      final result = resolve(
        _team(6, 'Cinza A', gray),
        _team(7, 'Cinza B', gray),
      );
      expect(result.home, isNot(result.away));
    });
  });
}
