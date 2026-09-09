import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
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

    // Dia sem partida: só o número, do jeito simples de sempre. Dia com
    // partida: só o escudo (ver `_MatchIndicator`) — sem número nenhum, nem
    // solto nem sobreposto.
    if (match == null) {
      return Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: isToday ? _todayDecoration(colors, circle: true) : null,
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: colors.textHint,
            ),
          ),
        ),
      );
    }

    // Dia de jogo que também é hoje precisa continuar marcado como hoje. Sem
    // isso o destaque some justamente no dia mais importante do mês: a
    // célula troca o número pelo escudo e leva junto o círculo. O contorno é
    // arredondado em vez de circular só porque aqui o conteúdo é um bloco
    // (escudo + pill), não um dígito — a cor e a espessura são as mesmas, pra
    // ler como a mesma marcação.
    return Padding(
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: isToday
            ? _todayDecoration(colors, circle: false)
            : const BoxDecoration(),
        child: _MatchIndicator(match: match, onTap: onMatchTap),
      ),
    );
  }

  BoxDecoration _todayDecoration(AppColors colors, {required bool circle}) {
    return BoxDecoration(
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(12),
      color: colors.primary.withValues(alpha: 0.14),
      border: Border.all(color: colors.primary, width: 1.2),
    );
  }
}

class _MatchIndicator extends StatelessWidget {
  const _MatchIndicator({required this.match, required this.onTap});

  final Match match;
  final ValueChanged<Match> onTap;

  @override
  Widget build(BuildContext context) {
    final isHome = match.isHomeTeam(
      sl<ClubConfig>().integrations.oneFootballTeamId,
    );
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
              ClubBadge(team: opponent, size: 30),
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
