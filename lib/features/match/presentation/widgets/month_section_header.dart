import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

class MonthSectionHeader extends StatelessWidget {
  const MonthSectionHeader({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: colors.textSecondary,
      ),
    );
  }
}
