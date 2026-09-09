import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/shared/widgets/jersey_shirt.dart';

/// Uma camisa no campo — número, estrutura da resposta ("...... ....."),
/// e o nome revelado depois de resolvida. O estado (resolvido/falhou/em
/// aberto) nunca depende só de cor: junto da cor sempre vem um selo com
/// ícone, pra continuar legível pra quem não distingue verde de cinza.
class LineupShirtButton extends StatelessWidget {
  const LineupShirtButton({
    required this.player,
    required this.playerState,
    required this.onTap,
    this.shirtSize = 46,
    super.key,
  });

  final LineupPlayer player;
  final LineupPlayerState playerState;
  final VoidCallback onTap;

  /// Lado da camisa em pixels — ajustável porque a linha mais cheia de
  /// uma formação (até 5 titulares lado a lado) precisa de camisas
  /// menores que uma linha de 1 (goleiro) pra nunca encostar na vizinha.
  final double shirtSize;

  @override
  Widget build(BuildContext context) {
    final solved = playerState.solved;
    final failed = playerState.failed;

    final shirtLabel = player.shirtNumber != null
        ? context.l10n.lineupShirtLabel(player.shirtNumber!)
        : context.l10n.lineupNoNumber;

    return Semantics(
      button: true,
      label: solved
          ? context.l10n.lineupA11yRevealed(shirtLabel, player.displayName)
          : failed
          ? context.l10n.lineupNotDiscovered(shirtLabel)
          : context.l10n.lineupA11yPending(shirtLabel, player.position),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: shirtSize,
              height: shirtSize,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  JerseyShirt(
                    size: shirtSize,
                    number: player.shirtNumber,
                    fillColor: failed
                        ? ArenaColors.opponentKeeper.withValues(alpha: 0.55)
                        : context.colors.primary,
                  ),
                  if (solved || failed)
                    Positioned(
                      top: -shirtSize * 0.09,
                      right: -shirtSize * 0.09,
                      child: Container(
                        width: shirtSize * 0.37,
                        height: shirtSize * 0.37,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Nunca vermelho — identidade do app não usa essa
                          // cor em nenhum componente. Erro usa âmbar/dourado.
                          color: solved
                              ? const Color(0xFF278A52)
                              : const Color(0xFFC99A36),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          solved ? Icons.check_rounded : Icons.close_rounded,
                          size: shirtSize * 0.22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _AnswerStructure(player: player, revealed: solved || failed),
          ],
        ),
      ),
    );
  }
}

class _AnswerStructure extends StatelessWidget {
  const _AnswerStructure({required this.player, required this.revealed});

  final LineupPlayer player;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    if (revealed) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          player.displayName.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            height: 1.1,
          ),
        ),
      );
    }
    final words = player.puzzleAnswer.split(' ');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 5,
      runSpacing: 3,
      children: [
        for (final word in words)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < word.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Container(
                  width: 4.5,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 1,
                        offset: Offset(0, 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
