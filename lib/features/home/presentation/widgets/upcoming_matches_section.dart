import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/home/presentation/widgets/upcoming_match_card.dart';
import 'package:goias_app/shared/widgets/section_header.dart';

class UpcomingMatchesSection extends StatelessWidget {
  const UpcomingMatchesSection({
    required this.matches,
    this.ticketsOpenMatchIds = const {},
    this.onSeeAll,
    this.onMatchTap,
    super.key,
  });

  final List<Match> matches;
  final Set<String> ticketsOpenMatchIds;
  final VoidCallback? onSeeAll;
  final ValueChanged<Match>? onMatchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'PRÓXIMOS JOGOS',
          actionLabel: 'Ver todos',
          onAction: onSeeAll,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final match = matches[index];
              return UpcomingMatchCard(
                match: match,
                ticketsAvailable: ticketsOpenMatchIds.contains(match.id),
                onTap: () => onMatchTap?.call(match),
              );
            },
          ),
        ),
      ],
    );
  }
}
