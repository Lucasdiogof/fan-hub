import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_cubit.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_state.dart';
import 'package:goias_app/features/match/presentation/widgets/match_events_timeline.dart';
import 'package:goias_app/features/match/presentation/widgets/match_hero_card.dart';
import 'package:goias_app/features/match/presentation/widgets/match_lineups_section.dart';
import 'package:goias_app/features/match/presentation/widgets/match_stats_section.dart';
import 'package:goias_app/shared/widgets/fan_hub_tab_bar.dart';
import 'package:goias_app/shared/widgets/refreshable_state_view.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// [cubit], quando fornecido, já veio construído e carregado por quem
/// navegou pra cá (ver `GlobalLoading.run` nos pontos de entrada) — a tela
/// só reaproveita via `BlocProvider.value`. Fica `null` (e a tela cria/
/// carrega o próprio Cubit, como antes) só em navegação direta por URL
/// (deep link, voltar/avançar do navegador) — o app é PWA, então isso
/// precisa continuar funcionando sem quebrar.
class MatchDetailsPage extends StatelessWidget {
  const MatchDetailsPage({required this.fixtureId, this.cubit, super.key});

  final String fixtureId;
  final MatchDetailsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final preloaded = cubit;
    if (preloaded != null) {
      return BlocProvider.value(
        value: preloaded,
        child: const _MatchDetailsView(),
      );
    }
    return BlocProvider(
      create: (_) =>
          MatchDetailsCubit(sl<FootballRepository>(), fixtureId)..load(),
      child: const _MatchDetailsView(),
    );
  }
}

class _MatchDetailsView extends StatefulWidget {
  const _MatchDetailsView();

  @override
  State<_MatchDetailsView> createState() => _MatchDetailsViewState();
}

class _MatchDetailsViewState extends State<_MatchDetailsView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = context.read<MatchDetailsCubit>();
    if (state == AppLifecycleState.resumed) {
      cubit.resumePolling();
    } else {
      cubit.pausePolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.detail.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _BackButton(onTap: () => context.pop()),
                ),
                Expanded(
                  child: BlocBuilder<MatchDetailsCubit, MatchDetailsState>(
                    builder: (context, state) {
                      return RefreshableStateView(
                        status: state.status,
                        onRefresh: () =>
                            context.read<MatchDetailsCubit>().load(),
                        errorMessage: state.errorMessage,
                        emptyIcon: Icons.sports_soccer_outlined,
                        emptyTitle: context.l10n.matchDetailsLoadError,
                        successBuilder: (context) => _MatchDetailsContent(
                          match: state.match!,
                          events: state.events,
                          lineups: state.lineups,
                          stats: state.stats,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _MatchDetailsContent extends StatefulWidget {
  const _MatchDetailsContent({
    required this.match,
    required this.events,
    required this.lineups,
    required this.stats,
  });

  final Match match;
  final List<MatchEvent> events;
  final MatchLineups? lineups;
  final List<MatchStat> stats;

  @override
  State<_MatchDetailsContent> createState() => _MatchDetailsContentState();
}

class _MatchDetailsContentState extends State<_MatchDetailsContent> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        MatchHeroCard(match: widget.match),
        const SizedBox(height: AppSpacing.lg),
        FanHubTabBar(
          labels: [
            l10n.matchTabEvents,
            l10n.matchStatsTitle,
            l10n.matchLineupsTitle,
          ],
          selectedIndex: _tab,
          onChanged: (index) => setState(() => _tab = index),
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (_tab) {
          0 => MatchEventsTimeline(match: widget.match, events: widget.events),
          1 => MatchStatsSection(match: widget.match, stats: widget.stats),
          _ => MatchLineupsSection(
            match: widget.match,
            lineups: widget.lineups,
          ),
        },
      ],
    );
  }
}
