import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/career_path/career_autocomplete.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/data/career_player_repository.dart';
import 'package:goias_app/features/arena/games/career_path/data/supabase_career_path_storage.dart';
import 'package:goias_app/features/arena/games/career_path/goias_players.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_cubit.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_state.dart';
import 'package:goias_app/features/arena/games/career_path/widgets/career_table.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_header.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

/// [cubit], quando fornecido, já veio construído e com o último jogador
/// visto carregado por quem navegou pra cá (ver `GlobalLoading.run` em
/// `arena_page.dart`) — a tela só reaproveita via `BlocProvider.value`.
/// Fica `null` (e a tela busca os jogadores do repository ela mesma —
/// SEMPRE via `CareerPlayerRepository`, nunca a lista local direto, senão
/// um clube não-Goiás acessando por deep link veria dado do Goiás pra
/// sempre) só em navegação direta por URL.
class CareerPathPage extends StatelessWidget {
  const CareerPathPage({this.cubit, super.key});

  final CareerPathCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final preloaded = cubit;
    if (preloaded != null) {
      return BlocProvider.value(
        value: preloaded,
        child: const _CareerPathView(),
      );
    }
    return const _CareerPathLoader();
  }
}

/// Só existe pro caminho de deep link (sem [CareerPathPage.cubit]
/// preloaded) — busca os jogadores tenant-scoped antes de montar o Cubit,
/// exatamente como `arena_page.dart._openCareerPath` já faz pra quem
/// navega pelo card da Arena.
class _CareerPathLoader extends StatefulWidget {
  const _CareerPathLoader();

  @override
  State<_CareerPathLoader> createState() => _CareerPathLoaderState();
}

class _CareerPathLoaderState extends State<_CareerPathLoader> {
  late final Future<CareerPathCubit> _future = _build();

  Future<CareerPathCubit> _build() async {
    final players = await sl<CareerPlayerRepository>().load();
    final storage = sl<SupabaseCareerPathStorage>();
    final cubit = CareerPathCubit(
      players: players,
      loadRound: storage.load,
      saveRound: storage.save,
      loadSelectedId: storage.loadSelectedPlayerId,
      saveSelectedId: storage.saveSelectedPlayerId,
      loadCompletedIds: storage.completedIds,
      ranking: sl<ArenaRankingRepository>(),
    );
    await cubit.loadSelected();
    return cubit;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CareerPathCubit>(
      future: _future,
      builder: (context, snapshot) {
        final cubit = snapshot.data;
        if (cubit == null) {
          return const Scaffold(body: Center(child: GoiasLoadingIndicator()));
        }
        return BlocProvider.value(value: cubit, child: const _CareerPathView());
      },
    );
  }
}

class _CareerPathView extends StatefulWidget {
  const _CareerPathView();

  @override
  State<_CareerPathView> createState() => _CareerPathViewState();
}

