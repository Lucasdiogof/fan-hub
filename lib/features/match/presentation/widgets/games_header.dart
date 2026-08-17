import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

class GamesHeader extends StatelessWidget {
  const GamesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      'JOGOS',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        color: colors.textPrimary,
      ),
    );
  }
}
