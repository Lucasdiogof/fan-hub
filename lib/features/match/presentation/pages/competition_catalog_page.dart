import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/competition_catalog_cubit.dart';
import 'package:goias_app/features/match/presentation/cubit/competition_catalog_state.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/refreshable_state_view.dart';

/// Catálogo GLOBAL de competições (spec multi-competição, item 5/6/30) —
/// busca, "SUAS COMPETIÇÕES" em destaque no topo, resto agrupado por
/// região. Qualquer item abre normalmente, disputado pelo clube ativo ou
/// não (item 21: participação nunca é gate de acesso).
class CompetitionCatalogPage extends StatelessWidget {
  const CompetitionCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CompetitionCatalogCubit(sl<FootballRepository>())..load(),
      child: const _CompetitionCatalogView(),
    );
  }
}

class _CompetitionCatalogView extends StatelessWidget {
  const _CompetitionCatalogView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButtonCircle(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PageTitle(context.l10n.otherCompetitionsTitle),
                  const SizedBox(height: AppSpacing.lg),
                  _SearchField(
                    onChanged: (query) =>
                        context.read<CompetitionCatalogCubit>().setQuery(query),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child:
                        BlocBuilder<
                          CompetitionCatalogCubit,
                          CompetitionCatalogState
                        >(
                          builder: (context, state) {
                            return RefreshableStateView(
                              status: state.status,
                              onRefresh: () => context
                                  .read<CompetitionCatalogCubit>()
                                  .load(),
                              errorMessage: state.errorMessage,
                              emptyIcon: Icons.emoji_events_outlined,
                              emptyTitle:
                                  context.l10n.otherCompetitionsSearchEmpty,
                              successBuilder: (context) {
                                final yours = state.yours;
                                final othersByRegion = state.othersByRegion;
                                if (yours.isEmpty && othersByRegion.isEmpty) {
                                  return Center(
                                    child: Text(
                                      context.l10n.otherCompetitionsSearchEmpty,
                                      style: TextStyle(color: colors.textHint),
                                    ),
                                  );
                                }
                                return ListView(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xxxl,
                                  ),
                                  children: [
                                    if (yours.isNotEmpty) ...[
                                      _SectionLabel(
                                        context
                                            .l10n
                                            .otherCompetitionsYourCompetitions,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      for (final competition in yours)
                                        _CompetitionTile(
                                          competition: competition,
                                          starred: true,
                                        ),
                                      const SizedBox(height: AppSpacing.lg),
                                    ],
                                    for (final entry
                                        in othersByRegion.entries) ...[
                                      _SectionLabel(entry.key.toUpperCase()),
                                      const SizedBox(height: AppSpacing.sm),
                                      for (final competition in entry.value)
                                        _CompetitionTile(
                                          competition: competition,
                                        ),
                                      const SizedBox(height: AppSpacing.lg),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: context.l10n.otherCompetitionsSearchHint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: colors.textHint,
      ),
    );
  }
}

class _CompetitionTile extends StatelessWidget {
  const _CompetitionTile({required this.competition, this.starred = false});

  final CompetitionRef competition;
  final bool starred;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(
          '/games/competitions/${competition.id}',
          extra: competition.name,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              if (starred) ...[
                Icon(Icons.star_rounded, size: 16, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  competition.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
