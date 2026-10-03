import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/presentation/widgets/match_tab_empty_state.dart';
import 'package:goias_app/shared/utils/team_name.dart';

/// Aba EVENTOS: TODOS os lances que a fonte trouxe, na ordem em que ela
/// entrega (cronológica, do 1' em diante), numa timeline vertical. A página
/// rola normalmente — a lista não tem limite nem rolagem própria. Sem lances
/// (partida futura, fonte ainda sem dados) mostra o estado vazio.
class MatchEventsTimeline extends StatelessWidget {
  const MatchEventsTimeline({
    required this.match,
    required this.events,
    super.key,
  });

  final Match match;
  final List<MatchEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return MatchTabEmptyState(
        icon: Icons.timeline_rounded,
        message: context.l10n.matchEventsEmpty,
      );
    }
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++)
            _EventRow(
              event: events[i],
              teamName: shortTeamName(
                events[i].side == MatchEventSide.home
                    ? match.homeTeam.name
                    : match.awayTeam.name,
              ),
              isLast: i == events.length - 1,
            ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.teamName,
    required this.isLast,
  });

  final MatchEvent event;
  final String teamName;
  final bool isLast;

  static const double _minuteWidth = 44;
  static const double _railWidth = 30;
  static const double _iconSize = 26;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = _subtitle(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _minuteWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              // Minuto comprido (ex.: "120+10'") encolhe de leve em vez de
              // vazar da coluna fixa e desalinhar a timeline.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  event.minute,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: _railWidth,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? _iconSize / 2 + 3 : null,
                  child: Container(
                    width: 1,
                    color: colors.border.withValues(alpha: 0.8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: _EventIcon(type: event.type),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _primaryLabel(context),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: colors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _primaryLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (event.type) {
      case MatchEventType.goal:
        return event.player ?? l10n.matchEventGoal;
      case MatchEventType.yellowCard:
      case MatchEventType.redCard:
        return event.player ?? l10n.matchEventCard;
      case MatchEventType.substitution:
        return l10n.matchEventSubstitution(
          event.player ?? '—',
          event.detail ?? '—',
        );
      case MatchEventType.other:
        return event.detail ?? '—';
    }
  }

  /// Time do lance e, nos gols, o detalhe que a fonte der (pênalti, contra).
  String _subtitle(BuildContext context) {
    final detail = event.type == MatchEventType.goal
        ? _goalDetail(context, event.detail)
        : null;
    return [teamName, ?detail].join(' • ');
  }

  static String? _goalDetail(BuildContext context, String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final l10n = context.l10n;
    switch (raw.trim().toLowerCase()) {
      case 'pênalti':
      case 'penalti':
        return l10n.matchEventPenalty;
      case 'contra':
        return l10n.matchEventOwnGoal;
      default:
        return raw;
    }
  }
}

class _EventIcon extends StatelessWidget {
  const _EventIcon({required this.type});

  final MatchEventType type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final (Widget glyph, String label) = switch (type) {
      MatchEventType.goal => (
        Icon(Icons.sports_soccer_rounded, size: 15, color: colors.primary),
        l10n.matchEventGoal,
      ),
      MatchEventType.yellowCard => (
        Container(
          width: 10,
          height: 14,
          decoration: BoxDecoration(
            color: colors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        l10n.matchEventYellowCard,
      ),
      MatchEventType.redCard => (
        Container(
          width: 10,
          height: 14,
          decoration: BoxDecoration(
            color: colors.error,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        l10n.matchEventRedCard,
      ),
      MatchEventType.substitution => (
        Icon(Icons.swap_vert_rounded, size: 16, color: colors.textSecondary),
        l10n.matchEventSubstitutionLabel,
      ),
      MatchEventType.other => (
        Icon(Icons.circle, size: 7, color: colors.textHint),
        '',
      ),
    };
    return Semantics(
      label: label.isEmpty ? null : label,
      excludeSemantics: label.isNotEmpty,
      child: Container(
        width: _EventRow._iconSize,
        height: _EventRow._iconSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border.withValues(alpha: 0.9)),
        ),
        child: glyph,
      ),
    );
  }
}
