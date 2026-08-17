import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/cubit/games_cubit.dart';
import 'package:goias_app/features/match/presentation/cubit/games_state.dart';
import 'package:goias_app/features/match/presentation/widgets/games_header.dart';
import 'package:goias_app/features/match/presentation/widgets/games_section.dart';
import 'package:goias_app/features/match/presentation/widgets/games_section_selector.dart';
import 'package:goias_app/features/match/presentation/widgets/match_list_item.dart';
import 'package:goias_app/features/match/presentation/widgets/next_match_card.dart';
import 'package:goias_app/features/match/presentation/widgets/result_list_item.dart';
import 'package:goias_app/features/match/presentation/widgets/standings_view.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/section_header.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GamesCubit>(),
      child: const _GamesView(),
    );
  }
}

class _GamesView extends StatefulWidget {
  const _GamesView();

  @override
  State<_GamesView> createState() => _GamesViewState();
}

class _GamesViewState extends State<_GamesView> {
  GamesSection _section = GamesSection.matches;

  void _openMatchDetails(Match match) {
    context.push('/match/${match.id}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GamesHeader(),
                      const SizedBox(height: AppSpacing.lg),
                      GamesSectionSelector(
                        section: _section,
                        onChanged: (section) => setState(() => _section = section),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: _section == GamesSection.matches
                      ? _MatchesTab(onMatchTap: _openMatchDetails)
                      : const StandingsView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab({required this.onMatchTap});

  final ValueChanged<Match> onMatchTap;

  static bool _isLoading(GamesState state) {
    return state.currentRoundStatus == LoadStatus.initial ||
        state.currentRoundStatus == LoadStatus.loading ||
        state.snapshotStatus == LoadStatus.initial ||
        state.snapshotStatus == LoadStatus.loading;
  }

  static bool _allFailed(GamesState state) {
    return state.currentRoundStatus == LoadStatus.error && state.snapshotStatus == LoadStatus.error;
  }

  static bool _allEmpty(GamesState state) {
    final currentRoundEmpty = state.currentRoundStatus == LoadStatus.empty || state.currentRoundStatus == LoadStatus.error;
    final snapshotEmpty = state.snapshotStatus == LoadStatus.empty || state.snapshotStatus == LoadStatus.error;
    return currentRoundEmpty &&
        snapshotEmpty &&
        state.currentRoundMatches.isEmpty &&
        state.nextMatch == null &&
        state.recentResults.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<GamesCubit, GamesState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<GamesCubit>().refresh(),
          color: colors.primary,
          child: _isLoading(state)
              ? _centered(CircularProgressIndicator(color: colors.primary))
              : _allFailed(state)
              ? _centered(
                  StateMessage(
                    icon: Icons.wifi_off_rounded,
                    title: 'Não foi possível carregar os jogos',
                    message: state.currentRoundErrorMessage ?? state.snapshotErrorMessage,
                  ),
                )
              : _allEmpty(state)
              ? _centered(const StateMessage(icon: Icons.event_busy_rounded, title: 'Nenhuma partida encontrada.'))
              : _MatchesContent(state: state, onMatchTap: onMatchTap),
        );
      },
    );
  }
}

Widget _centered(Widget child) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      Padding(padding: const EdgeInsets.only(top: 100), child: Center(child: child)),
    ],
  );
}

class _MatchesContent extends StatelessWidget {
  const _MatchesContent({required this.state, required this.onMatchTap});

  final GamesState state;
  final ValueChanged<Match> onMatchTap;

  @override
  Widget build(BuildContext context) {
    final nextMatch = state.nextMatch;
    final roundMatches = state.currentRoundMatches;
    final results = state.recentResults;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
      children: [
        if (nextMatch != null) ...[
          NextMatchCard(
            match: nextMatch,
            onBuyTicket: () {},
            onViewDetails: () => onMatchTap(nextMatch),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        if (roundMatches.isNotEmpty) ...[
          const SectionHeader(title: 'RODADA ATUAL'),
          const SizedBox(height: AppSpacing.md),
          for (final match in roundMatches) ...[
            MatchListItem(match: match, onTap: () => onMatchTap(match)),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
        if (results.isNotEmpty) ...[
          const SectionHeader(title: 'RESULTADOS RECENTES'),
          const SizedBox(height: AppSpacing.md),
          for (final match in results) ...[
            ResultListItem(match: match, onTap: () => onMatchTap(match)),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}
