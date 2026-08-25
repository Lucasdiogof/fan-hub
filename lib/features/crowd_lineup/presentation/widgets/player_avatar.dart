import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/crowd_lineup/domain/squad_player.dart';

/// Avatar do atleta — foto quando houver, com fallback discreto pro número
/// da camisa (nunca quebra a escalação se a imagem falhar).
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({required this.player, required this.size, super.key});

  final SquadPlayer? player;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final p = player;

    if (p == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.primary.withValues(alpha: 0.10),
          border: Border.all(
            color: colors.onPrimary.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          size: size * 0.5,
          color: colors.onPrimary.withValues(alpha: 0.85),
        ),
      );
    }

    final fallback = _NumberCircle(number: p.shirtNumber, size: size);
    final url = p.imageUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}

class _NumberCircle extends StatelessWidget {
  const _NumberCircle({required this.number, required this.size});

  final int? number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary,
        border: Border.all(
          color: colors.onPrimary.withValues(alpha: 0.85),
          width: 1.5,
        ),
      ),
      child: Text(
        number?.toString() ?? '–',
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
