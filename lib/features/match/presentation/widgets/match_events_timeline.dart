import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';

/// Timeline de gols/cartões/substituições — só aparece quando a fonte tem
/// eventos pra essa partida (não toda partida tem, ex.: futuras).
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
    if (events.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'EVENTOS DA PARTIDA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < events.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.border),
                _EventRow(
                  event: events[i],
                  teamName: events[i].side == MatchEventSide.home
                      ? match.homeTeam.name
                      : match.awayTeam.name,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.teamName});

  final MatchEvent event;
  final String teamName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              event.minute,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.textHint,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: _EventIcon(type: event.type, colors: colors),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _primaryLabel(event),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teamName,
                  style: TextStyle(fontSize: 11.5, color: colors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _primaryLabel(MatchEvent event) {
    switch (event.type) {
      case MatchEventType.goal:
        final who = event.player ?? 'Gol';
        return event.detail != null ? '$who (${event.detail})' : who;
      case MatchEventType.yellowCard:
      case MatchEventType.redCard:
        return event.player ?? 'Cartão';
      case MatchEventType.substitution:
        return '${event.player ?? '—'} entra no lugar de ${event.detail ?? '—'}';
      case MatchEventType.other:
        return event.detail ?? '—';
    }
  }
}

class _EventIcon extends StatelessWidget {
  const _EventIcon({required this.type, required this.colors});

  final MatchEventType type;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MatchEventType.goal:
        return Icon(
          Icons.sports_soccer_rounded,
          size: 16,
          color: colors.primary,
        );
      case MatchEventType.yellowCard:
        return Container(
          width: 11,
          height: 15,
          decoration: BoxDecoration(
            color: colors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case MatchEventType.redCard:
        return Container(
          width: 11,
          height: 15,
          decoration: BoxDecoration(
            color: colors.textPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case MatchEventType.substitution:
        return Icon(
          Icons.swap_vert_rounded,
          size: 16,
          color: colors.textSecondary,
        );
      case MatchEventType.other:
        return Icon(Icons.circle, size: 8, color: colors.textHint);
    }
  }
}
