import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/player_identity/cubit/player_identity_cubit.dart';
import 'package:goias_app/features/arena/games/player_identity/presentation/player_identity_copy.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_header.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Introdução do jogo — mesma estrutura de `TacticalIdentityIntroPage`. O
/// cubit só é criado aqui (perguntas e jogadores são dataset estático, não
/// vêm do Supabase, ver `arena_page.dart`).
class PlayerIdentityIntroPage extends StatelessWidget {
  const PlayerIdentityIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.form.maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ArenaGameHeader(
                    title: context.playerIdentityGameTitle.toUpperCase(),
                    onBack: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colors.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.sports_soccer_rounded,
                                size: 36,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              context.playerIntroTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              context.playerIntroDescription,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14.5,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.playerIntroMeta,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textHint,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.playerIntroNoRightWrong,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textHint,
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AppPrimaryButton(
                    label: l10n.playerIntroStart,
                    showArrow: true,
                    onPressed: () => context.pushReplacement(
                      '/arena/player-identity/play',
                      extra: PlayerIdentityCubit(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
