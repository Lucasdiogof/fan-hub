import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';

const _yearsWidth = 92.0;
const _numberWidth = 50.0;

class CareerTable extends StatelessWidget {
  const CareerTable({required this.player, super.key});

  final CareerPlayer player;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _HeaderRow(),
          const SizedBox(height: AppSpacing.xs),
          for (var i = 0; i < player.clubCareer.length; i++)
            _EntryRow(
              entry: player.clubCareer[i],
              showDivider: i < player.clubCareer.length - 1,
            ),
          if (player.nationalTeams.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _SectionRow(label: context.l10n.careerNationalTeam),
            for (var i = 0; i < player.nationalTeams.length; i++)
              _EntryRow(
                entry: player.nationalTeams[i],
                showDivider: i < player.nationalTeams.length - 1,
              ),
          ],
          if (player.aggregateStats.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _AggregateSection(stats: player.aggregateStats),
          ],
        ],
      ),
    );
  }
}

/// Quando o jogador teve mais de uma passagem pelo mesmo clube e a fonte só
/// fecha o total somado (nunca por passagem individual), as linhas daquele
/// clube na tabela acima mostram "—" em jogos/gols — o número real mora só
/// aqui, explicitamente marcado como combinado, nunca atribuído a uma
/// passagem específica.
class _AggregateSection extends StatelessWidget {
  const _AggregateSection({required this.stats});

  final List<CareerAggregateStat> stats;

  String _n(int? value) => value?.toString() ?? '—';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.careerAggregateTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: colors.textHint,
            ),
          ),
          for (final stat in stats) ...[
            const SizedBox(height: 6),
            Text(
              l10n.careerAggregateLine(
                stat.club,
                stat.spells.join('; '),
                _n(stat.appearances),
                _n(stat.goals),
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            if (stat.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  stat.note!,
                  style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
      color: context.colors.textPrimary,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: _yearsWidth,
            child: Text(context.l10n.careerYears, style: style),
          ),
          Expanded(child: Text(context.l10n.careerClubs, style: style)),
          SizedBox(
            width: _numberWidth,
            child: Text(
              context.l10n.careerGames,
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: _numberWidth,
            child: Text(
              context.l10n.careerGoals,
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, required this.showDivider});

  final CareerEntry entry;
  final bool showDivider;

  String _n(int? value) => value?.toString() ?? '—';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final highlight = entry.isGoias;
    final textColor = highlight ? colors.primary : colors.textPrimary;
    final teamName = entry.loan
        ? context.l10n.careerOnLoan(entry.team)
        : entry.team;

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _yearsWidth,
            child: Text(
              entry.period,
              style: TextStyle(
                fontSize: 13.5,
                color: highlight ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              teamName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
                height: 1.15,
              ),
            ),
          ),
          SizedBox(
            width: _numberWidth,
            child: Text(
              _n(entry.appearances),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14.5, color: textColor),
            ),
          ),
          SizedBox(
            width: _numberWidth,
            child: Text(
              _n(entry.goals),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14.5, color: textColor),
            ),
          ),
        ],
      ),
    );

    if (highlight) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: colors.secondary,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
        ),
        child: row,
      );
    }

    return Column(
      children: [
        row,
        if (showDivider) Divider(height: 1, color: colors.border),
      ],
    );
  }
}
