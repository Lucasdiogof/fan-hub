import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';

/// Estatísticas comparativas (posse de bola, chutes, disputas...) — cada
/// linha só aparece quando a fonte já tem os dois lados (nunca mostra "0 x
/// 0" pra uma estatística que a fonte simplesmente ainda não preencheu,
/// comum no início do jogo).
class MatchStatsSection extends StatelessWidget {
  const MatchStatsSection({required this.stats, super.key});

  final List<MatchStat> stats;

  @override
  Widget build(BuildContext context) {
    final visible = stats.where((s) => s.hasValues).toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          context.l10n.matchStatsTitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.lg),
                _StatRow(stat: visible[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});

  final MatchStat stat;

  String _format(num value) => stat.unit == MatchStatUnit.percent
      ? '${value.round()}%'
      : value.round().toString();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final home = stat.home!.toDouble();
    final away = stat.away!.toDouble();
    final total = home + away;
    // Empate/zero-a-zero na estatística: divide a barra ao meio em vez de
    // deixar os dois lados com largura zero.
    final homeFraction = total <= 0 ? 0.5 : home / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _format(stat.home!),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            Text(
              stat.title,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            Text(
              _format(stat.away!),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: (homeFraction * 1000).round().clamp(1, 999),
                  child: ColoredBox(color: colors.primary),
                ),
                Expanded(
                  flex: ((1 - homeFraction) * 1000).round().clamp(1, 999),
                  child: ColoredBox(color: colors.secondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
