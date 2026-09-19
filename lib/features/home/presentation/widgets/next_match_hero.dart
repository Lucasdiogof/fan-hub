import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_button_styles.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/home/presentation/widgets/match_countdown.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:goias_app/shared/widgets/stadium_backdrop.dart';

/// Único grande bloco escuro da primeira dobra — o header acima dele é
/// claro de propósito, pra não competir visualmente.
class NextMatchHero extends StatelessWidget {
  const NextMatchHero({
    required this.match,
    this.onTap,
    this.onTickets,
    this.onMatchStarted,
    super.key,
  });

  final Match match;
  final VoidCallback? onTap;
  final VoidCallback? onTickets;
  final VoidCallback? onMatchStarted;

  /// Venda de ingresso só existe quando a capability do clube está ligada
  /// E o jogo é em casa — o visitante não controla a bilheteria.
  bool get _showsTicketsCta =>
      onTickets != null && match.homeTeam.matchesClub(sl<ClubConfig>());

  /// Sem ingresso pra vender, o CTA vira "Ver detalhes" (mesmo destino do
  /// toque no card). Se nem isso existir, o botão simplesmente não aparece.
  VoidCallback? get _ctaAction => _showsTicketsCta ? onTickets : onTap;

  @override
  Widget build(BuildContext context) {
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
          // O botão de ingresso (quando existe) fica por cima e cuida do
          // próprio toque — este `Positioned.fill` só cobre o resto do
          // card, senão ele "roubaria" o toque do botão.
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
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
                Text(
                  context.l10n.homeNextMatch,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _shortCompetitionLabel(match.competition),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // `toBrazilTime`, nunca `.toLocal()` (spec 2026-09-12).
                  match.kickoff != null
                      ? '${shortDateLabel(toBrazilTime(match.kickoff!), Localizations.localeOf(context).toString())} • ${timeLabel(toBrazilTime(match.kickoff!))} • ${match.stadium.toUpperCase()}'
                      : '${context.l10n.homeDateToBeConfirmed} • ${match.stadium.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _TeamColumn(team: match.homeTeam)),
                    const _VersusBadge(),
                    Expanded(child: _TeamColumn(team: match.awayTeam)),
                  ],
                ),
                if (match.kickoff != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  MatchCountdown(
                    kickoff: match.kickoff!,
                    onFinished: onMatchStarted,
                  ),
                ],
                // Fora de casa não tem ingresso pra vender — só o mandante
                // do jogo controla a bilheteria do próprio estádio. E com
                // `hasTickets: false` (venda desligada pro envio às lojas)
                // o card NUNCA mostra um botão de compra desabilitado: cai
                // pro mesmo destino do toque no card, "Ver detalhes".
                if (_ctaAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _ctaAction,
                      // `forceDark`: este botão fica sobre o
                      // `StadiumBackdrop`, que é sempre escuro
                      // independente do tema do app.
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
                        _showsTicketsCta
                            ? context.l10n.homeTickets
                            : context.l10n.matchViewDetails,
                      ),
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

final _competitionShortNames = {
  RegExp(r'campeonato brasileiro s[ée]rie a', caseSensitive: false):
      'Brasileirão Série A',
  RegExp(r'campeonato brasileiro s[ée]rie b', caseSensitive: false):
      'Brasileirão Série B',
  RegExp(r'campeonato brasileiro s[ée]rie c', caseSensitive: false):
      'Brasileirão Série C',
};

/// A fonte real devolve algo como "Campeonato Brasileiro Série B 2026" —
/// grande demais pro Hero. Isso é só apresentação, não mexe no dado.
String _shortCompetitionLabel(String competition) {
  for (final entry in _competitionShortNames.entries) {
    if (entry.key.hasMatch(competition)) return entry.value;
  }
  return competition;
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

class _VersusBadge extends StatelessWidget {
  const _VersusBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Text(
        'X',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
