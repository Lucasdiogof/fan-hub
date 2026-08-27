import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Botão de voltar redondo padrão do app — usado em toda página empilhada
/// via `context.push` (Perfil, Parceiros, Sócio).
class BackButtonCircle extends StatelessWidget {
  const BackButtonCircle({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
