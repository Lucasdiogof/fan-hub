import 'package:flutter/material.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

/// Uma camisa no campo — número, estrutura da resposta ("...... ....."),
/// e o nome revelado depois de resolvida. O estado (resolvido/falhou/em
/// aberto) nunca depende só de cor: junto da cor sempre vem um selo com
/// ícone, pra continuar legível pra quem não distingue verde de cinza.
class LineupShirtButton extends StatelessWidget {
  const LineupShirtButton({
    required this.player,
    required this.playerState,
    required this.onTap,
    super.key,
  });

  final LineupPlayer player;
  final LineupPlayerState playerState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final solved = playerState.solved;
    final failed = playerState.failed;

    final shirtLabel = player.shirtNumber != null
        ? 'Camisa ${player.shirtNumber}'
        : 'Jogador sem número confirmado';

    return Semantics(
      button: true,
      label: solved
          ? '$shirtLabel, ${player.displayName}, descoberto'
          : failed
          ? '$shirtLabel, não descoberto'
          : '$shirtLabel, ${player.position}, ainda não descoberto',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(40, 40),
                    painter: _JerseyPainter(
                      color: failed
                          ? ArenaColors.opponentKeeper.withValues(alpha: 0.55)
                          : ArenaColors.goiasOutfield,
                      number: player.shirtNumber,
                    ),
                  ),
                  if (solved || failed)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: solved
                              ? const Color(0xFF278A52)
                              : const Color(0xFFD64545),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(
                          solved ? Icons.check_rounded : Icons.close_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
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
      return Text(
        player.displayName.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    final words = player.puzzleAnswer.split(' ');
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 3,
      children: [
        for (final word in words)
          Text(
            '·' * word.length,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
      ],
    );
  }
}

/// Silhueta simples de camisa — corpo trapezoidal com decote e mangas
/// curtas, só o suficiente pra ler como "camisa de futebol" no tamanho
/// pequeno em que aparece (11 delas juntas no campo).
class _JerseyPainter extends CustomPainter {
  const _JerseyPainter({required this.color, required this.number});

  final Color color;
  final int? number;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Path()
      ..moveTo(w * 0.32, 0)
      ..lineTo(w * 0.68, 0)
      ..lineTo(w * 0.68, h * 0.12)
      ..lineTo(w * 0.86, h * 0.22)
      ..lineTo(w * 0.78, h * 0.42)
      ..lineTo(w * 0.68, h * 0.34)
      ..lineTo(w * 0.68, h)
      ..lineTo(w * 0.32, h)
      ..lineTo(w * 0.32, h * 0.34)
      ..lineTo(w * 0.22, h * 0.42)
      ..lineTo(w * 0.14, h * 0.22)
      ..lineTo(w * 0.32, h * 0.12)
      ..close();

    canvas.drawShadow(body, Colors.black, 1.5, false);
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Sem número confirmado pela fonte: a camisa fica lisa, nunca com um
    // "?" no lugar do número (pedido explícito — não inventar o dado).
    if (number == null) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((w - textPainter.width) / 2, h * 0.42 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _JerseyPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.number != number;
}
