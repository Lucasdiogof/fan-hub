import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Título de seção da Arena ("Destaques da Torcida", "Jogos da Arena") —
/// com [subtitle] opcional, só usado quando não deixa a tela poluída (ver
/// `arena_page.dart`).
class ArenaSectionHeader extends StatelessWidget {
  const ArenaSectionHeader(this.title, {this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}
