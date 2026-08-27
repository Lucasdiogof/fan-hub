import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Título de topo de aba — usado no lugar de um `Text` solto genérico.
/// A barrinha verde ao lado é o mesmo tipo de acento usado no restante do
/// app (ex.: divisor do wordmark da Home antes da simplificação).
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
