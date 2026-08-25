import 'package:flutter/material.dart';
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
            const _SectionRow(label: 'Seleção nacional'),
            for (var i = 0; i < player.nationalTeams.length; i++)
              _EntryRow(
                entry: player.nationalTeams[i],
                showDivider: i < player.nationalTeams.length - 1,
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
            child: Text('Anos', style: style),
          ),
          Expanded(child: Text('Clubes', style: style)),
          SizedBox(
            width: _numberWidth,
            child: Text('Jogos', style: style, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: _numberWidth,
            child: Text('Gols', style: style, textAlign: TextAlign.right),
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
    final teamName = entry.loan ? '${entry.team} (emp.)' : entry.team;

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
