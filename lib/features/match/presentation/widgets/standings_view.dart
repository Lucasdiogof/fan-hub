import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
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
          onRefresh: () => context.read<GamesCubit>().loadStandings(),
          errorMessage: state.standingsErrorMessage,
          emptyIcon: Icons.leaderboard_outlined,
          emptyTitle: 'Classificação indisponível no momento.',
          successBuilder: (context) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              const StandingsHeader(),
              for (final standing in state.standings)
                StandingsRow(standing: standing, isGoias: standing.isGoias),
            ],
          ),
        );
      },
    );
  }
}
