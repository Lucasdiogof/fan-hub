import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/match_status_label.dart';
import 'package:goias_app/features/match/presentation/widgets/match_team_name.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Cabeçalho da tela de detalhes: foto de estádio ao fundo (com camada escura
/// por cima, pra o texto sempre ler bem), competição, AO VIVO, escudos,
/// placar ou horário, data e estádio. Fica escuro nos dois temas — o texto é
/// sempre branco sobre a imagem.
class MatchHeroCard extends StatelessWidget {
  const MatchHeroCard({required this.match, super.key});

  final Match match;

  static const backgroundAsset = 'lib/assets/match_hero_stadium.webp';
  static const double badgeSize = 64;
  static const double centerWidth = 112;

  bool get _isLive =>
      match.status == MatchStatus.live || match.status == MatchStatus.halftime;

  bool get _hasScore => match.homeScore != null && match.awayScore != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    // `toBrazilTime`, nunca `.toLocal()` (spec 2026-09-12).
    final kickoff = match.kickoff != null ? toBrazilTime(match.kickoff!) : null;
    final dateLine = kickoff != null
        ? '${longDateLabel(kickoff, l10n, locale)} • ${timeLabel(kickoff)}'
        : l10n.matchDateToBeConfirmed;
    final venue = [
      match.stadium,
      if (match.city != null && match.city!.isNotEmpty) match.city!,
    ].where((part) => part.isNotEmpty).join(' • ');
    // Estados que não são "futura" nem "ao vivo" (encerrada, adiada...) — o
    // antigo card de informações era o único lugar que mostrava isso.
    final showStatus = !_isLive && match.status != MatchStatus.scheduled;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.banner),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.62),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF020A05).withValues(alpha: 0.42),
                    const Color(0xFF04120A).withValues(alpha: 0.55),
                    const Color(0xFF020A05).withValues(alpha: 0.80),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        [
                          match.competition,
                          if (match.round.isNotEmpty) match.round,
                        ].join(' • ').toUpperCase(),
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          height: 1.3,
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
                    ),
                    if (_isLive) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _LiveBadge(label: matchStatusLabel(l10n, match.status)),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _TeamColumn(team: match.homeTeam)),
                    SizedBox(
                      width: centerWidth,
                      child: _Center(
                        match: match,
                        hasScore: _hasScore,
                        kickoff: kickoff,
                        dateLine: dateLine,
                        statusText: showStatus
                            ? matchStatusLabel(l10n, match.status)
                            : null,
                      ),
                    ),
                    Expanded(child: _TeamColumn(team: match.awayTeam)),
                  ],
                ),
                if (venue.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    venue,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: Color(0xB3FFFFFF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: MatchHeroCard.badgeSize,
          height: MatchHeroCard.badgeSize,
          child: ClubBadge(team: team, size: MatchHeroCard.badgeSize),
        ),
        const SizedBox(height: AppSpacing.sm),
        MatchTeamName(
          shortTeamName(team.name),
          alignment: Alignment.center,
          sizes: const [14.5, 13.5, 12.5, 11.5],
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _Center extends StatelessWidget {
  const _Center({
    required this.match,
    required this.hasScore,
    required this.kickoff,
    required this.dateLine,
    required this.statusText,
  });

  final Match match;
  final bool hasScore;
  final DateTime? kickoff;
  final String dateLine;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final big = hasScore
        ? '${match.homeScore} x ${match.awayScore}'
        : (kickoff != null ? timeLabel(kickoff!) : '--:--');
    return Column(
      children: [
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            big,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          // Com o horário já em destaque (jogo futuro), a linha secundária só
          // repete a data.
          hasScore || kickoff == null ? dateLine : _dateOnly(dateLine),
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.3,
            color: Color(0xCCFFFFFF),
          ),
        ),
        if (statusText != null) ...[
          const SizedBox(height: 4),
          Text(
            statusText!.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xE6FFFFFF),
            ),
          ),
        ],
      ],
    );
  }

  static String _dateOnly(String line) {
    final index = line.lastIndexOf(' • ');
    return index < 0 ? line : line.substring(0, index);
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDDF3E4),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF1E9E4F),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Color(0xFF0B3D1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
