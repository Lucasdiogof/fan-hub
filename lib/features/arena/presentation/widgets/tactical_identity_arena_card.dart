import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_archetype_descriptions.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Card de entrada da "Identidade Futebolística" na Arena — próprio, não o
/// `ArenaChallengeCard` genérico dos outros 4 jogos (esses têm coleção/
/// progresso; este jogo é um perfil único, sem "X/Y completos"). Mesma
/// linguagem visual da Arena (ícone 52×52 sobre `colors.surface`, título,
/// descrição, CTA + chevron — ver `ArenaHighlightCard`), mas com dois
/// estados de conteúdo: nunca jogou (CTA único) ou já tem resultado (perfil
/// + "Ver resultado" + "Refazer" separados).
class TacticalIdentityArenaCard extends StatelessWidget {
  const TacticalIdentityArenaCard({
    required this.result,
    required this.onStart,
    required this.onViewResult,
    required this.onRedo,
    super.key,
  });

  final TacticalIdentityResult? result;
  final VoidCallback onStart;
  final VoidCallback onViewResult;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final completed = result;

    return Material(
      color: colors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        // Desafio já completado ganha uma borda de destaque — mesma cor
        // do CTA/ícone, pra bater o olho na Arena que este perfil já foi
        // descoberto (nunca jogado fica sem borda nenhuma, igual antes).
        side: completed != null
            ? BorderSide(color: colors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: completed == null ? onStart : onViewResult,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    ),
                    child: Icon(
                      Icons.hub_rounded,
                      color: colors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tacticalIdentityGameTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          completed == null
                              ? l10n.tacticalIdentityCardSubtitleNew
                              : l10n.tacticalIdentityYourProfile(
                                  completed.archetype.displayName,
                                ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: completed == null ? 13 : 13.5,
                            height: 1.35,
                            fontWeight: completed == null
                                ? FontWeight.w400
                                : FontWeight.w700,
                            color: completed == null
                                ? colors.textSecondary
                                : colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    completed == null
                        ? l10n.tacticalIdentityCardCtaStart
                        : l10n.tacticalIdentityCardCtaViewResult,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  if (completed != null) ...[
                    const Spacer(),
                    InkWell(
                      onTap: onRedo,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          l10n.tacticalIdentityCardCtaRedo,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textHint,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