class _CareerPathViewState extends State<_CareerPathView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  late final List<String> _suggestions;
  late final Map<String, String> _resolveMap;
  bool _canGuess = false;

  /// Nome do último chute errado — aparece na barra de tentativas por
  /// alguns segundos. [_shakeTick] muda a cada erro e dispara o tremor.
  String? _wrongName;
  int _shakeTick = 0;
  Timer? _wrongTimer;

  void _onWrongGuess(String name) {
    HapticFeedback.mediumImpact();
    _wrongTimer?.cancel();
    setState(() {
      _wrongName = name;
      _shakeTick++;
    });
    _wrongTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _wrongName = null);
    });
  }

  @override
  void initState() {
    super.initState();
    final players = context.read<CareerPathCubit>().state.players;
    // Prioridade EXPLÍCITA career_players > goiasPlayers em caso de
    // colisão de texto (nunca mais dependente da ordem de inserção — ver
    // career_autocomplete.dart). Nenhuma colisão real existe hoje (Etapa
    // F6), mas o índice já reporta se um dia existir.
    final index = buildCareerAutocompleteIndex(
      careerPlayers: players,
      goiasPlayers: goiasPlayers,
    );

    _suggestions = index.suggestions.map((s) => s.label).toList();
    _resolveMap = index.resolveMap;
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    final can = _resolveMap.containsKey(normalizeName(_controller.text));
    if (can != _canGuess) setState(() => _canGuess = can);
  }

  @override
  void dispose() {
    _wrongTimer?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitGuess(BuildContext context) {
    final resolved = _resolveMap[normalizeName(_controller.text)];
    if (resolved == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.careerSelectFromList)),
        );
      return;
    }
    context.read<CareerPathCubit>().guess(resolved);
    _controller.clear();
    _focusNode.unfocus();
  }

  Future<void> _confirmReveal(BuildContext context) async {
    final cubit = context.read<CareerPathCubit>();
    final confirmed = await AppBottomSheet.show(
      context,
      icon: Icons.visibility_outlined,
      title: context.l10n.careerRevealTitle,
      description: context.l10n.careerRevealMessage,
      confirmLabel: context.l10n.careerReveal,
      cancelLabel: context.l10n.commonCancel,
    );
    if (confirmed == true) await cubit.reveal();
  }

  Future<void> _showResult(BuildContext context, CareerPathState state) async {
    final cubit = context.read<CareerPathCubit>();
    final player = state.player;
    if (player == null) return;
    final status = state.roundStatus;
    final attempts = state.round?.attemptsToWin ?? state.attemptsUsed;

    final l10n = context.l10n;
    final (title, description) = switch (status) {
      CareerRoundStatus.won => (
        l10n.careerCorrectTitle,
        attempts == 1
            ? l10n.careerCorrectFirstTry
            : l10n.careerCorrectInAttempts(attempts),
      ),
      CareerRoundStatus.lost => (
        l10n.careerWrongTitle,
        l10n.careerUsedAllAttempts(CareerPathCubit.maxAttempts),
      ),
      _ => (l10n.careerPlayerRevealed, l10n.careerRoundEnded),
    };

    await AppBottomSheet.show(
      context,
      icon: status == CareerRoundStatus.won
          ? Icons.emoji_events_rounded
          : Icons.person_rounded,
      title: title,
      description: description,
      content: _PlayerReveal(player: player),
      confirmLabel: l10n.careerNextPlayer,
      cancelLabel: l10n.commonCloseLabel,
      onConfirm: cubit.goToNextOrFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocListener<CareerPathCubit, CareerPathState>(
      // Erro que ainda deixa tentativas: o fim da rodada já tem o seu
      // próprio aviso (o bottom sheet de resultado).
      listenWhen: (previous, current) {
        final before = previous.round?.wrongGuesses.length ?? 0;
        final after = current.round?.wrongGuesses.length ?? 0;
        return after > before && !(current.round?.isDone ?? true);
      },
      listener: (context, state) =>
          _onWrongGuess(state.round!.wrongGuesses.last),
      child: BlocConsumer<CareerPathCubit, CareerPathState>(
        listenWhen: (previous, current) =>
            current.justFinished && !previous.justFinished,
        listener: (context, state) async {
          final cubit = context.read<CareerPathCubit>();
          await _showResult(context, state);
          if (context.mounted) cubit.acknowledgeResultShown();
        },
        builder: (context, state) {
          if (state.status == LoadStatus.loading ||
              state.player == null ||
              state.round == null) {
            return Scaffold(
              backgroundColor: colors.background,
              body: const Center(child: GoiasLoadingIndicator()),
            );
          }

          final player = state.player!;
          return Scaffold(
            backgroundColor: colors.background,
            body: SafeArea(
              child: Column(
                children: [
                  _Header(
                    index: state.roundNumber == 0 ? 0 : state.roundNumber - 1,
                    total: state.total,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: CareerTable(player: player),
                    ),
                  ),
                  _BottomBar(
                    child: state.isDone
                        ? _ResolvedBlock(
                            player: player,
                            status: state.roundStatus,
                            onNext: () => context
                                .read<CareerPathCubit>()
                                .goToNextOrFirst(),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AttemptsBar(
                                used: state.attemptsUsed,
                                max: CareerPathCubit.maxAttempts,
                                wrongName: _wrongName,
                                shakeTick: _shakeTick,
                              ),
                              if (state.round!.wrongGuesses.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                _TriedNames(names: state.round!.wrongGuesses),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              _GuessBlock(
                                controller: _controller,
                                focusNode: _focusNode,
                                suggestions: _suggestions,
                                canGuess: _canGuess,
                                onSubmit: () => _submitGuess(context),
                                onReveal: () => _confirmReveal(context),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: ArenaGameHeader(
        title: context.l10n.arenaGameCareerTitle.toUpperCase(),
        subtitle: context.l10n.careerSubtitle,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        trailing: _CountPill(index: index, total: total),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.index, required this.total});

  final int index;
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
        '${index + 1}/$total',
        style: TextStyle(
          color: colors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: child,
    );
  }
}

/// Cor de erro do app — nunca vermelho (mesmo âmbar dos selos da
/// Escalação).
const _wrongColor = Color(0xFFC99A36);

class _AttemptsBar extends StatelessWidget {
  const _AttemptsBar({
    required this.used,
    required this.max,
    required this.wrongName,
    required this.shakeTick,
  });

  final int used;
  final int max;

  /// Último chute errado, enquanto o aviso estiver na tela.
  final String? wrongName;

  /// Muda a cada erro; reinicia o tremor.
  final int shakeTick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = max - used;
    final wrong = wrongName != null;
    final bar = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: wrong ? _wrongColor.withValues(alpha: 0.12) : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: wrong ? _wrongColor : colors.border,
          width: wrong ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              wrong
                  ? context.l10n.careerWrongGuessFeedback(wrongName!, remaining)
                  : context.l10n.careerAttemptsRemaining(remaining),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: wrong ? FontWeight.w800 : FontWeight.w700,
                color: wrong ? _wrongColor : colors.textSecondary,
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < max; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _AttemptDot(spent: i < used),
                ),
            ],
          ),
        ],
      ),
    );
    if (shakeTick == 0) return bar;
    return TweenAnimationBuilder<double>(
      key: ValueKey(shakeTick),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 6) * (1 - t) * 8, 0),
        child: child,
      ),
      child: bar,
    );
  }
}

