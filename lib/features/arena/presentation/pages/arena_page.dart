import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/data/arena_catalog.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_card.dart';

class ArenaPage extends StatelessWidget {
  const ArenaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const games = ArenaCatalog.games;
    final featured = games.firstWhere((game) => game.featured);
    final others = games.where((game) => !game.featured).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
              children: [
                Text(
                  'ARENA ESMERALDINA',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.3, color: colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minigames rápidos para o torcedor.',
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionLabel('JOGUE AGORA'),
                const SizedBox(height: AppSpacing.md),
                ArenaFeaturedCard(game: featured, onTap: () => context.push(featured.route)),
                const SizedBox(height: AppSpacing.xl),
                const _SectionLabel('MAIS DESAFIOS'),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.1,
                  children: [
                    for (final game in others) ArenaCompactCard(game: game, onTap: () => context.push(game.route)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: context.colors.textHint),
    );
  }
}
