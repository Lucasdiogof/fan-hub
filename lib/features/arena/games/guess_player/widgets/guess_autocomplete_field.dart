import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/shared/utils/normalize_name.dart';

/// Campo de chute com autocomplete — nunca permite enviar um nome livre,
/// só um jogador realmente selecionado da lista (mesmo padrão do Adivinhe
/// o Jogador).
class GuessAutocompleteField extends StatefulWidget {
  const GuessAutocompleteField({
    required this.catalog,
    required this.excludedIds,
    required this.onSubmit,
    super.key,
  });

  final List<GuessPlayer> catalog;
  final Set<String> excludedIds;
  final ValueChanged<GuessPlayer> onSubmit;

  @override
  State<GuessAutocompleteField> createState() => _GuessAutocompleteFieldState();
}

class _GuessAutocompleteFieldState extends State<GuessAutocompleteField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  late final List<String> _suggestions;
  late final Map<String, GuessPlayer> _resolveMap;
  bool _canGuess = false;

  static const _minChars = 2;
  static const _maxResults = 8;

  @override
  void initState() {
    super.initState();
    final resolve = <String, GuessPlayer>{};
    for (final player in widget.catalog) {
      resolve[normalizeName(player.displayName)] = player;
      resolve[normalizeName(player.name)] = player;
      for (final alias in player.aliases) {
        resolve[normalizeName(alias)] = player;
      }
    }
    final names = <String>[];
    final seen = <String>{};
    for (final player in widget.catalog) {
      if (seen.add(normalizeName(player.displayName))) {
        names.add(player.displayName);
      }
    }
    names.sort();
    _suggestions = names;
    _resolveMap = resolve;
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    final resolved = _resolveMap[normalizeName(_controller.text)];
    final can = resolved != null && !widget.excludedIds.contains(resolved.id);
    if (can != _canGuess) setState(() => _canGuess = can);
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final resolved = _resolveMap[normalizeName(_controller.text)];
    if (resolved == null || widget.excludedIds.contains(resolved.id)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.careerSelectFromList)),
        );
      return;
    }
    widget.onSubmit(resolved);
    _controller.clear();
    _focusNode.unfocus();
    setState(() => _canGuess = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth;
            return RawAutocomplete<String>(
              textEditingController: _controller,
              focusNode: _focusNode,
              optionsViewOpenDirection: OptionsViewOpenDirection.down,
              optionsBuilder: (value) {
                final query = normalizeName(value.text);
                if (query.length < _minChars) {
                  return const Iterable<String>.empty();
                }
                return _suggestions
                    .where((name) => normalizeName(name).contains(query))
                    .take(_maxResults);
              },
              onSelected: (selection) => _controller.text = selection,
              fieldViewBuilder:
                  (context, textController, node, onFieldSubmitted) {
                    return TextField(
                      controller: textController,
                      focusNode: node,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: context.l10n.guessTypePlayer,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colors.textHint,
                        ),
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
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
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
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canGuess ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor: colors.primary.withValues(alpha: 0.3),
              disabledForegroundColor: colors.onPrimary.withValues(alpha: 0.75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              context.l10n.careerGuess,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
