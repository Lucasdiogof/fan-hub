import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/cubit/games_cubit.dart';
import 'package:goias_app/features/match/presentation/cubit/games_state.dart';
import 'package:goias_app/features/match/presentation/match_navigation.dart';
import 'package:goias_app/features/match/presentation/widgets/games_header.dart';
import 'package:goias_app/features/match/presentation/widgets/games_section.dart';
import 'package:goias_app/features/match/presentation/widgets/games_section_selector.dart';
import 'package:goias_app/features/match/presentation/widgets/live_match_poller.dart';
import 'package:goias_app/features/match/presentation/widgets/match_list_item.dart';
import 'package:goias_app/features/match/presentation/widgets/next_match_card.dart';
import 'package:goias_app/features/match/presentation/widgets/standings_view.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

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

  Future<void> _openMatchDetails(Match match) => openMatchDetails(context, match);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GamesHeader(),
                      const SizedBox(height: AppSpacing.lg),
                      GamesSectionSelector(
                        section: _section,
                        onChanged: (section) =>
                            setState(() => _section = section),
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

  /// Só bloqueia a tela inteira quando ainda não existe NADA pra mostrar
  /// (primeira carga). Navegar entre rodadas também deixa
  /// `currentRoundStatus` em `loading`, mas já existe `currentRoundMatches`
  /// de antes — nesse caso `_MatchesContent` mantém o card do próximo jogo
  /// e o cabeçalho de rodada fixos e só troca a lista de jogos por um
  /// carregamento local (ver `_isRoundNavigating`).
  static bool _isLoading(GamesState state) {
    final noRoundDataYet =
        state.currentRoundStatus == LoadStatus.initial ||
        (state.currentRoundStatus == LoadStatus.loading &&
            state.currentRoundMatches.isEmpty);
    return noRoundDataYet ||
        state.snapshotStatus == LoadStatus.initial ||
        state.snapshotStatus == LoadStatus.loading;
  }

  static bool _allFailed(GamesState state) {
    return state.currentRoundStatus == LoadStatus.error &&
        state.snapshotStatus == LoadStatus.error;
  }

  static bool _allEmpty(GamesState state) {
    final currentRoundEmpty =
        state.currentRoundStatus == LoadStatus.empty ||
        state.currentRoundStatus == LoadStatus.error;
    final snapshotEmpty =
        state.snapshotStatus == LoadStatus.empty ||
        state.snapshotStatus == LoadStatus.error;
    return currentRoundEmpty &&
        snapshotEmpty &&
        state.currentRoundMatches.isEmpty &&
        state.nextMatch == null;
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
              ? _centered(const GoiasLoadingIndicator())
              : _allFailed(state)
              ? _centered(
                  StateMessage(
                    icon: Icons.wifi_off_rounded,
                    title: context.l10n.matchLoadError,
                    message:
                        state.currentRoundErrorMessage ??
                        state.snapshotErrorMessage,
                  ),
                )
              : _allEmpty(state)
              ? _centered(
                  StateMessage(
                    icon: Icons.event_busy_rounded,
                    title: context.l10n.matchNoMatches,
                  ),
                )
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
      Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Center(child: child),
      ),
    ],
  );
}

bool _isLive(Match match) =>
    match.status == MatchStatus.live || match.status == MatchStatus.halftime;

class _MatchesContent extends StatelessWidget {
  const _MatchesContent({required this.state, required this.onMatchTap});

  final GamesState state;
  final ValueChanged<Match> onMatchTap;

  @override
  Widget build(BuildContext context) {
    final nextMatch = state.nextMatch;
    // O jogo do Goiás já aparece em destaque no card do topo (com placar
    // ao vivo quando for o caso) — repeti-lo na lista da rodada logo
    // abaixo seria redundante.
    final roundMatches = nextMatch == null
        ? state.currentRoundMatches
        : state.currentRoundMatches
              .where((match) => match.id != nextMatch.id)
              .toList(growable: false);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        if (nextMatch != null) ...[
          _isLive(nextMatch)
              ? LiveMatchPoller(
                  match: nextMatch,
                  onMatchEnded: () => context.read<GamesCubit>().refresh(),
                  builder: (context, liveMatch) => NextMatchCard(
                    match: liveMatch,
                    onBuyTicket: () => context.push('/tickets'),
                    onViewDetails: () => onMatchTap(liveMatch),
                  ),
                )
              : NextMatchCard(
                  match: nextMatch,
                  onBuyTicket: () => context.push('/tickets'),
                  onViewDetails: () => onMatchTap(nextMatch),
                ),
          const SizedBox(height: AppSpacing.xxl),
        ],
        if (roundMatches.isNotEmpty) ...[
          _RoundNavigationHeader(state: state),
          const SizedBox(height: AppSpacing.md),
          if (state.currentRoundStatus == LoadStatus.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(child: GoiasLoadingIndicator()),
            )
          else
            for (final match in roundMatches) ...[
              MatchListItem(match: match, onTap: () => onMatchTap(match)),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ],
    );
  }
}

/// Substitui o antigo título fixo "RODADA ATUAL" — agora mostra o rótulo
/// real da rodada (ex.: "Rodada 25") e deixa navegar pras rodadas
/// anteriores/seguintes, sempre relativo à rodada atual (ver
/// `GamesCubit.previousRound`/`nextRound`).
class _RoundNavigationHeader extends StatelessWidget {
  const _RoundNavigationHeader({required this.state});

  final GamesState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<GamesCubit>();
    final navigating = state.currentRoundStatus == LoadStatus.loading;
    return Row(
      children: [
        _RoundArrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: (state.hasPreviousRound && !navigating)
              ? cubit.previousRound
              : null,
        ),
        Expanded(
          child: Text(
            (state.roundLabel ?? 'Rodada atual').toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: navigating ? colors.textHint : colors.textPrimary,
            ),
          ),
        ),
        _RoundArrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: (state.hasNextRound && !navigating) ? cubit.nextRound : null,
        ),
      ],
    );
  }
}

class _RoundArrowButton extends StatelessWidget {
  const _RoundArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: colors.textPrimary,
      disabledColor: colors.textHint.withValues(alpha: 0.3),
      style: IconButton.styleFrom(
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
