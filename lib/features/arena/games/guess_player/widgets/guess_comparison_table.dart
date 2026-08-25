import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_comparison.dart';
import 'package:goias_app/shared/domain/player_position.dart';

/// Tabela de pistas — uma linha por palpite, mais recente no topo. Sem
/// vermelho: erro/diferente é neutro (cinza), só acerto é verde.
class GuessComparisonTable extends StatelessWidget {
  const GuessComparisonTable({required this.results, super.key});

  final List<GuessComparisonResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();
    final reversed = results.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            _HeaderCell('JOGADOR', flex: 3),
            _HeaderCell('POS', flex: 2),
            _HeaderCell('CAMISA', flex: 2),
            _HeaderCell('BASE', flex: 2),
            _HeaderCell('NAC', flex: 2),
            _HeaderCell('ESTREIA', flex: 2),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final result in reversed) ...[
          _ResultRow(result: result),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: colors.textHint,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});

  final GuessComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                result.guessedPlayer.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _MatchCell(
              match: result.position,
              label: result.guessedPlayer.position?.short ?? '—',
            ),
          ),
          Expanded(
            flex: 2,
            child: _DirectionalCell(
              result: result.shirtNumber,
              label: result.guessedPlayer.shirtNumber?.toString() ?? '—',
            ),
          ),
          Expanded(
            flex: 2,
            child: _MatchCell(
              match: result.academy,
              label: result.guessedPlayer.academyClub ?? '—',
            ),
          ),
          Expanded(
            flex: 2,
            child: _MatchCell(
              match: result.nationality,
              label: result.guessedPlayer.nationalityCode ?? '—',
            ),
          ),
          Expanded(
            flex: 2,
            child: _DirectionalCell(
              result: result.debutYear,
              label: result.guessedPlayer.goiasDebutYear?.toString() ?? '—',
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchCell extends StatelessWidget {
  const _MatchCell({required this.match, required this.label});

  final MatchResult match;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (match) {
      MatchResult.match => (
        colors.success.withValues(alpha: 0.16),
        colors.success,
      ),
      MatchResult.mismatch => (
        colors.border.withValues(alpha: 0.5),
        colors.textHint,
      ),
      MatchResult.unknown => (Colors.transparent, colors.textHint),
    };
    return _CellChip(
      background: background,
      foreground: foreground,
      label: label,
    );
  }
}

class _DirectionalCell extends StatelessWidget {
  const _DirectionalCell({required this.result, required this.label});

  final DirectionalResult result;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground, icon) = switch (result) {
      DirectionalResult.match => (
        colors.success.withValues(alpha: 0.16),
        colors.success,
        null,
      ),
      DirectionalResult.higher => (
        colors.border.withValues(alpha: 0.5),
        colors.textHint,
        Icons.arrow_upward_rounded,
      ),
      DirectionalResult.lower => (
        colors.border.withValues(alpha: 0.5),
        colors.textHint,
        Icons.arrow_downward_rounded,
      ),
      DirectionalResult.unknown => (Colors.transparent, colors.textHint, null),
    };
    return _CellChip(
      background: background,
      foreground: foreground,
      label: label,
      trailingIcon: icon,
    );
  }
}

class _CellChip extends StatelessWidget {
  const _CellChip({
    required this.background,
    required this.foreground,
    required this.label,
    this.trailingIcon,
  });

  final Color background;
  final Color foreground;
  final String label;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 2),
            Icon(trailingIcon, size: 12, color: foreground),
          ],
        ],
      ),
    );
  }
}
