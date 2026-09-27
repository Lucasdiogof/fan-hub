import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:goias_app/shared/utils/image_proxy.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
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
                        previous.competition?.name !=
                            current.competition?.name ||
                        previous.competition?.logoUrl !=
                            current.competition?.logoUrl,
                    builder: (context, state) => _CompetitionTitle(
                      text: state.competition?.name ?? fallbackName ?? '',
                      logoUrl: state.competition?.logoUrl,
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

/// Mesmo layout do `PageTitle` (barrinha + escudo + texto), mas com a logo
/// da PRÓPRIA competição em vez do escudo do clube ativo — só faz sentido
/// aqui, onde a tela é sobre uma competição do catálogo global, não sobre o
/// clube (ver `fetchCompetitionLogoUrl` no Worker). Sem `logoUrl` (ainda
/// carregando ou o provider não achou), cai num ícone de troféu genérico.
class _CompetitionTitle extends StatelessWidget {
  const _CompetitionTitle({required this.text, required this.logoUrl});

  final String text;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        _CompetitionLogo(url: logoUrl, colors: colors),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompetitionLogo extends StatelessWidget {
  const _CompetitionLogo({required this.url, required this.colors});

  final String? url;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null || url.isEmpty) return _fallbackIcon();
    return CachedNetworkImage(
      imageUrl: proxiedImageUrl(url),
      width: 22,
      height: 22,
      fit: BoxFit.contain,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, _) => const SizedBox(width: 22, height: 22),
      errorWidget: (context, _, _) => _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Icon(Icons.emoji_events_rounded, size: 22, color: colors.primary);
  }
}
