import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/data/club_history_data.dart';
import 'package:goias_app/features/club/domain/entities/club_history_section.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class ClubHistoryPage extends StatelessWidget {
  const ClubHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                      PageTitle(context.l10n.clubSectionHistory.toUpperCase()),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    itemCount: ClubHistoryData.sections.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.xl),
                    itemBuilder: (context, index) => _HistorySectionCard(
                      section: ClubHistoryData.sections[index],
                    ),
                  ),
                ),
              ],
            ),
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
