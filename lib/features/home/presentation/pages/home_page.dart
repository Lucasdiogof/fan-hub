import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/presentation/widgets/club_entry_card.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_state.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/home/presentation/widgets/home_brand_header.dart';
import 'package:goias_app/features/home/presentation/widgets/next_match_section.dart';
import 'package:goias_app/features/news/presentation/widgets/news_home_section.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

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

  /// Recarrega ao voltar pra Home (ex.: próximo jogo/notícias podem ter
  /// mudado enquanto o usuário estava em outra tela). `HomePage` é uma aba
  /// do `IndexedStack` da Home — todas as abas compartilham a MESMA rota
  /// (`/`), então `didPopNext` dispara pra ela mesmo quando quem voltou foi
  /// outra aba (ex.: Arena → Ranking → voltar). Sem essa checagem de índice,
  /// isso recarregava a Home (e a request pro backend de futebol) por
  /// baixo dos panos toda vez que QUALQUER tela do app era fechada.
  @override
  void didPopNext() {
    if (sl<HomeShellCubit>().state.index == 0) {
      context.read<HomeCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocListener<HomeShellCubit, HomeShellState>(
      bloc: sl<HomeShellCubit>(),
      listenWhen: (previous, current) =>
          previous.index != 0 && current.index == 0,
      listener: (context, state) => context.read<HomeCubit>().load(),
      child: Scaffold(
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
                  constraints: BoxConstraints(
                    maxWidth: ContentWidth.wide.maxWidth,
                  ),
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
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        ClubEntryCard(onTap: () => context.push('/clube')),
                        const SizedBox(height: AppSpacing.xl),
                        const NewsHomeSection(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