class _AttemptDot extends StatelessWidget {
  const _AttemptDot({required this.spent});

  final bool spent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: spent ? _wrongColor : colors.primary,
      ),
      child: spent
          ? const Icon(Icons.close_rounded, size: 10, color: Colors.white)
          : null,
    );
  }
}

/// Chutes errados da rodada, riscados — pra não repetir nome.
class _TriedNames extends StatelessWidget {
  const _TriedNames({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${context.l10n.careerTriedLabel}:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        for (final name in names)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _wrongColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _wrongColor,
                decoration: TextDecoration.lineThrough,
                decorationColor: _wrongColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _GuessBlock extends StatelessWidget {
  const _GuessBlock({
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.canGuess,
    required this.onSubmit,
    required this.onReveal,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final bool canGuess;
  final VoidCallback onSubmit;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NameField(
          controller: controller,
          focusNode: focusNode,
          suggestions: suggestions,
          onSubmit: onSubmit,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: canGuess ? onSubmit : null,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: colors.primary.withValues(alpha: 0.3),
              disabledForegroundColor: colors.onPrimary.withValues(alpha: 0.75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              context.l10n.careerGuess,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          onPressed: onReveal,
          style: TextButton.styleFrom(
            foregroundColor: colors.textSecondary,
            minimumSize: const Size.fromHeight(46),
          ),
          child: Text(
            context.l10n.careerRevealPlayer,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final VoidCallback onSubmit;

  static const _minChars = 2;
  static const _maxResults = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.maxWidth;
        return RawAutocomplete<String>(
          textEditingController: controller,
          focusNode: focusNode,
          optionsViewOpenDirection: OptionsViewOpenDirection.up,
          optionsBuilder: (value) {
            final query = normalizeName(value.text);
            if (query.length < _minChars) return const Iterable<String>.empty();
            return suggestions
                .where((name) => normalizeName(name).contains(query))
                .take(_maxResults);
          },
          onSelected: (selection) => controller.text = selection,
          fieldViewBuilder: (context, textController, node, onFieldSubmitted) {
            return TextField(
              controller: textController,
              focusNode: node,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                hintText: context.l10n.lineupTypePlayerName,
                prefixIcon: Icon(Icons.search_rounded, color: colors.textHint),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  borderSide: BorderSide(color: colors.primary, width: 1.6),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                  color: colors.surface,
                  child: SizedBox(
                    width: fieldWidth,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ResolvedBlock extends StatelessWidget {
  const _ResolvedBlock({
    required this.player,
    required this.status,
    required this.onNext,
  });

  final CareerPlayer player;
  final CareerRoundStatus status;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = switch (status) {
      CareerRoundStatus.won => context.l10n.careerYouGotIt,
      CareerRoundStatus.lost => context.l10n.careerWas,
      _ => context.l10n.careerAnswer,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                player.answer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              if (player.position != null) ...[
                const SizedBox(height: 2),
                Text(
                  player.position!,
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              context.l10n.careerNextPlayer,
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerReveal extends StatelessWidget {
  const _PlayerReveal({required this.player});

  final CareerPlayer player;

  String get _initials {
    final parts = player.answer.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.secondary,
            shape: BoxShape.circle,
          ),
          child: Text(
            _initials,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          player.answer,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        if (player.position != null) ...[
          const SizedBox(height: 2),
          Text(
            player.position!,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}
