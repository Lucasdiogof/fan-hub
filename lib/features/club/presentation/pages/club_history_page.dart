import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/data/club_history_data.dart';
import 'package:goias_app/features/club/domain/entities/club_history_section.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';

class ClubHistoryPage extends StatelessWidget {
  const ClubHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = context.l10n.clubSectionHistory.toUpperCase();
    return Scaffold(
      backgroundColor: colors.background,
      body: DetailPageHeader(
        title: title,
        heroTitle: Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < ClubHistoryData.sections.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.xl),
                _HistorySectionCard(section: ClubHistoryData.sections[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySectionCard extends StatelessWidget {
  const _HistorySectionCard({required this.section});

  final ClubHistorySection section;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.period,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          section.title,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < section.paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          Text(
            section.paragraphs[i],
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
