import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Card compartilhado pelos dois "Destaques da Torcida" (Escalação e
/// Ranking) — mesma estrutura, tamanho e linguagem visual pros dois, pra
/// nunca mais um parecer um hero banner e o outro um aviso secundário (ver
/// `arena_page.dart`). Semi-horizontal: [leading] à esquerda, título +
/// descrição à direita, [extra] opcional embaixo (ex.: pill de posição no
/// ranking) e uma linha final de CTA + chevron. O card inteiro é clicável.
class ArenaHighlightCard extends StatelessWidget {
  const ArenaHighlightCard({
    required this.leading,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.onTap,
    this.topBadge,
    this.extra,
    super.key,
  });

  final Widget leading;
  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback onTap;
  final String? topBadge;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.secondary,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
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
                  leading,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (topBadge != null) ...[
                          _TopBadge(label: topBadge!),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          title,
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
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (extra != null) ...[
                const SizedBox(height: AppSpacing.sm),
                extra!,
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    ctaLabel,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Container 52x52 branco pro ícone/ilustração de cada card — mesma
/// dimensão nos dois destaques, mesmo o conteúdo interno sendo diferente
/// (imagem numa, `Icon` na outra).
class ArenaHighlightLeading extends StatelessWidget {
  const ArenaHighlightLeading({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: child,
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      label,
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: colors.primary,
      ),
    );
  }
}

/// Pill "#N SUA POSIÇÃO" (já formatada e maiúscula pelo chamador) — o
/// [extra] do card de Ranking quando o usuário já pontuou.
class ArenaHighlightPositionPill extends StatelessWidget {
  const ArenaHighlightPositionPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: colors.primary,
        ),
      ),
    );
  }
}
