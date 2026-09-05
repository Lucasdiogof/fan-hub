import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Selo compacto "isto é demonstração" — pra cards/carteirinha/detalhe,
/// nunca um disclaimer de parágrafo inteiro (ver [DemoDisclaimerBanner]
/// pra isso). Um selo só, discreto, sempre no mesmo estilo visual.
class DemoTag extends StatelessWidget {
  const DemoTag({required this.label, this.onDark = false, super.key});

  final String label;

  /// `true` quando o fundo atrás já é escuro/colorido (ex.: dentro da
  /// carteirinha de sócio com gradiente) — troca o tom pra continuar
  /// legível, sem virar um bloco sólido competindo com o resto do card.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = onDark ? Colors.white : colors.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.16)
            : colors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: 0.3) : colors.gold,
          width: 1,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: foreground,
        ),
      ),
    );
  }
}
