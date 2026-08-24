import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_state.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_share.dart';
import 'package:share_plus/share_plus.dart';

/// [onPrevious]/[onNext] são `null` quando não há partida anterior/seguinte
/// (primeira/última do banco) — o botão correspondente some, em vez de
/// aparecer desabilitado.
Future<void> showLineupResultDialog(
  BuildContext context,
  LineupState state, {
  VoidCallback? onPrevious,
  VoidCallback? onNext,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _LineupResultDialog(state: state, onPrevious: onPrevious, onNext: onNext),
  );
}

class _LineupResultDialog extends StatelessWidget {
  const _LineupResultDialog({required this.state, this.onPrevious, this.onNext});

  final LineupState state;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elapsed = state.elapsed ?? Duration.zero;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ESCALAÇÃO COMPLETA',
              style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${state.solvedCount}/${state.totalPlayers}',
              style: TextStyle(color: colors.textPrimary, fontSize: 40, fontWeight: FontWeight.w900),
            ),
            Text(
              'DESCOBERTOS',
              style: TextStyle(color: colors.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(label: 'TENTATIVAS', value: '${state.totalAttempts}'),
                _Stat(label: 'TEMPO', value: '$minutes:$seconds'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: IconButton.filledTonal(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: buildLineupShareText(state)));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resultado copiado.')));
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copiar resultado',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: IconButton.filledTonal(
                    onPressed: () => SharePlus.instance.share(ShareParams(text: buildLineupShareText(state))),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    tooltip: 'Compartilhar resultado',
                  ),
                ),
              ],
            ),
            if (onNext != null || onPrevious != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(height: 1, color: colors.border),
              const SizedBox(height: AppSpacing.lg),
              if (onNext != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNext!();
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('PRÓXIMO JOGO'),
                  ),
                ),
              if (onNext != null && onPrevious != null) const SizedBox(height: AppSpacing.sm),
              if (onPrevious != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onPrevious!();
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('ANTERIOR'),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('FECHAR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(
          label,
          style: TextStyle(color: colors.textHint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6),
        ),
      ],
    );
  }
}
