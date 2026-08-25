import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
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
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

class GuessPlayerPage extends StatelessWidget {
  const GuessPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = sl<GuessPlayerStorage>();
    return BlocProvider(
      create: (_) => GuessPlayerCubit(
        catalog: guessPlayerCatalog,
        loadRound: storage.loadActiveRound,
        saveRound: storage.saveActiveRound,
        clearRound: storage.clearActiveRound,
        recordRoundResult: storage.recordRoundResult,
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
    await AppBottomSheet.show(
      context,
      icon: round.won
          ? Icons.emoji_events_rounded
          : Icons.sports_soccer_rounded,
      title: round.won ? 'ACERTOU!' : 'ERA ${secret.displayName.toUpperCase()}',
      description: round.won
          ? '${secret.displayName}\n\nVocê acertou em ${round.attemptsUsed} de $maxGuessAttempts tentativas.'
          : 'Não foi dessa vez.',
      confirmLabel: 'PRÓXIMO JOGADOR',
      isDismissible: false,
      onConfirm: () {
        if (context.mounted) context.read<GuessPlayerCubit>().nextPlayer();
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
                    title: 'QUEM VESTIU O MANTO?',
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
          'Nenhum jogador disponível pra essa arena ainda.',
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
                  ? 'Rodada encerrada'
                  : '${round.attemptsRemaining} tentativas restantes',
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
              catalog: guessablePlayers,
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
