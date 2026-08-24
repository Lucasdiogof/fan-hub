import 'package:flutter/material.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_state.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_matches.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_storage.dart';
import 'package:goias_app/features/arena/games/lineup/pages/lineup_guess_page.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_field_background.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_result_dialog.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_shirt_button.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/date_labels.dart';

class LineupPage extends StatelessWidget {
  const LineupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = sl<LineupStorage>();

    return BlocProvider(
      create: (_) => LineupCubit(
        matches: lineupMatches,
        loadState: storage.load,
        saveState: storage.save,
        loadSelectedMatchId: storage.loadSelectedMatchId,
        saveSelectedMatchId: storage.saveSelectedMatchId,
      ),
      child: const _LineupView(),
    );
  }
}

class _LineupView extends StatefulWidget {
  const _LineupView();

  @override
  State<_LineupView> createState() => _LineupViewState();
}

class _LineupViewState extends State<_LineupView> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<LineupCubit, LineupState>(
      listenWhen: (previous, current) =>
          current.justCompleted && !previous.justCompleted,
      listener: (context, state) async {
        final cubit = context.read<LineupCubit>();
        await showLineupResultDialog(
          context,
          state,
          onPrevious: state.hasPrevious ? () => _goToAdjacentMatch(context, cubit.previousMatch) : null,
          onNext: state.hasNext ? () => _goToAdjacentMatch(context, cubit.nextMatch) : null,
        );
        if (context.mounted) cubit.acknowledgeResultShown();
      },
      builder: (context, state) {
        if (state.status == LoadStatus.loading ||
            state.match == null ||
            state.game == null) {
          return Scaffold(
            backgroundColor: colors.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final match = state.match!;
        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () =>
                            context.canPop() ? context.pop() : context.go('/'),
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
                      ),
                      const Spacer(),
                      _ProgressPill(
                        solved: state.solvedCount,
                        total: state.totalPlayers,
                      ),
                    ],
                  ),
                ),
                _MatchNav(
                  index: state.currentIndex ?? 0,
                  total: state.totalMatches,
                  hasPrevious: state.hasPrevious,
                  hasNext: state.hasNext,
                  onPrevious: () => context.read<LineupCubit>().previousMatch(),
                  onNext: () => context.read<LineupCubit>().nextMatch(),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MatchHeader(match: match),
                const SizedBox(height: AppSpacing.xs),
                if (state.isComplete)
                  TextButton.icon(
                    onPressed: () => showLineupResultDialog(
                      context,
                      state,
                      onPrevious: state.hasPrevious ? () => _goToAdjacentMatch(context, context.read<LineupCubit>().previousMatch) : null,
                      onNext: state.hasNext ? () => _goToAdjacentMatch(context, context.read<LineupCubit>().nextMatch) : null,
                    ),
                    icon: const Icon(Icons.emoji_events_outlined, size: 16),
                    label: const Text('VER RESULTADO'),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 14,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Toque em uma camisa para adivinhar',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 0.66,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          child: Stack(
                            children: [
                              const Positioned.fill(
                                child: LineupFieldBackground(),
                              ),
                              for (final player in match.players)
                                Align(
                                  alignment: Alignment(
                                    player.x * 2 - 1,
                                    player.y * 2 - 1,
                                  ),
                                  child: LineupShirtButton(
                                    key: ValueKey(player.id),
                                    player: player,
                                    playerState:
                                        state.game!.playerStates[player.id] ??
                                        const LineupPlayerState(),
                                    onTap: () =>
                                        _openPlayer(context, player.id),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!state.isComplete)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xs),
                    child: TextButton.icon(
                      onPressed: () => _confirmGiveUp(context),
                      style: TextButton.styleFrom(foregroundColor: colors.textHint),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text(
                        'Desistir da partida',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  /// "Próximo jogo"/"Anterior" no diálogo de resultado podem acontecer
  /// enquanto a tela de adivinhação (empilhada por [_openPlayer]) ainda
  /// está por cima do campo — `popUntil((route) => route.isFirst)` garante
  /// que voltamos pro campo antes de trocar de partida, sem isso a tela de
  /// adivinhação ficaria por cima mostrando os jogadores da partida
  /// errada. É um no-op seguro quando já estamos no campo (nada pra
  /// popar).
  void _goToAdjacentMatch(BuildContext context, Future<void> Function() action) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    action();
  }

  void _openPlayer(BuildContext context, String playerId) {
    final cubit = context.read<LineupCubit>();
    cubit.selectPlayer(playerId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const LineupGuessPage()),
      ),
    );
  }

  Future<void> _confirmGiveUp(BuildContext context) async {
    final cubit = context.read<LineupCubit>();
    final confirmed = await AppBottomSheet.show(
      context,
      icon: Icons.flag_outlined,
      title: 'Desistir da partida?',
      description: 'Os jogadores restantes serão revelados e a partida será encerrada.',
      confirmLabel: 'DESISTIR',
      cancelLabel: 'Continuar jogando',
    );
    if (confirmed == true) {
      await cubit.giveUp();
    }
  }
}

/// Navegação entre as partidas do banco — setas + "PARTIDA N DE M",
/// separado do `_ProgressPill` do topo (que conta jogadores descobertos
/// DENTRO da partida atual, não qual partida é essa).
class _MatchNav extends StatelessWidget {
  const _MatchNav({
    required this.index,
    required this.total,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final int total;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavArrow(icon: Icons.chevron_left_rounded, onTap: hasPrevious ? onPrevious : null),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'PARTIDA ${index + 1} DE $total',
          style: TextStyle(color: colors.textHint, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
        ),
        const SizedBox(width: AppSpacing.sm),
        _NavArrow(icon: Icons.chevron_right_rounded, onTap: hasNext ? onNext : null),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: enabled ? colors.primary : colors.textHint.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({required this.match});

  final LineupMatch match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            '${match.competition.toUpperCase()} ${match.season}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            match.phase.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${match.homeTeam.toUpperCase()} ${match.homeScore} x ${match.awayScore} ${match.awayTeam.toUpperCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            fullDateLabel(match.date),
            style: TextStyle(
              color: colors.textHint,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.solved, required this.total});

  final int solved;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$solved/$total',
        style: TextStyle(
          color: colors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
