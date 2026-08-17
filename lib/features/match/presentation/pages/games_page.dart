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
import 'package:goias_app/features/match/presentation/widgets/matches_by_month_section.dart';
import 'package:goias_app/features/match/presentation/widgets/next_match_card.dart';
import 'package:goias_app/features/match/presentation/widgets/result_list_item.dart';
import 'package:goias_app/features/match/presentation/widgets/standings_view.dart';
import 'package:goias_app/shared/widgets/refreshable_state_view.dart';
import 'package:goias_app/shared/widgets/section_header.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GamesCubit, GamesState>(
      builder: (context, state) {
        return RefreshableStateView(
          status: state.matchesStatus,
          onRefresh: () => context.read<GamesCubit>().loadMatches(),
          errorMessage: state.matchesErrorMessage,
          emptyIcon: Icons.event_busy_rounded,
          emptyTitle: 'Nenhuma partida encontrada.',
          successBuilder: (context) {
            final upcomingAfterNext = state.nextMatch == null
                ? state.upcomingMatches
                : state.upcomingMatches.where((m) => m.id != state.nextMatch!.id).toList();
            final results = state.results;

            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
              children: [
                if (state.nextMatch != null) ...[
                  NextMatchCard(
                    match: state.nextMatch!,
                    onBuyTicket: () {},
                    onViewDetails: () => onMatchTap(state.nextMatch!),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
                if (upcomingAfterNext.isNotEmpty) ...[
                  MatchesByMonthSection(matches: upcomingAfterNext, onMatchTap: onMatchTap),
                ],
                if (results.isNotEmpty) ...[
                  const SectionHeader(title: 'RESULTADOS'),
                  const SizedBox(height: AppSpacing.md),
                  for (final match in results) ...[
                    ResultListItem(match: match, onTap: () => onMatchTap(match)),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ],
            );
          },
        );
      },
    );
  }
}
