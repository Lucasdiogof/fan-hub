import 'package:flutter/material.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/router/app_page.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_state.dart';
import 'package:goias_app/features/arena/games/lineup/data/supabase_lineup_storage.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_matches.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/lineup/pages/lineup_guess_page.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_result_dialog.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/lineup_shirt_button.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_header.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/features/crowd_lineup/presentation/layout/lineup_layout_engine.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/lineup_field.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// [cubit], quando fornecido, já veio construído e com a última partida
/// vista carregada por quem navegou pra cá (ver `GlobalLoading.run` em
/// `arena_page.dart`) — a tela só reaproveita via `BlocProvider.value`.
/// Fica `null` (e a tela cria/carrega o próprio Cubit) só em navegação
/// direta por URL.
class LineupPage extends StatelessWidget {
  const LineupPage({this.cubit, super.key});

  final LineupCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final preloaded = cubit;
    if (preloaded != null) {
      return BlocProvider.value(value: preloaded, child: const _LineupView());
    }
    final storage = sl<SupabaseLineupStorage>();
    return BlocProvider(
      create: (_) => LineupCubit(
        matches: orderedLineupMatches,
        loadState: storage.load,
        saveState: storage.save,
        loadSelectedMatchId: storage.loadSelectedMatchId,
        saveSelectedMatchId: storage.saveSelectedMatchId,
        loadCompletedIds: storage.completedIds,
        ranking: sl<ArenaRankingRepository>(),
      )..loadSelectedMatch(),
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
          onPrevious: state.hasPrevious
              ? () => _goToAdjacentMatch(context, cubit.previousMatch)
              : null,
          onNext: state.hasNext
              ? () => _goToAdjacentMatch(context, cubit.nextMatch)
              : null,
        );
        if (context.mounted) cubit.acknowledgeResultShown();
      },
      builder: (context, state) {
        if (state.status == LoadStatus.loading ||
            state.match == null ||
            state.game == null) {
          return Scaffold(
            backgroundColor: colors.background,
            body: const Center(child: GoiasLoadingIndicator()),
          );
        }

        final match = state.match!;
        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ContentWidth.interactive.maxWidth,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: ArenaGameHeader(
                        title: context.l10n.arenaGameLineupTitle.toUpperCase(),
                        onBack: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                        trailing: _ProgressPill(
                          solved: state.solvedCount,
                          total: state.totalPlayers,
                        ),
                      ),
                    ),
                    _MatchNav(
                      index: state.currentIndex ?? 0,
                      total: state.totalMatches,
                      hasPrevious: state.hasPrevious,
                      hasNext: state.hasNext,
                      onPrevious: () =>
                          context.read<LineupCubit>().previousMatch(),
                      onNext: () => context.read<LineupCubit>().nextMatch(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _MatchHeader(match: match),
                    const SizedBox(height: 2),
                    if (state.isComplete)
                      TextButton.icon(
                        onPressed: () => showLineupResultDialog(
                          context,
                          state,
                          onPrevious: state.hasPrevious
                              ? () => _goToAdjacentMatch(
                                  context,
                                  context.read<LineupCubit>().previousMatch,
                                )
                              : null,
                          onNext: state.hasNext
                              ? () => _goToAdjacentMatch(
                                  context,
                                  context.read<LineupCubit>().nextMatch,
                                )
                              : null,
                        ),
                        icon: const Icon(Icons.emoji_events_outlined, size: 16),
                        label: Text(context.l10n.quizSeeResult),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Center(
                          child: LineupField(
                            formation: _formationFor(match.players),
                            mode: LineupRenderMode.editable,
                            slotBuilder: (slotIndex, slot, footprint) {
                              final player = match.players[slotIndex];
                              return LineupShirtButton(
                                key: ValueKey(player.id),
                                player: player,
                                playerState:
                                    state.game!.playerStates[player.id] ??
                                    const LineupPlayerState(),
                                shirtSize: footprint.jerseySize,
                                onTap: () => _openPlayer(context, player.id),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (!state.isComplete)
                      Padding(
                        // `bottom` bem maior que o normal de propósito: só a
                        // margem mínima do `SafeArea` (inset do home
                        // indicator) não é suficiente no iOS — o gesto de
                        // arrastar pra fechar o app ainda captura o toque
                        // perto demais da borda, mesmo dentro da área seguro.
                        padding: const EdgeInsets.only(
                          top: 2,
                          bottom: AppSpacing.xl,
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmGiveUp(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.gold,
                            backgroundColor: colors.gold.withValues(alpha: 0.1),
                            side: BorderSide(color: colors.gold, width: 1.2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.flag_rounded, size: 15),
                          label: Text(
                            context.l10n.lineupGiveUp,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// "Próximo jogo"/"Anterior" no diálogo de resultado podem acontecer
  /// enquanto a tela de adivinhação (empilhada por [_openPlayer]) ainda
  /// está por cima do campo — sem popar de volta antes, ela ficaria por
  /// cima mostrando os jogadores da partida errada. `LineupPage` mora
  /// dentro do `ShellRoute` do go_router (mesmo Navigator compartilhado com
  /// Home/Arena/etc.), então `popUntil((route) => route.isFirst)` (versão
  /// antiga daqui) popava até a primeira rota de TODO o Navigator — voltava
  /// pra Arena/Home em vez de só fechar a tela de adivinhação. Capturar a
  /// própria rota da `LineupPage` via `ModalRoute.of(context)` e popar só
  /// até ela resolve isso: sobe exatamente uma tela (a de adivinhação,
  /// quando existe) e nunca mais que isso. Continua um no-op seguro quando
  /// já estamos no campo (`isCurrent` já `true`, nada pra popar).
  void _goToAdjacentMatch(
    BuildContext context,
    Future<void> Function() action,
  ) {
    final lineupRoute = ModalRoute.of(context);
    if (lineupRoute != null && !lineupRoute.isCurrent) {
      Navigator.of(context).popUntil((route) => route == lineupRoute);
    }
    action();
  }

  void _openPlayer(BuildContext context, String playerId) {
    final cubit = context.read<LineupCubit>();
    cubit.selectPlayer(playerId);
    Navigator.of(context).push(
      appRoute<void>(
        BlocProvider.value(value: cubit, child: const LineupGuessPage()),
      ),
    );
  }

  Future<void> _confirmGiveUp(BuildContext context) async {
    final cubit = context.read<LineupCubit>();
    final confirmed = await AppBottomSheet.show(
      context,
      icon: Icons.flag_outlined,
      title: context.l10n.lineupGiveUpTitle,
      description: context.l10n.lineupGiveUpMessage,
      confirmLabel: context.l10n.lineupGiveUpConfirm,
      cancelLabel: context.l10n.lineupKeepPlaying,
    );
    if (confirmed == true) {
      await cubit.giveUp();
    }
  }
}

/// Adapta os 11 titulares reais (com `x`/`y` curados por partida) pro
/// mesmo `Formation`/`LineupLayoutEngine` que "Escale seu Time" usa — nunca
/// reinventa o posicionamento aqui: tamanho de camisa fixo por breakpoint,
/// anti-colisão entre linhas/dentro da linha, tudo herdado de lá. A `y` de
/// cada jogador já agrupa quem está na mesma linha tática (curado no
/// dataset, ver `LineupPlayer.y`); ordenar essas linhas por `y` ascendente
/// e mapear pra `TacticalLine.values` na mesma ordem funciona porque o
/// enum já é declarado ataque→goleiro, exatamente a mesma convenção de "y
/// menor = mais perto do ataque" usada no dataset. `PlayerPosition.mc` é só
/// um valor de preenchimento em `FormationSlot` — nunca lido de volta: o
/// `slotBuilder` sempre resolve o jogador de verdade por `slotIndex`,
/// mapeado 1:1 com [players] na mesma ordem.
Formation _formationFor(List<LineupPlayer> players) {
  final indicesByY = <double, List<int>>{};
  for (var i = 0; i < players.length; i++) {
    indicesByY.putIfAbsent(players[i].y, () => []).add(i);
  }
  final sortedYs = indicesByY.keys.toList()..sort();

  final slots = List<FormationSlot?>.filled(players.length, null);
  for (var lineIndex = 0; lineIndex < sortedYs.length; lineIndex++) {
    final line =
        TacticalLine.values[lineIndex.clamp(0, TacticalLine.values.length - 1)];
    for (final playerIndex in indicesByY[sortedYs[lineIndex]]!) {
      final player = players[playerIndex];
      slots[playerIndex] = FormationSlot(
        PlayerPosition.mc,
        player.x,
        player.y,
        line,
      );
    }
  }

  return Formation(
    id: 'lineup-guess',
    label: 'lineup-guess',
    slots: [for (final slot in slots) slot!],
  );
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
        _NavArrow(
          icon: Icons.chevron_left_rounded,
          onTap: hasPrevious ? onPrevious : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          context.l10n.lineupMatchProgress(index + 1, total),
          style: TextStyle(
            color: colors.textHint,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _NavArrow(
          icon: Icons.chevron_right_rounded,
          onTap: hasNext ? onNext : null,
        ),
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
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? colors.primary
              : colors.textHint.withValues(alpha: 0.4),
        ),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 15,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${match.competition.toUpperCase()} ${match.season}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${match.homeTeam.toUpperCase()} ${match.homeScore} x ${match.awayScore} ${match.awayTeam.toUpperCase()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 13,
                  color: colors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  fullDateLabel(match.date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textHint,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
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
