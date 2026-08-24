import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/career_path_storage.dart';
import 'package:goias_app/features/arena/games/career_path/career_players.dart';
import 'package:goias_app/features/arena/games/career_path/goias_players.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_cubit.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_state.dart';
import 'package:goias_app/features/arena/games/career_path/widgets/career_table.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';

class CareerPathPage extends StatelessWidget {
  const CareerPathPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = sl<CareerPathStorage>();
    return BlocProvider(
      create: (_) => CareerPathCubit(
        players: careerPlayers,
        loadRound: storage.load,
        saveRound: storage.save,
        loadSelectedId: storage.loadSelectedPlayerId,
        saveSelectedId: storage.saveSelectedPlayerId,
      ),
      child: const _CareerPathView(),
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

  @override
  void initState() {
    super.initState();
    final resolve = <String, String>{};
    for (final entry in goiasPlayers) {
      resolve[normalizeName(entry.name)] = entry.name;
      for (final alias in entry.aliases) {
        resolve[normalizeName(alias)] = entry.name;
      }
    }
    for (final player in careerPlayers) {
      for (final answer in player.acceptedAnswers) {
        resolve[normalizeName(answer)] = player.answer;
      }
    }

    final names = <String>[];
    final seen = <String>{};
    void addName(String display) {
      if (seen.add(normalizeName(display))) names.add(display);
    }
    for (final player in careerPlayers) {
      addName(player.answer);
    }
    for (final entry in goiasPlayers) {
      addName(entry.name);
    }
    names.sort();

    _suggestions = names;
    _resolveMap = resolve;
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    final can = _resolveMap.containsKey(normalizeName(_controller.text));
    if (can != _canGuess) setState(() => _canGuess = can);
  }

  @override
  void dispose() {
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
          const SnackBar(content: Text('Selecione um jogador da lista.')),
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
      title: 'Revelar jogador?',
      description: 'Ao revelar a resposta, esta rodada será considerada encerrada.',
      confirmLabel: 'REVELAR',
      cancelLabel: 'Cancelar',
    );
    if (confirmed == true) await cubit.reveal();
  }

  Future<void> _showResult(BuildContext context, CareerPathState state) async {
    final cubit = context.read<CareerPathCubit>();
    final player = state.player;
    if (player == null) return;
    final status = state.roundStatus;
    final attempts = state.round?.attemptsToWin ?? state.attemptsUsed;

    final (title, description) = switch (status) {
      CareerRoundStatus.won => (
          'Você acertou!',
          attempts == 1
              ? 'Acertou de primeira!'
              : 'Você acertou em $attempts tentativas.',
        ),
      CareerRoundStatus.lost => (
          'Não foi dessa vez',
          'Você usou as ${CareerPathCubit.maxAttempts} tentativas.',
        ),
      _ => ('Jogador revelado', 'Rodada encerrada.'),
    };

    await AppBottomSheet.show(
      context,
      icon: status == CareerRoundStatus.won ? Icons.emoji_events_rounded : Icons.person_rounded,
      title: title,
      description: description,
      content: _PlayerReveal(player: player),
      confirmLabel: 'PRÓXIMO JOGADOR',
      cancelLabel: 'Fechar',
      onConfirm: cubit.goToNextOrFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<CareerPathCubit, CareerPathState>(
      listenWhen: (previous, current) => current.justFinished && !previous.justFinished,
      listener: (context, state) async {
        final cubit = context.read<CareerPathCubit>();
        await _showResult(context, state);
        if (context.mounted) cubit.acknowledgeResultShown();
      },
      builder: (context, state) {
        if (state.status == LoadStatus.loading || state.player == null || state.round == null) {
          return Scaffold(
            backgroundColor: colors.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final player = state.player!;
        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Column(
              children: [
                _Header(index: state.currentIndex ?? 0, total: state.total),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
                    child: CareerTable(player: player),
                  ),
                ),
                _BottomBar(
                  child: state.isDone
                      ? _ResolvedBlock(
                          player: player,
                          status: state.roundStatus,
                          onNext: () => context.read<CareerPathCubit>().goToNextOrFirst(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AttemptsBar(used: state.attemptsUsed, max: CareerPathCubit.maxAttempts),
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
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.canPop() ? context.pop() : context.go('/'),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: colors.textPrimary),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'ADIVINHE O JOGADOR',
                  style: TextStyle(color: colors.primary, fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                ),
                const SizedBox(height: 2),
                Text(
                  'Descubra pela carreira',
                  style: TextStyle(color: colors.textHint, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          _CountPill(index: index, total: total),
        ],
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
      decoration: BoxDecoration(color: colors.secondary, borderRadius: BorderRadius.circular(999)),
      child: Text(
        '${index + 1}/$total',
        style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w900),
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: child,
    );
  }
}

class _AttemptsBar extends StatelessWidget {
  const _AttemptsBar({required this.used, required this.max});

  final int used;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final remaining = max - used;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Tentativas · Restam $remaining',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary),
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
        color: spent ? Colors.transparent : colors.primary,
        border: Border.all(
          color: spent ? colors.primary.withValues(alpha: 0.25) : colors.primary,
          width: 1.5,
        ),
      ),
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
        _NameField(controller: controller, focusNode: focusNode, suggestions: suggestions, onSubmit: onSubmit),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: const Text('CHUTAR', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          onPressed: onReveal,
          style: TextButton.styleFrom(foregroundColor: colors.textSecondary, minimumSize: const Size.fromHeight(46)),
          child: const Text('Revelar jogador', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
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
            hintText: 'Digite o nome do jogador',
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
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          child: Text(option, style: TextStyle(fontSize: 14.5, color: colors.textPrimary)),
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
  const _ResolvedBlock({required this.player, required this.status, required this.onNext});

  final CareerPlayer player;
  final CareerRoundStatus status;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = switch (status) {
      CareerRoundStatus.won => 'Você acertou',
      CareerRoundStatus.lost => 'Era',
      _ => 'Resposta',
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
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: colors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                player.answer,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.primary),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ),
            child: const Text('PRÓXIMO JOGADOR', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
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
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
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
          decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
          child: Text(
            _initials,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          player.answer,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.textPrimary),
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
