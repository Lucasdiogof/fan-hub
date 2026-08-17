import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/match_ordering.dart';
import 'package:goias_app/features/match/presentation/widgets/match_list_item.dart';
import 'package:goias_app/features/match/presentation/widgets/month_section_header.dart';

/// Agrupa por mês derivado de `kickoff` — nunca "AGOSTO"/"SETEMBRO" fixos.
class MatchesByMonthSection extends StatelessWidget {
  const MatchesByMonthSection({required this.matches, this.onMatchTap, super.key});

  final List<Match> matches;
  final ValueChanged<Match>? onMatchTap;

  @override
  Widget build(BuildContext context) {
    final groups = MatchOrdering.groupByMonth(matches);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          MonthSectionHeader(label: entry.key),
          const SizedBox(height: AppSpacing.md),
          for (final match in entry.value) ...[
            MatchListItem(match: match, onTap: () => onMatchTap?.call(match)),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
