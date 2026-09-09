import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_button_styles.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/match_status_label.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:goias_app/shared/widgets/live_pulse_dot.dart';
import 'package:goias_app/shared/widgets/stadium_backdrop.dart';

/// Mesma moldura do `NextMatchHero` (silhueta/fundo do estádio já
/// estabelecida na Home), mas o conteúdo vira placar em vez de contagem
/// regressiva — usado pra `live`/`halftime` (placar ao vivo) e também pra
/// `finished` (placar final, dentro da folga que `HomeCubit._resolveMatch`
/// decide — não faz sentido continuar vendendo ingresso pra um jogo que já
/// aconteceu). Quem decide qual status chega aqui é `NextMatchSection`,
/// este widget só exibe.
class LiveMatchHero extends StatelessWidget {
  const LiveMatchHero({required this.match, this.onFollow, super.key});

  final Match match;
  final VoidCallback? onFollow;

  bool get _isReallyLive => match.status == MatchStatus.live;
  bool get _isFinished => match.status == MatchStatus.finished;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasScore = match.homeScore != null && match.awayScore != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Stack(
        children: [
          Positioned.fill(
            child: StadiumBackdrop(
              imageAsset: sl<ClubConfig>().assets.matchHero,
              showFloodlights: false,
              overlayOpacity: 0.85,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  // "Finalizado" fica do lado direito, isolado — sinaliza o
                  // fim do jogo sem competir com o resto do cabeçalho, que
                  // aqui nem existe mais (nada de pulso "ao vivo").
                  mainAxisAlignment: _isFinished
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (_isReallyLive) ...[
                      const LivePulseDot(color: Colors.white, size: 8),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _isFinished
                          ? l10n.matchFinishedLabel.toUpperCase()
                          : [
                              matchStatusLabel(
                                l10n,
                                match.status,
                              ).toUpperCase(),
                              if (_isReallyLive && match.minute != null)
                                match.minute!,
                            ].join(' · '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _TeamColumn(team: match.homeTeam)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        hasScore
                            ? '${match.homeScore} x ${match.awayScore}'
                            : 'x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Expanded(child: _TeamColumn(team: match.awayTeam)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: onFollow,
                      style: matchCtaFilledStyle(context, forceDark: true)
                          .merge(
                            ElevatedButton.styleFrom(
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                      child: Text(
                        _isFinished
                            ? l10n.matchViewDetails
                            : l10n.matchFollowLive,
                      ),
                    ),
                  ),
                ),
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
        ClubBadge(team: team, size: 64, onDark: true),
        const SizedBox(height: AppSpacing.sm),
        Text(
          shortTeamName(team.name).toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
