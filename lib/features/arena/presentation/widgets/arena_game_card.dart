import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/domain/arena_game.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

class ArenaFeaturedCard extends StatelessWidget {
  const ArenaFeaturedCard({required this.game, required this.onTap, super.key});

  final ArenaGame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ArenaColors.goiasOutfield, ArenaColors.arenaBottom],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    ),
                    child: Icon(game.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      game.title.toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                game.tagline,
                style: TextStyle(fontSize: 13.5, height: 1.35, color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('JOGAR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ArenaColors.goiasOutfield)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: ArenaColors.goiasOutfield),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArenaCompactCard extends StatelessWidget {
  const ArenaCompactCard({required this.game, required this.onTap, super.key});

  final ArenaGame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: colors.secondary, borderRadius: BorderRadius.circular(AppRadius.cardSmall)),
                child: Icon(game.icon, color: colors.primary, size: 22),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                game.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary, height: 1.15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
