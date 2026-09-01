import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/data/club_titles_data.dart';
import 'package:goias_app/features/club/domain/entities/club_title_group.dart';
import 'package:goias_app/features/club/presentation/widgets/title_image_carousel.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

class ClubTitlesPage extends StatelessWidget {
  const ClubTitlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
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
                      PageTitle(context.l10n.clubSectionTitles.toUpperCase()),
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
                              context.l10n.clubMainTitles,
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
                        _TitleGroupSection(group: group),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        context.l10n.clubHistoricCampaigns,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      for (
                        var i = 0;
                        i < ClubTitlesData.historicalCampaigns.length;
                        i++
                      ) ...[
                        _CampaignSection(
                          campaign: ClubTitlesData.historicalCampaigns[i],
                        ),
                        if (i < ClubTitlesData.historicalCampaigns.length - 1)
                          const SizedBox(height: AppSpacing.md),
                      ],
                    ],
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

/// Card principal do título (nome + quantidade + anos) e, logo abaixo, o
/// carrossel de momentos históricos daquela competição — só aparece quando
/// já existe pelo menos uma foto real cadastrada (ver `ClubTitleGroup.images`).
class _TitleGroupSection extends StatelessWidget {
  const _TitleGroupSection({required this.group});

  final ClubTitleGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitleGroupCard(group: group),
        if (group.images.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          TitleImageCarousel(
            images: group.images,
            title: group.competitionName,
          ),
        ],
      ],
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
            context.l10n.clubTimesChampion(group.count),
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

/// Mesmo tratamento visual do título (card + carrossel abaixo), mas pra uma
/// campanha histórica — substitui a antiga lista compacta com divisores:
/// cada campanha ganhou peso próprio, coerente com o pedido de a seção
/// parecer "memória histórica", não uma listagem burocrática.
class _CampaignSection extends StatelessWidget {
  const _CampaignSection({required this.campaign});

  final ClubHistoricalCampaign campaign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CampaignCard(campaign: campaign),
        if (campaign.images.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          TitleImageCarousel(images: campaign.images, title: campaign.title),
        ],
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign});

  final ClubHistoricalCampaign campaign;

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
            '${campaign.year}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            campaign.title,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
