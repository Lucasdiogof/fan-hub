import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Badge genérico de competição — NUNCA tenta reproduzir a logo oficial de
/// liga/campeonato (Brasileirão, Copa do Brasil, CONMEBOL...), só um ícone
/// de troféu num formato neutro (cantos arredondados, não o formato de
/// escudo do [StyledTeamBadge] — competição não é time, não deve parecer
/// um). Cor sempre `colors.primary` do app, nunca cor de terceiros.
class CompetitionBadge extends StatelessWidget {
  const CompetitionBadge({this.size = 22, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.emoji_events_rounded,
        size: size * 0.62,
        color: colors.primary,
      ),
    );
  }
}
