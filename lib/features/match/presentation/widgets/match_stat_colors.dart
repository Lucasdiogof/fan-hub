import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/shared/widgets/team_visuals/team_visual_identity.dart';

/// Cores dos dois lados das barras de estatística.
///
/// Regras:
/// 1. O clube ATIVO (Goiás no app do Goiás) é sempre `colors.primary` — o
///    verde fica sempre "pra gente", seja mandante ou visitante.
/// 2. O outro time usa a identidade dele (tabela curada em
///    `team_visual_identity.dart`: primária e, quando existe, secundária).
/// 3. Duas cores só valem se forem DIVERGENTES entre si e visíveis sobre a
///    superfície do card. Se a primária do adversário colide com a nossa (ou
///    não aparece no fundo), tenta a secundária; se nem ela serve, cai num
///    cinza neutro. Ex.: Vila Nova x Náutico (ambos vermelho e branco) → um
///    fica vermelho e o outro neutro, nunca dois vermelhos.
/// 4. Jogo sem o clube ativo: o mandante escolhe primeiro, o visitante é
///    quem se adapta.
class MatchStatColors {
  const MatchStatColors({required this.home, required this.away});

  final Color home;
  final Color away;

  /// Contraste mínimo (WCAG) entre a cor da barra e a superfície do card.
  static const double _minContrast = 1.6;

  /// Distância mínima entre as duas cores (escala "redmean", 0–765).
  static const double _minDistance = 110;

  static MatchStatColors resolve({
    required Team homeTeam,
    required Team awayTeam,
    required ClubConfig clubConfig,
    required AppColors colors,
    required Brightness brightness,
  }) {
    final neutral = Color.alphaBlend(
      colors.textSecondary.withValues(alpha: 0.6),
      colors.surface,
    );
    final strongNeutral = Color.alphaBlend(
      colors.textPrimary.withValues(alpha: 0.85),
      colors.surface,
    );

    Color? usable(Color color) {
      if (_contrast(color, colors.surface) >= _minContrast) return color;
      final shifted = Color.lerp(
        color,
        brightness == Brightness.dark ? Colors.white : Colors.black,
        brightness == Brightness.dark ? 0.4 : 0.35,
      )!;
      return _contrast(shifted, colors.surface) >= _minContrast
          ? shifted
          : null;
    }

    List<Color> candidates(Team team) {
      if (team.matchesClub(clubConfig)) return [colors.primary];
      final identity = resolveTeamVisualIdentity(
        team: team,
        clubConfig: clubConfig,
      );
      return [identity.primaryColor, ?identity.secondaryColor];
    }

    Color pick(Team team, {Color? avoid}) {
      for (final candidate in candidates(team)) {
        final color = usable(candidate);
        if (color == null) continue;
        if (avoid == null || _distance(color, avoid) >= _minDistance) {
          return color;
        }
      }
      if (avoid == null || _distance(neutral, avoid) >= _minDistance) {
        return neutral;
      }
      return strongNeutral;
    }

    // Quem escolhe primeiro: o nosso clube; senão, o mandante.
    final awayIsOurs = awayTeam.matchesClub(clubConfig);
    final homeIsOurs = homeTeam.matchesClub(clubConfig);
    if (awayIsOurs && !homeIsOurs) {
      final away = pick(awayTeam);
      return MatchStatColors(
        home: pick(homeTeam, avoid: away),
        away: away,
      );
    }
    final home = pick(homeTeam);
    return MatchStatColors(
      home: home,
      away: pick(awayTeam, avoid: home),
    );
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _distance(Color a, Color b) {
    final rMean = (a.r + b.r) * 255 / 2;
    final dr = (a.r - b.r) * 255;
    final dg = (a.g - b.g) * 255;
    final db = (a.b - b.b) * 255;
    final sum =
        (2 + rMean / 256) * dr * dr +
        4 * dg * dg +
        (2 + (255 - rMean) / 256) * db * db;
    return sum <= 0 ? 0 : _sqrt(sum);
  }

  static double _sqrt(double value) {
    var x = value;
    for (var i = 0; i < 20; i++) {
      x = (x + value / x) / 2;
    }
    return x;
  }
}
