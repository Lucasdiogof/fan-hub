import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_spotlight_card.dart';
import 'package:goias_app/features/club/presentation/widgets/club_entry_card.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_state.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/home/presentation/widgets/compact_match_header.dart';
import 'package:goias_app/features/home/presentation/widgets/home_brand_header.dart';
import 'package:goias_app/features/home/presentation/widgets/main_navigation_items.dart';
import 'package:goias_app/features/home/presentation/widgets/next_match_section.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/match_navigation.dart';
import 'package:goias_app/features/match/presentation/widgets/live_match_poller.dart';
import 'package:goias_app/features/store/presentation/widgets/goias_store_banner.dart';
import 'package:goias_app/features/store/presentation/widgets/store_entry_card.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

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

  /// Marca a posição/altura real do hero grande na árvore — é assim que o
  /// header compacto sabe quando aparecer: nunca um número mágico de
  /// scroll, sempre a posição de verdade do hero na tela (ver
  /// `_updateCompactHeaderVisibility`).
  final _heroKey = GlobalKey();
  final _scrollController = ScrollController();
  bool _showCompactHeader = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateCompactHeaderVisibility(),
    );
  }

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
    _scrollController.dispose();
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
    if (sl<HomeShellCubit>().state.index == homeTabIndex) {
      context.read<HomeCubit>().load();
    }
  }

  /// O header compacto aparece quando a borda de baixo do hero grande sobe
  /// além do topo da área segura — a posição REAL na tela, não um offset de
  /// scroll arbitrário. `findRenderObject()` é seguro aqui: só é chamado
  /// depois do layout (notificação de scroll ou pós-frame), nunca durante.
  void _updateCompactHeaderVisibility() {
    if (!mounted) return;
    final renderObject = _heroKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;
    final topInset = MediaQuery.paddingOf(context).top;
    final heroBottom = renderObject
        .localToGlobal(Offset(0, renderObject.size.height))
        .dy;
    final shouldShow = heroBottom <= topInset;
    if (shouldShow != _showCompactHeader) {
      setState(() => _showCompactHeader = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocListener<HomeShellCubit, HomeShellState>(
      bloc: sl<HomeShellCubit>(),
      listenWhen: (previous, current) =>
          previous.index != homeTabIndex && current.index == homeTabIndex,
      listener: (context, state) => context.read<HomeCubit>().load(),
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state.status == LoadStatus.loading && state.nextMatch == null) {
                return const Center(child: GoiasLoadingIndicator());
              }

              final match = state.nextMatch;
              if (match == null) {
                // Sem próximo jogo (ou erro ao buscar — as duas categorias
                // nunca mostram hero/header compacto) — nunca deixa
                // `_showCompactHeader` "preso" em true de uma partida
                // anterior.
                if (_showCompactHeader) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _showCompactHeader = false);
                  });
                }
                return _ScrollContent(
                  scrollController: _scrollController,
                  match: null,
                  heroKey: _heroKey,
                  isError: state.status == LoadStatus.error,
                  errorMessage: state.errorMessage,
                );
              }

              // Mesma regra de antes (`NextMatchSection`): só entra em
              // polling quando o jogo já está de fato rolando — enquanto
              // está só agendado, `match` já é tudo que existe pra mostrar.
              final isLive =
                  match.status == MatchStatus.live ||
                  match.status == MatchStatus.halftime;

              if (!isLive) {
                return _buildStack(context, match);
              }
              return LiveMatchPoller(
                match: match,
                onMatchEnded: () => context.read<HomeCubit>().load(),
                builder: (context, liveMatch) =>
                    _buildStack(context, liveMatch),
              );
            },
          ),
        ),
      ),
    );
  }

  /// [displayMatch] é a MESMA partida (já ao vivo ou não) usada tanto pelo
  /// hero grande quanto pelo header compacto — única fonte de verdade,
  /// nenhum dos dois busca/atualiza nada por conta própria.
  Widget _buildStack(BuildContext context, Match displayMatch) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _updateCompactHeaderVisibility();
        return false;
      },
      child: Stack(
        children: [
          _ScrollContent(
            scrollController: _scrollController,
            match: displayMatch,
            heroKey: _heroKey,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_showCompactHeader,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                offset: _showCompactHeader ? Offset.zero : const Offset(0, -0.3),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  opacity: _showCompactHeader ? 1 : 0,
                  child: CompactMatchHeader(
                    match: displayMatch,
                    onTap: () => openMatchDetails(context, displayMatch),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollContent extends StatelessWidget {
  const _ScrollContent({
    required this.scrollController,
    required this.match,
    required this.heroKey,
    this.isError = false,
    this.errorMessage,
  });

  final ScrollController scrollController;
  final Match? match;
  final Key heroKey;

  /// Falha ao buscar o próximo jogo — nunca mostrado como se simplesmente
  /// não houvesse jogo (ver `HomeCubit.load`, branch `Error`). Só faz
  /// sentido quando [match] é `null`.
  final bool isError;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
        child: SingleChildScrollView(
          controller: scrollController,
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
              if (match != null) ...[
                const SizedBox(height: AppSpacing.md),
                NextMatchSection(
                  key: heroKey,
                  match: match!,
                  onTickets: () => context.push('/tickets'),
                  onMatchStarted: () => context.read<HomeCubit>().load(),
                ),
              ] else if (isError) ...[
                const SizedBox(height: AppSpacing.xl),
                StateMessage(
                  icon: Icons.wifi_off_rounded,
                  title: context.l10n.commonLoadError,
                  message: errorMessage,
                  actionLabel: context.l10n.commonRetry,
                  onAction: () => context.read<HomeCubit>().load(),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              ClubEntryCard(onTap: () => context.push('/clube')),
              const SizedBox(height: AppSpacing.lg),
              const ArenaSpotlightCard(),
              const SizedBox(height: AppSpacing.lg),
              StoreEntryCard(
                onTap: () =>
                    sl<HomeShellCubit>().navigateToTab(lojaTabIndex),
              ),
              const SizedBox(height: AppSpacing.lg),
              GoiasStoreBanner(
                onTap: () =>
                    sl<HomeShellCubit>().navigateToTab(lojaTabIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
