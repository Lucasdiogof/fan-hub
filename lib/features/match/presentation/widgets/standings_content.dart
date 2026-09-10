import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/features/match/presentation/widgets/standings_header.dart';
import 'package:goias_app/features/match/presentation/widgets/standings_row.dart';

/// Renderer de tabela/grupos compartilhado entre a aba Classificação
/// (`StandingsView`) e a tela de detalhe de UMA competição do catálogo
/// (`CompetitionDetailsPage`) — mesmo `StandingsHeader`/`StandingsRow`,
/// nunca duas implementações do mesmo desenho.
class StandingsContent extends StatelessWidget {
  const StandingsContent({
    required this.standings,
    required this.standingGroups,
    super.key,
  });

  final List<Standing> standings;
  final List<StandingGroup> standingGroups;

  @override
  Widget build(BuildContext context) {
    if (standingGroups.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < standingGroups.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xl),
            _GroupSection(group: standingGroups[i]),
          ],
        ],
      );
    }
    return Column(
      children: [
        const StandingsHeader(),
        for (final standing in standings)
          StandingsRow(standing: standing, isActiveClub: standing.isActiveClub),
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group});

  final StandingGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            group.title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const StandingsHeader(),
        for (final standing in group.standings)
          StandingsRow(standing: standing, isActiveClub: standing.isActiveClub),
      ],
    );
  }
}
