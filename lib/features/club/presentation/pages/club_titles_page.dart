import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/data/club_titles_data.dart';
import 'package:goias_app/features/club/domain/entities/club_title_group.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class ClubTitlesPage extends StatelessWidget {
  const ClubTitlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
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
                  const PageTitle('TÍTULOS'),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${ClubTitlesData.totalTitles}',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: colors.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TÍTULOS PRINCIPAIS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  for (final group in ClubTitlesData.groups) ...[
                    _TitleGroupCard(group: group),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'CAMPANHAS HISTÓRICAS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grandes campanhas do Goiás que não resultaram em título.',
                    style: TextStyle(fontSize: 12.5, color: colors.textHint),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        for (
                          var i = 0;
                          i < ClubTitlesData.historicalCampaigns.length;
                          i++
                        ) ...[
                          if (i > 0) Divider(height: 1, color: colors.border),
                          _CampaignRow(
                            campaign: ClubTitlesData.historicalCampaigns[i],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleGroupCard extends StatelessWidget {
  const _TitleGroupCard({required this.group});

  final ClubTitleGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.competitionName.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${group.count}× CAMPEÃO',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            group.years.join(' • '),
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textHint,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignRow extends StatelessWidget {
  const _CampaignRow({required this.campaign});

  final ClubHistoricalCampaign campaign;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '${campaign.year}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textHint,
              ),
            ),
          ),
          Expanded(
            child: Text(
              campaign.title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
