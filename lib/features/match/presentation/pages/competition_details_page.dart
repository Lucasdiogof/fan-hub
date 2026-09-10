import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/competition_details_cubit.dart';
import 'package:goias_app/features/match/presentation/cubit/competition_details_state.dart';
import 'package:goias_app/features/match/presentation/widgets/competition_stage_renderer.dart';
import 'package:goias_app/features/match/presentation/widgets/competition_stage_selector.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/refreshable_state_view.dart';

/// Tela própria de UMA competição do catálogo (spec multi-competição, item
/// 7/8) — aberta a partir do catálogo global, mostra a classificação dessa
/// competição normalmente, independente de o clube ativo participar dela
/// ou não. [competitionName] é só pra já mostrar um título sem esperar a
/// rede (a resposta real confirma/atualiza assim que chega).
class CompetitionDetailsPage extends StatelessWidget {
  const CompetitionDetailsPage({
    required this.competitionId,
    this.competitionName,
    super.key,
  });

  final String competitionId;
  final String? competitionName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CompetitionDetailsCubit(sl<FootballRepository>(), competitionId)
            ..load(),
      child: _CompetitionDetailsView(fallbackName: competitionName),
    );
  }
}

class _CompetitionDetailsView extends StatelessWidget {
  const _CompetitionDetailsView({this.fallbackName});

  final String? fallbackName;

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
                  BlocBuilder<CompetitionDetailsCubit, CompetitionDetailsState>(
                    buildWhen: (previous, current) =>
                        previous.competition?.name != current.competition?.name,
                    builder: (context, state) => PageTitle(
                      state.competition?.name ?? fallbackName ?? '',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child:
                        BlocBuilder<
                          CompetitionDetailsCubit,
                          CompetitionDetailsState
                        >(
                          builder: (context, state) {
                            return RefreshableStateView(
                              status: state.status,
                              onRefresh: () => context
                                  .read<CompetitionDetailsCubit>()
                                  .load(),
                              errorMessage: state.errorMessage,
                              emptyIcon: Icons.leaderboard_outlined,
                              emptyTitle: context.l10n.standingsUnavailable,
                              successBuilder: (context) => ListView(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xxxl,
                                ),
                                children: [
                                  CompetitionStageSelector(
                                    stages: state.stages,
                                    selectedStageId: state.selectedStageId,
                                    onSelected: (id) => context
                                        .read<CompetitionDetailsCubit>()
                                        .selectStage(id),
                                  ),
                                  if (state.stages.length > 1)
                                    const SizedBox(height: AppSpacing.lg),
                                  CompetitionStageRenderer(
                                    stages: state.stages,
                                    selectedStageId: state.selectedStageId,
                                  ),
                                ],
                              ),
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
