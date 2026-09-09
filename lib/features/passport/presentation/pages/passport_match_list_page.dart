import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/presentation/passport_display_format.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_outcome_pill.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Argumento de rota — lista já filtrada (Jogos/Vitórias/Empates/Derrotas/
/// Em casa/Fora de casa da Minha Trajetória são todas a mesma tela, só
/// mudando [title] e [matches], sempre um recorte de
/// `PassportTrajectoryState.attendedMatches` já calculado por quem navega.
class PassportMatchListArgs {
  const PassportMatchListArgs({required this.title, required this.matches});

  final String title;
  final List<PassportMatch> matches;
}

class PassportMatchListPage extends StatelessWidget {
  const PassportMatchListPage({required this.args, super.key});

  final PassportMatchListArgs args;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final matches = [...args.matches]
      ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        args.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: matches.isEmpty
                      ? Center(
                          child: StateMessage(
                            icon: Icons.event_busy_rounded,
                            title: context.l10n.passportTrajectoryListEmpty,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.xl,
                            AppSpacing.lg,
                            AppSpacing.xxxl,
                          ),
                          itemCount: matches.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) =>
                              _MatchRow(match: matches[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});

  final PassportMatch match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final home = match.homeTeam;
    final away = match.awayTeam;
    final hasScore = match.homeScore != null && match.awayScore != null;
    final round = humanizeRound(l10n, match.round);
    final subtitleParts = [match.competition, ?round, ?match.venueName];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${match.matchDate.day}'.padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      weekdayShortLabel(match.matchDate, locale),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: colors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(width: 1, color: colors.border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              children: home != null && away != null
                                  ? [
                                      TextSpan(
                                        text: home,
                                        style: _goiasStyle(colors, home),
                                      ),
                                      const TextSpan(text: ' x '),
                                      TextSpan(
                                        text: away,
                                        style: _goiasStyle(colors, away),
                                      ),
                                    ]
                                  : [
                                      TextSpan(
                                        text: sl<ClubConfig>()
                                            .identity
                                            .shortName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: colors.primary,
                                        ),
                                      ),
                                      const TextSpan(text: ' x '),
                                      TextSpan(text: match.opponent),
                                    ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasScore) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${match.homeScore}-${match.awayScore}',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            subtitleParts.join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.3,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        if (match.outcome != null) ...[
                          const SizedBox(width: 6),
                          PassportOutcomePill(outcome: match.outcome),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle? _goiasStyle(AppColors colors, String team) =>
      team.toLowerCase().contains(
        sl<ClubConfig>().identity.shortName.toLowerCase(),
      )
      ? TextStyle(fontWeight: FontWeight.w900, color: colors.primary)
      : null;
}
