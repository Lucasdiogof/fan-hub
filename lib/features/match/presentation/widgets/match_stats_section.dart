import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/presentation/widgets/match_tab_empty_state.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/team_name.dart';

/// Aba ESTATÍSTICAS: comparativo entre os dois times, com barra proporcional.
/// Só mostra o que a fonte trouxe — cada linha exige os dois lados (nunca um
/// "0" no lugar de um dado que não veio). As quatro métricas principais
/// (posse, finalizações, finalizações no gol, escanteios) vêm primeiro,
/// quando existirem; as demais seguem na ordem da fonte.
class MatchStatsSection extends StatelessWidget {
  const MatchStatsSection({
    required this.match,
    required this.stats,
    super.key,
  });

  final Match match;
  final List<MatchStat> stats;

  /// Ordem de prioridade; a fonte só entrega o título em português, sem
  /// chave estável, então o reconhecimento é pelo texto exato dela.
  static const _priority = [
    _StatKind.possession,
    _StatKind.shots,
    _StatKind.shotsOnTarget,
    _StatKind.corners,
  ];

  static _StatKind? _kindOf(String title) {
    switch (title.trim().toLowerCase()) {
      case 'posse de bola':
        return _StatKind.possession;
      case 'total de chutes':
      case 'finalizações':
      case 'finalizacoes':
        return _StatKind.shots;
      case 'chutes ao gol':
      case 'finalizações no gol':
      case 'finalizacoes no gol':
        return _StatKind.shotsOnTarget;
      case 'escanteios':
        return _StatKind.corners;
      case 'disputas ganhas':
        return _StatKind.duelsWon;
      default:
        return null;
    }
  }

  static String labelOf(AppLocalizations l10n, MatchStat stat) =>
      switch (_kindOf(stat.title)) {
        _StatKind.possession => l10n.matchStatPossession,
        _StatKind.shots => l10n.matchStatShots,
        _StatKind.shotsOnTarget => l10n.matchStatShotsOnTarget,
        _StatKind.corners => l10n.matchStatCorners,
        _StatKind.duelsWon => l10n.matchStatDuelsWon,
        null => stat.title,
      };

  List<MatchStat> get _ordered {
    final visible = stats.where((s) => s.hasValues).toList();
    int rank(MatchStat s) {
      final kind = _kindOf(s.title);
      final index = kind == null ? -1 : _priority.indexOf(kind);
      return index < 0 ? _priority.length : index;
    }

    // `sort` do Dart não é estável: desempata pela posição original.
    final indexed = [for (var i = 0; i < visible.length; i++) (i, visible[i])]
      ..sort((a, b) {
        final byRank = rank(a.$2).compareTo(rank(b.$2));
        return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
      });
    return [for (final entry in indexed) entry.$2];
  }

  @override
  Widget build(BuildContext context) {
    final ordered = _ordered;
    if (ordered.isEmpty) {
      return MatchTabEmptyState(
        icon: Icons.bar_chart_rounded,
        message: context.l10n.matchStatsEmpty,
      );
    }
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shortTeamName(match.homeTeam.name),
                  style: _teamStyle(colors, colors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  shortTeamName(match.awayTeam.name),
                  textAlign: TextAlign.right,
                  style: _teamStyle(colors, colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < ordered.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            _StatRow(stat: ordered[i]),
          ],
        ],
      ),
    );
  }

  static TextStyle _teamStyle(AppColors colors, Color color) =>
      TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color);
}

enum _StatKind { possession, shots, shotsOnTarget, corners, duelsWon }

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat});

  final MatchStat stat;

  String _format(num value) => stat.unit == MatchStatUnit.percent
      ? '${value.round()}%'
      : value.round().toString();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = MatchStatsSection.labelOf(context.l10n, stat);
    final home = stat.home!.toDouble();
    final away = stat.away!.toDouble();
    final total = home + away;
    // Zero a zero REAL (a fonte devolveu 0 dos dois lados): só a trilha, sem
    // barra preenchida — nada de dividir ao meio como se houvesse dado.
    final homeFlex = total <= 0 ? 0 : (home / total * 1000).round();
    final awayFlex = total <= 0 ? 0 : 1000 - homeFlex;

    return Semantics(
      label: '$label: ${_format(stat.home!)} / ${_format(stat.away!)}',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _format(stat.home!),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Flexible(
                flex: 3,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _format(stat.away!),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: ColoredBox(
                color: colors.border.withValues(alpha: 0.6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (homeFlex > 0)
                      Expanded(
                        flex: homeFlex,
                        child: ColoredBox(color: colors.primary),
                      ),
                    if (homeFlex > 0 && awayFlex > 0) const SizedBox(width: 2),
                    if (awayFlex > 0)
                      Expanded(
                        flex: awayFlex,
                        child: ColoredBox(
                          color: colors.textSecondary.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
