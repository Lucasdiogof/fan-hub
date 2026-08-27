import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

class SocialSkeletonCard extends StatelessWidget {
  const SocialSkeletonCard({this.withImage = true, super.key});

  final bool withImage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shimmer = colors.border;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Block(width: 12, height: 12, color: shimmer),
              const SizedBox(width: 6),
              _Block(width: 60, height: 10, color: shimmer),
              const Spacer(),
              _Block(width: 30, height: 10, color: shimmer),
            ],
          ),
          if (withImage) ...[
            const SizedBox(height: AppSpacing.md),
            _Block(
              width: double.infinity,
              height: 170,
              color: shimmer,
              radius: AppRadius.cardSmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _Block(width: double.infinity, height: 14, color: shimmer),
          const SizedBox(height: AppSpacing.sm),
          _Block(width: 200, height: 14, color: shimmer),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 6,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
