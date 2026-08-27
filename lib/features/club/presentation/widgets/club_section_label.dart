import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Rótulo de seção do Hino & Músicas ("HINO", "MÚSICAS ESMERALDINAS",
/// "LETRA") — mesmo estilo nos três, pra ficarem consistentes entre a
/// listagem e a página da letra.
class ClubSectionLabel extends StatelessWidget {
  const ClubSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: context.colors.textSecondary,
      ),
    );
  }
}
