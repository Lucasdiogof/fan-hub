import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/presentation/passport_display_format.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_outcome_pill.dart';
import 'package:goias_app/shared/utils/date_labels.dart';

/// Cartão-ingresso de uma partida — nunca uma linha de tabela com
/// checkbox. Estádio/rodada/horário só aparecem quando existem; nunca
/// mostra código cru (round vem de [humanizeRound], horário sem segundos).
/// O card inteiro é a área de toque (mesmo padrão de acessibilidade que o
/// checkbox da V1 já tinha) — o selo "EU FUI" é feedback visual, não um
/// segundo alvo de toque escondido dentro do primeiro.
class PassportMatchTicketV2 extends StatelessWidget {
  const PassportMatchTicketV2({
    required this.match,
    required this.attended,
    required this.onToggle,
    super.key,
  });

  final PassportMatch match;
  final bool attended;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final canMark = match.canMarkAttendance;
    final home = match.homeTeam;
    final away = match.awayTeam;
    final score = match.score;
    final round = humanizeRound(l10n, match.round);
    final time = shortMatchTime(match.matchTime);

    final subtitleParts = [
      shortCompetitionLabel(match.competition),
      ?round,
      ?match.venueName,
    ];

    return Semantics(
      button: canMark,
      checked: canMark ? attended : null,
      label: home != null && away != null
          ? '$home x $away'
          : '${sl<ClubConfig>().identity.shortName} x ${match.opponent}',
      child: InkWell(
        onTap: canMark ? onToggle : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            color: attended
                ? colors.primary.withValues(alpha: 0.05)
                : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: attended
                  ? colors.primary.withValues(alpha: 0.4)
                  : colors.border,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DateStub(date: match.matchDate, time: time),
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
                        if (match.status != PassportMatchStatus.finished)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _StatusTag(
                              label: switch (match.status) {
                                PassportMatchStatus.scheduled =>
                                  l10n.passportStatusScheduled,
                                PassportMatchStatus.postponed =>
                                  l10n.passportStatusPostponed,
                                PassportMatchStatus.cancelled =>
                                  l10n.passportStatusCancelled,
                                _ => '',
                              },
                            ),
                          ),
                        _Matchup(
                          home: home,
                          away: away,
                          opponent: match.opponent,
                        ),
                        if (score.isKnown) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${score.firstScore}-${score.secondScore}',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
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
                _AttendanceSeal(attended: attended, canMark: canMark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateStub extends StatelessWidget {
  const _DateStub({required this.date, this.time});

  final DateTime? date;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = this.date;
    return SizedBox(
      width: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date == null ? '—' : '${date.day}'.padLeft(2, '0'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            if (date != null)
              Text(
                weekdayShortLabel(date, locale),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: colors.textHint,
                ),
              ),
            if (time != null) ...[
              const SizedBox(height: 6),
              Text(
                time!,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Matchup extends StatelessWidget {
  const _Matchup({
    required this.home,
    required this.away,
    required this.opponent,
  });

  final String? home;
  final String? away;
  final String opponent;

  /// Compara pelo nome de exibição do clube ativo (`ClubConfig.identity`),
  /// nunca um literal hardcoded — este widget só recebe nomes de time como
  /// `String` (não `Team`), então não dá pra usar `Team.matchesClub` aqui
  /// direto, mas a fonte do valor comparado é sempre a config, não um
  /// texto fixo.
  bool _isActiveClub(String team) {
    final identity = sl<ClubConfig>().identity;
    final normalized = team.toLowerCase();
    return normalized.contains(identity.shortName.toLowerCase()) ||
        normalized.contains(identity.displayName.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeClubShortName = sl<ClubConfig>().identity.shortName;
    if (home == null || away == null) {
      return _MatchupText(
        spans: [
          TextSpan(
            text: activeClubShortName,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
          const TextSpan(text: ' x '),
          TextSpan(text: opponent),
        ],
      );
    }
    return _MatchupText(
      spans: [
        TextSpan(
          text: home,
          style: _isActiveClub(home!)
              ? TextStyle(fontWeight: FontWeight.w900, color: colors.primary)
              : null,
        ),
        const TextSpan(text: ' x '),
        TextSpan(
          text: away,
          style: _isActiveClub(away!)
              ? TextStyle(fontWeight: FontWeight.w900, color: colors.primary)
              : null,
        ),
      ],
    );
  }
}

class _MatchupText extends StatelessWidget {
  const _MatchupText({required this.spans});

  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
        children: spans,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

/// O selo emocional — substitui o checkbox. Estado marcado é um selo
/// preenchido; estado não marcado é só um convite discreto, nunca um botão
/// genérico. Partida que não pode ser marcada não mostra nada aqui.
class _AttendanceSeal extends StatelessWidget {
  const _AttendanceSeal({required this.attended, required this.canMark});

  final bool attended;
  final bool canMark;

  @override
  Widget build(BuildContext context) {
    if (!canMark) return const SizedBox(width: AppSpacing.sm);
    final colors = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: attended
              ? Container(
                  key: const ValueKey(true),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: colors.onPrimary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.passportSealLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: colors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  key: const ValueKey(false),
                  l10n.passportSealActionLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textHint,
                  ),
                ),
        ),
      ),
    );
  }
}
