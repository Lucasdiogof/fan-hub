import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/entities/standing_group.dart';
import 'package:goias_app/features/match/presentation/cubit/games_cubit.dart';
import 'package:goias_app/features/match/presentation/cubit/games_state.dart';
import 'package:goias_app/features/match/presentation/widgets/standings_header.dart';
import 'package:goias_app/features/match/presentation/widgets/standings_row.dart';
import 'package:goias_app/shared/widgets/refreshable_state_view.dart';

class StandingsView extends StatelessWidget {
  const StandingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamesCubit, GamesState>(
      builder: (context, state) {
        return RefreshableStateView(
          status: state.standingsStatus,
          onRefresh: () => context.read<GamesCubit>().loadStandings(
            competitionId: state.selectedCompetition?.id,
          ),
          errorMessage: state.standingsErrorMessage,
          emptyIcon: Icons.leaderboard_outlined,
          emptyTitle: context.l10n.standingsUnavailable,
          successBuilder: (context) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              // Seletor só aparece com mais de uma competição real pra
              // escolher — clube com só a principal nunca vê um seletor
              // vazio/inútil.
              if (state.competitions.length > 1) ...[
                _CompetitionPicker(
                  competitions: state.competitions,
                  selectedId: state.selectedCompetition?.id ?? 'primary',
                  onSelected: (id) =>
                      context.read<GamesCubit>().selectCompetition(id),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (state.standingGroups.isNotEmpty)
                for (var i = 0; i < state.standingGroups.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.xl),
                  _GroupSection(group: state.standingGroups[i]),
                ]
              else ...[
                const StandingsHeader(),
                for (final standing in state.standings)
                  StandingsRow(
                    standing: standing,
                    isActiveClub: standing.isActiveClub,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CompetitionPicker extends StatelessWidget {
  const _CompetitionPicker({
    required this.competitions,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CompetitionRef> competitions;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final competition in competitions) ...[
            _CompetitionChip(
              label: competition.name,
              selected: competition.id == selectedId,
              onTap: () => onSelected(competition.id),
              colors: colors,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _CompetitionChip extends StatelessWidget {
  const _CompetitionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.primary : colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? colors.onPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Uma seção de grupo (ex.: "GRUPO H") — mesmo `StandingsHeader`/
/// `StandingsRow` da tabela normal, só com um rótulo do grupo acima.
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
          StandingsRow(
            standing: standing,
            isActiveClub: standing.isActiveClub,
          ),
      ],
    );
  }
}
