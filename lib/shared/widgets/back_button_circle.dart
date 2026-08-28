import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Botão de voltar redondo padrão do app — usado em toda página empilhada
/// via `context.push` (Perfil, Parceiros, Sócio).
class BackButtonCircle extends StatelessWidget {
  const BackButtonCircle({
    required this.onTap,
    this.size = 38,
    this.iconSize = 18,
    super.key,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: iconSize,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
