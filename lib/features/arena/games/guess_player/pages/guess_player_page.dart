import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/guess_player/cubit/guess_player_cubit.dart';
import 'package:goias_app/features/arena/games/guess_player/cubit/guess_player_state.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_catalog.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_storage.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_round_state.dart';
import 'package:goias_app/features/arena/games/guess_player/widgets/guess_autocomplete_field.dart';
import 'package:goias_app/features/arena/games/guess_player/widgets/guess_blurred_photo.dart';
import 'package:goias_app/features/arena/games/guess_player/widgets/guess_comparison_table.dart';
import 'package:goias_app/features/arena/games/guess_player/widgets/guess_confetti.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_header.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

/// [cubit], quando fornecido, já veio construído com o catálogo carregado
/// por quem navegou pra cá (ver `GlobalLoading.run` em `arena_page.dart`)
/// — a tela só reaproveita via `BlocProvider.value`. Fica `null` (e a tela
/// cria/carrega o próprio Cubit com o catálogo local) só em navegação
/// direta por URL.
class GuessPlayerPage extends StatelessWidget {
  const GuessPlayerPage({this.cubit, super.key});

  final GuessPlayerCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final preloaded = cubit;
    if (preloaded != null) {
      return BlocProvider.value(
        value: preloaded,
        child: const _GuessPlayerView(),
      );
    }
    final storage = sl<GuessPlayerStorage>();
    return BlocProvider(
      create: (_) => GuessPlayerCubit(
        catalog: guessPlayerCatalog,
        loadRound: storage.loadActiveRound,
        saveRound: storage.saveActiveRound,
        clearRound: storage.clearActiveRound,
        recordRoundResult: storage.recordRoundResult,
        ranking: sl<ArenaRankingRepository>(),
      ),
      child: const _GuessPlayerView(),
    );
  }
}

class _GuessPlayerView extends StatelessWidget {
  const _GuessPlayerView();

  Future<void> _showRoundOverSheet(
    BuildContext context,
    GuessPlayerState state,
  ) async {
    final round = state.round!;
    final secret = state.secretPlayer!;
    final cubit = context.read<GuessPlayerCubit>();
    final hasNextPlayer = cubit.hasEligibleSecret;
    await AppBottomSheet.show(
      context,
      icon: round.won
          ? Icons.emoji_events_rounded
          : Icons.sports_soccer_rounded,
      title: round.won
          ? context.l10n.guessCorrectTitle
          : context.l10n.guessOutOfAttempts,
      description: round.won
          ? '${secret.displayName}\n\n${context.l10n.guessCorrectDetail(round.attemptsUsed, maxGuessAttempts)}'
          : null,
      content: round.won ? null : _SecretPlayerReveal(name: secret.displayName),
      confirmLabel: hasNextPlayer
          ? context.l10n.careerNextPlayer
          : context.l10n.commonBack,
      isDismissible: false,
      onConfirm: () {
        if (!context.mounted) return;
        if (hasNextPlayer) {
          cubit.nextPlayer();
        } else {
          context.canPop() ? context.pop() : context.go('/');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<GuessPlayerCubit, GuessPlayerState>(
      listenWhen: (previous, current) =>
          previous.round?.isOver != true && current.round?.isOver == true,
      listener: (context, state) => _showRoundOverSheet(context, state),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ArenaGameHeader(
                    title: context.l10n.arenaGuessPlayerTitle.toUpperCase(),
                    onBack: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(child: _Body(state: state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final GuessPlayerState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (state.status == LoadStatus.empty) {
      return Center(
        child: Text(
          context.l10n.guessNoPlayers,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textHint, fontSize: 14),
        ),
      );
    }

    if (state.status != LoadStatus.success ||
        state.secretPlayer == null ||
        state.round == null) {
      return const Center(child: GoiasLoadingIndicator());
    }

    final round = state.round!;
    final secret = state.secretPlayer!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GuessBlurredPhoto(
                    imageUrl: secret.imageUrl!,
                    sigma: round.blurSigma,
                  ),
                  if (round.won) const Positioned.fill(child: GuessConfetti()),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              round.isOver
                  ? context.l10n.guessRoundEnded
                  : context.l10n.guessAttemptsRemaining(
                      round.attemptsRemaining,
                    ),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!round.isOver)
            GuessAutocompleteField(
              catalog: context
                  .read<GuessPlayerCubit>()
                  .catalog
                  .where((player) => player.hasFullHints)
                  .toList(growable: false),
              excludedIds: round.guessedPlayerIds.toSet(),
              onSubmit: (guess) =>
                  context.read<GuessPlayerCubit>().submitGuess(guess),
            ),
          if (state.comparisons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            GuessComparisonTable(results: state.comparisons),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Conteúdo da bottom sheet de derrota — só o nome do jogador secreto em
/// destaque (verde/negrito), sem repetir o ícone/título já mostrados acima.
class _SecretPlayerReveal extends StatelessWidget {
  const _SecretPlayerReveal({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 14.5,
          height: 1.4,
          color: colors.textSecondary,
        ),
        children: [
          TextSpan(text: context.l10n.guessThePlayerWas),
          TextSpan(
            text: name,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colors.primary,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
