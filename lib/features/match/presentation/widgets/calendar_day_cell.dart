import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Uma célula do grid — `date == null` é espaço vazio antes/depois do mês
/// (nunca mostra dia de mês vizinho). O dia inteiro não é clicável — só o
/// bloco do escudo/pill, quando existe partida (ponto 7 do pedido).
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.date,
    required this.matches,
    required this.isToday,
    required this.onMatchTap,
    super.key,
  });

  final DateTime? date;
  final List<Match> matches;
  final bool isToday;
  final ValueChanged<Match> onMatchTap;

  @override
  Widget build(BuildContext context) {
    final date = this.date;
    if (date == null) return const SizedBox.shrink();

    final colors = context.colors;
    // Mais de uma partida no mesmo dia é um caso raro (nunca aconteceu de
    // fato pro Goiás) — mostra só a primeira, de propósito, pra célula
    // nunca ficar poluída.
    final match = matches.isEmpty ? null : matches.first;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: isToday
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: 0.14),
                    border: Border.all(color: colors.primary, width: 1.2),
                  )
                : null,
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                color: match == null ? colors.textHint : colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 3),
          if (match != null) _MatchIndicator(match: match, onTap: onMatchTap),
        ],
      ),
    );
  }
}

class _MatchIndicator extends StatelessWidget {
  const _MatchIndicator({required this.match, required this.onTap});

  final Match match;
  final ValueChanged<Match> onTap;

  @override
  Widget build(BuildContext context) {
    final isHome = match.isHomeTeam(Team.goiasId);
    final opponent = isHome ? match.awayTeam : match.homeTeam;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(match),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClubBadge(team: opponent, size: 22),
              const SizedBox(height: 3),
              _HomeAwayPill(isHome: isHome),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeAwayPill extends StatelessWidget {
  const _HomeAwayPill({required this.isHome});

  final bool isHome;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = isHome
        ? context.l10n.matchCalendarHome
        : context.l10n.matchCalendarAway;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: isHome ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: isHome ? null : Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: isHome ? colors.onPrimary : colors.textSecondary,
        ),
      ),
    );
  }
}
