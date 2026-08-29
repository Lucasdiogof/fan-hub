import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

class NewsSkeletonRow extends StatelessWidget {
  const NewsSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shimmer = colors.border;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Block(
            width: 84,
            height: 84,
            color: shimmer,
            radius: AppRadius.cardSmall,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Block(width: 80, height: 10, color: shimmer),
                const SizedBox(height: 10),
                _Block(width: double.infinity, height: 14, color: shimmer),
                const SizedBox(height: 6),
                _Block(width: 160, height: 14, color: shimmer),
              ],
            ),
          ),
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
