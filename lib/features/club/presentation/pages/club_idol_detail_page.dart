import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';
import 'package:goias_app/features/club/presentation/widgets/club_idol_avatar.dart';
import 'package:goias_app/features/club/presentation/widgets/club_section_label.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';
import 'package:intl/intl.dart';

/// Detalhe de UM ídolo — mesmo cabeçalho de tela interna da letra do hino
/// (`DetailPageHeader`). Cada bloco só aparece quando o dado existe: sem
/// números não há placar de jogos/gols, sem títulos não há a seção — nunca
/// um "—" ou "0" no lugar de um dado que a pesquisa não confirmou.
class ClubIdolDetailPage extends StatelessWidget {
  const ClubIdolDetailPage({required this.idol, super.key});

  final ClubIdol idol;

  String? get _subtitle {
    final parts = [
      idol.position,
      idol.period,
    ].where((part) => part != null && part.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final subtitle = _subtitle;
    final story = idol.story ?? idol.description;
    final hasStats = idol.matches != null || idol.goals != null;

    return Scaffold(
      backgroundColor: colors.background,
      body: DetailPageHeader(
        maxWidth: ContentWidth.detail,
        title: idol.name,
        heroTitle: Row(
          children: [
            ClubIdolAvatar(
              name: idol.name,
              photoAsset: idol.photoAsset,
              size: 88,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idol.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                      height: 1.15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                  if (idol.fullName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      idol.fullName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasStats) ...[
                _Stats(idol: idol),
                const SizedBox(height: AppSpacing.xxl),
              ],
              if (story.trim().isNotEmpty) ...[
                ClubSectionLabel(l10n.clubIdolStory),
                const SizedBox(height: AppSpacing.md),
                Text(
                  story,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
              if (idol.titles.isNotEmpty) ...[
                ClubSectionLabel(l10n.clubIdolTitles),
                const SizedBox(height: AppSpacing.md),
                _BulletList(
                  items: idol.titles,
                  icon: Icons.emoji_events_outlined,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
              if (idol.highlights.isNotEmpty) ...[
                ClubSectionLabel(l10n.clubIdolHighlights),
                const SizedBox(height: AppSpacing.md),
                _BulletList(items: idol.highlights, icon: Icons.star_outline),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.idol});

  final ClubIdol idol;

  String? _asOf(BuildContext context) {
    final raw = idol.statsAsOf;
    if (raw == null) return null;
    final date = DateTime.tryParse(raw);
    if (date == null) return null;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return context.l10n.clubIdolStatsAsOf(DateFormat.yMd(locale).format(date));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final notes = [idol.statsScope, _asOf(context)].whereType<String>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (idol.matches != null)
              Expanded(
                child: _StatBox(
                  value: idol.matches!,
                  label: l10n.clubIdolMatches,
                ),
              ),
            if (idol.matches != null && idol.goals != null)
              const SizedBox(width: AppSpacing.md),
            if (idol.goals != null)
              Expanded(
                child: _StatBox(value: idol.goals!, label: l10n.clubIdolGoals),
              ),
          ],
        ),
        for (final note in notes) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            note,
            style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colors.primary,
              height: 1.1,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.icon});

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 18, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  items[i],
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
