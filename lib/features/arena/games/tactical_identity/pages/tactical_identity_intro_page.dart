import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/tactical_identity/cubit/tactical_identity_cubit.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_header.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Introdução do jogo — mesma estrutura de cabeçalho dos outros jogos da
/// Arena (`ArenaGameHeader`), mas o cubit só é criado aqui (não precisa de
/// nenhum carregamento assíncrono antes, ver `arena_page.dart`: perguntas e
/// técnicos são dataset estático, não vêm do Supabase).
class TacticalIdentityIntroPage extends StatelessWidget {
  const TacticalIdentityIntroPage({super.key});

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
                    title: l10n.tacticalIdentityGameTitle.toUpperCase(),
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
                                Icons.hub_rounded,
                                size: 36,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              l10n.tacticalIntroTitle,
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
                              l10n.tacticalIntroDescription,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14.5,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.tacticalIntroMeta,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textHint,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.tacticalIntroNoRightWrong,
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
                    label: l10n.tacticalIntroStart,
                    showArrow: true,
                    onPressed: () => context.pushReplacement(
                      '/arena/tactical-identity/play',
                      extra: TacticalIdentityCubit(),
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
