import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Título de topo de aba — usado no lugar de um `Text` solto genérico.
/// A barrinha verde ao lado é o mesmo tipo de acento usado no restante do
/// app (ex.: divisor do wordmark da Home antes da simplificação). O escudo
/// do clube ativo vem logo depois, em todo título — identidade do clube
/// presente em toda tela, não só na Home. Via `ClubBadge.activeClub` (não
/// `StyledTeamBadge` direto) DE PROPÓSITO: assim o rollback de
/// `useStyledTeamBadges` (em `club_badge.dart`) cobre este componente
/// também, sem precisar duplicar a checagem da flag aqui.
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const ClubBadge.activeClub(size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              maxLines: 1,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
