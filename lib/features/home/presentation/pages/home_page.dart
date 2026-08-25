import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/club/presentation/widgets/club_entry_card.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/crowd_lineup_home_card.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/home/presentation/widgets/home_brand_header.dart';
import 'package:goias_app/features/home/presentation/widgets/membership_banner.dart';
import 'package:goias_app/features/home/presentation/widgets/next_match_section.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/news/presentation/widgets/news_home_section.dart';
import 'package:goias_app/features/partners/presentation/widgets/partners_home_section.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

/// [HomeCubit] agora é singleton (ver `injection_container.dart`) — pra
/// dar tempo da Splash pré-carregar ele por trás do vídeo (ver
/// `splash_video_page.dart`), sem precisar de um segundo loading assim que
/// a Home aparece. `BlocProvider.value` (não `create`) de propósito: quem
/// criou/é dono desse Cubit é o container de DI, não esta tela — se fosse
/// `create`, o provider fecharia o Cubit ao sair da árvore, quebrando o
/// singleton pra o resto do app.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: sl<HomeCubit>(), child: const _HomeView());
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with RouteAware {
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Ex.: usuário mudou o status de sócio (mock) no Perfil e voltou — o
  /// banner "Seja sócio esmeraldino" precisa refletir isso na volta.
  @override
  void didPopNext() => context.read<HomeCubit>().load();

  /// Carrega a escalação salva do usuário ANTES de navegar, pra
  /// "Escalação da Torcida" já abrir com jogadores/formação restaurados —
  /// nunca vazia esperando o carregamento aparecer.
  Future<void> _openCrowdLineup(BuildContext context, Match match) async {
    final cubit = CrowdLineupCubit(
      repository: sl<CrowdLineupRepository>(),
      matchId: match.id,
      votingOpen: true,
    );
    await GlobalLoading.run(context, cubit.load);
    if (!context.mounted) return;
    unawaited(
      context.push('/crowd-lineup', extra: (match: match, cubit: cubit)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.loading && state.nextMatch == null) {
              return const Center(child: GoiasLoadingIndicator());
            }
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HomeBrandHeader(),
                      if (state.nextMatch != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        NextMatchSection(
                          match: state.nextMatch!,
                          onTickets: () => context.push('/tickets'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        CrowdLineupHomeCard(
                          hasVoted: state.hasVotedForNextMatch,
                          onTap: () =>
                              _openCrowdLineup(context, state.nextMatch!),
                        ),
                      ],
                      if (!state.isMember) ...[
                        const SizedBox(height: AppSpacing.xl),
                        MembershipBanner(
                          onViewPlans: () =>
                              context.read<HomeShellCubit>().navigateToTab(2),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      const NewsHomeSection(),
                      const SizedBox(height: AppSpacing.xl),
                      ClubEntryCard(onTap: () => context.push('/clube')),
                      const SizedBox(height: AppSpacing.xl),
                      const PartnersHomeSection(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
