import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

/// Destaque da Arena Esmeraldina na Home — é a porta de entrada pro hub da
/// Arena inteiro, nunca propaganda de um minigame específico (já foi
/// "Quiz do Verdão", já foi a Escalação da Torcida: a Arena tem várias
/// formas de participação, então o card não escolhe uma pra vender).
/// Copy fixa de propósito — não há mais lógica de qual texto mostrar, só
/// de navegar sempre pro mesmo lugar (`/arena`).
class ArenaSpotlightCard extends StatelessWidget {
  const ArenaSpotlightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/arena'),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ArenaColors.arenaTop, ArenaColors.arenaBottom],
            ),
            border: Border.all(
              color: ArenaColors.pitch.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.14),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Marca d'água — centralizada verticalmente, cortada pela
              // borda direita, em tom verde (duotone já gravado no asset,
              // não a foto colorida) e opacidade baixa: profundidade sem
              // competir com o texto.
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(1.3, 0),
                  child: Opacity(
                    opacity: 0.6,
                    child: Image.asset(
                      AppAssets.arenaStadiumPhoto,
                      width: 170,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 16,
                          color: colors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.arenaSpotlightEyebrow.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: colors.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.arenaSpotlightHeadline,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.arenaSpotlightSubtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.arenaSpotlightCta,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
