import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/social/domain/entities/social_post.dart';

class SocialPlatformFilter extends StatelessWidget {
  const SocialPlatformFilter({required this.selected, required this.onChanged, super.key});

  final SocialPlatform? selected;
  final ValueChanged<SocialPlatform?> onChanged;

  static const _filters = [
    (label: 'TODOS', platform: null),
    (label: 'YOUTUBE', platform: SocialPlatform.youtube),
    (label: 'X', platform: SocialPlatform.x),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (final filter in _filters)
            Expanded(
              child: _FilterChip(
                label: filter.label,
                selected: selected == filter.platform,
                onTap: () => onChanged(filter.platform),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button - 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button - 4),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.4,
            color: selected ? colors.onPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
