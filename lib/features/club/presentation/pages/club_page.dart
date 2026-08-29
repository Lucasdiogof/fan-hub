import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/data/club_titles_data.dart';
import 'package:goias_app/features/club/presentation/widgets/club_header.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_cubit.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

class ClubPage extends StatelessWidget {
  const ClubPage({super.key});

  /// Mesmo padrão do Perfil: carrega o Elenco ANTES de navegar, pra tela já
  /// abrir pronta em vez de aparecer vazia esperando a busca.
  Future<void> _openSquad(BuildContext context) async {
    final cubit = sl<SquadCubit>();
    await GlobalLoading.run(context, cubit.load);
    if (!context.mounted) return;
    unawaited(context.push('/squad', extra: cubit));
  }

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
                  child: BackButtonCircle(onTap: () => context.pop()),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      const ClubHeader(),
                      const SizedBox(height: AppSpacing.xxl),
                      _ClubBigCard(
                        icon: Icons.auto_stories_outlined,
                        title: context.l10n.clubSectionHistory,
                        subtitle: context.l10n.clubHistorySubtitle,
                        onTap: () => context.push('/clube/historia'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ClubBigCard(
                        icon: Icons.emoji_events_outlined,
                        title: context.l10n.clubSectionTitles,
                        subtitle: context.l10n.clubTitlesSubtitle(
                          ClubTitlesData.totalTitles,
                        ),
                        onTap: () => context.push('/clube/titulos'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ClubBigCard(
                        icon: Icons.groups_outlined,
                        title: context.l10n.clubSectionBoard,
                        subtitle: context.l10n.clubBoardSubtitle,
                        onTap: () => context.push('/clube/diretoria'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ClubBigCard(
                        icon: Icons.shield_outlined,
                        title: context.l10n.clubSectionSquad,
                        subtitle: context.l10n.clubSquadSubtitle,
                        onTap: () => _openSquad(context),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ClubBigCard(
                        icon: Icons.music_note_outlined,
                        title: context.l10n.clubSectionSongs,
                        subtitle: context.l10n.clubSongsSubtitle,
                        onTap: () => context.push('/clube/hino'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ClubBigCard(
                        icon: Icons.fact_check_outlined,
                        title: context.l10n.clubSectionTransparency,
                        subtitle: context.l10n.clubTransparencySubtitle,
                        onTap: () => context.push('/clube/transparencia'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ClubBigCard(
                        icon: Icons.handshake_outlined,
                        title: context.l10n.clubSectionPartners,
                        subtitle: context.l10n.clubPartnersSubtitle,
                        onTap: () => context.push('/partners'),
                      ),
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

class _ClubBigCard extends StatelessWidget {
  const _ClubBigCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                ),
                child: Icon(icon, size: 22, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
