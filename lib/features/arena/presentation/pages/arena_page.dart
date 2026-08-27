import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_breakpoints.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/data/arena_catalog.dart';
import 'package:goias_app/features/arena/data/arena_progress_repository.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_cubit.dart';
import 'package:goias_app/features/arena/games/career_path/data/career_player_repository.dart';
import 'package:goias_app/features/arena/games/career_path/data/supabase_career_path_storage.dart';
import 'package:goias_app/features/arena/games/guess_player/cubit/guess_player_cubit.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_repository.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_storage.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/data/lineup_match_repository.dart';
import 'package:goias_app/features/arena/games/lineup/data/supabase_lineup_storage.dart';
import 'package:goias_app/features/arena/games/quiz/pages/quiz_level_page.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/features/arena/ranking/presentation/cubit/ranking_cubit.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_game_card.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_highlight_card.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_section_header.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_state.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

const _arenaTabIndex = 4;

class ArenaPage extends StatefulWidget {
  const ArenaPage({super.key});

  @override
  State<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends State<ArenaPage> with RouteAware {
  // `ArenaPage` é uma aba dentro do `IndexedStack` da Home — nunca é
  // recriada ao trocar de aba nem ao empurrar/voltar de uma rota de jogo
  // por cima dela, então sem os dois mecanismos abaixo esse snapshot
  // ficaria preso no valor da primeira vez que a aba abriu, mesmo depois
  // de jogar (só um restart completo do app resolvia):
  // - `BlocListener` (no build) cobre TROCAR DE ABA e voltar;
  // - `RouteAware.didPopNext` (abaixo) cobre EMPURRAR uma rota de jogo
  //   (Quiz, Escalação, Jogador, Manto) por cima da Arena e voltar — o
  //   caso mais comum, já que é assim que se joga.
  late Future<ArenaProgressSnapshot> _progressFuture =
      sl<ArenaProgressRepository>().loadSnapshot();
  late Future<({int rank, int totalScore})?> _myRankFuture = _loadMyRank();
  bool _celebrationShown = false;

  Future<({int rank, int totalScore})?> _loadMyRank() async {
    final result = await sl<ArenaRankingRepository>().getMyRank(
      RankingPeriod.allTime,
    );
    return result is Success<({int rank, int totalScore})?>
        ? result.data
        : null;
  }

  void _reloadProgress() {
    setState(() {
      _progressFuture = sl<ArenaProgressRepository>().loadSnapshot();
      _myRankFuture = _loadMyRank();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => _reloadProgress();

  Future<void> _maybeCelebrate(ArenaProgressSnapshot snapshot) async {
    if (!snapshot.justUnlockedAchievement || _celebrationShown) return;
    _celebrationShown = true;
    await AppBottomSheet.show(
      context,
      icon: Icons.military_tech_rounded,
      title: context.l10n.arenaAchievementTitle,
      description: context.l10n.arenaAchievementMessage,
      confirmLabel: context.l10n.arenaAchievementConfirm,
    );
  }

  /// Rodapé de cada card — os 3 jogos de coleção finita mostram barra de
  /// progresso; Quem Vestiu o Manto mostra desempenho (partidas/acertos),
  /// nunca uma fração de coleção (o mesmo jogador pode voltar a ser
  /// secreto, então "X/total" não faz sentido pra ele).
  Widget? _footerFor(String gameId, ArenaProgressSnapshot? snapshot) {
    if (snapshot == null) return null;
    return switch (gameId) {
      'quiz' => ArenaCardProgressFooter(
        progress: (completed: snapshot.quizAnswered, total: snapshot.quizTotal),
      ),
      'lineup' => ArenaCardProgressFooter(
        progress: (
          completed: snapshot.lineupCompleted,
          total: snapshot.lineupTotal,
        ),
      ),
      'career_path' => ArenaCardProgressFooter(
        progress: (
          completed: snapshot.careerCompleted,
          total: snapshot.careerTotal,
        ),
      ),
      'guess_player' => ArenaCardStatFooter(
        text: snapshot.guessPlayerPlayed == 0
            ? context.l10n.arenaPlayFirstTime
            : context.l10n.arenaStatMatchesCorrect(
                snapshot.guessPlayerPlayed,
                snapshot.guessPlayerCorrect,
              ),
      ),
      _ => null,
    };
  }

  Future<void> _openRanking(BuildContext context) async {
    final cubit = await GlobalLoading.run(context, () async {
      final cubit = RankingCubit(
        sl<ArenaRankingRepository>(),
        sl<MembershipRepository>(),
      );
      await cubit.load();
      return cubit;
    });
    if (!context.mounted) return;
    unawaited(context.push('/arena/ranking', extra: cubit));
  }

  /// Carrega o resumo dos 3 níveis ANTES de navegar — a tela de níveis do
  /// Quiz já abre pronta (título + cards), nunca com o cabeçalho visível e
  /// só a lista carregando por baixo.
  Future<void> _openQuizLevels(BuildContext context) async {
    final summaries = await GlobalLoading.run(context, loadQuizLevelSummaries);
    if (!context.mounted) return;
    unawaited(context.push('/arena/quiz', extra: summaries));
  }

  /// Carrega os jogadores (Supabase, com fallback local) e retoma a rodada
  /// salva ANTES de navegar — mesma lógica de "nunca aparecer vazio" das
  /// outras entradas da Arena.
  Future<void> _openCareerPath(BuildContext context) async {
    final cubit = await GlobalLoading.run(context, () async {
      final players = await sl<CareerPlayerRepository>().load();
      final storage = sl<SupabaseCareerPathStorage>();
      final cubit = CareerPathCubit(
        players: players,
        loadRound: storage.load,
        saveRound: storage.save,
        loadSelectedId: storage.loadSelectedPlayerId,
        saveSelectedId: storage.saveSelectedPlayerId,
        loadCompletedIds: storage.completedIds,
        ranking: sl<ArenaRankingRepository>(),
      );
      await cubit.loadSelected();
      return cubit;
    });
    if (!context.mounted) return;
    unawaited(context.push('/arena/career-path', extra: cubit));
  }

  /// Mesma lógica do Adivinhe o Jogador, agora pra Adivinhe a Escalação.
  Future<void> _openLineup(BuildContext context) async {
    final cubit = await GlobalLoading.run(context, () async {
      final matches = await sl<LineupMatchRepository>().load();
      final storage = sl<SupabaseLineupStorage>();
      final cubit = LineupCubit(
        matches: matches,
        loadState: storage.load,
        saveState: storage.save,
        loadSelectedMatchId: storage.loadSelectedMatchId,
        saveSelectedMatchId: storage.saveSelectedMatchId,
        loadCompletedIds: storage.completedIds,
        ranking: sl<ArenaRankingRepository>(),
      );
      await cubit.loadSelectedMatch();
      return cubit;
    });
    if (!context.mounted) return;
    unawaited(context.push('/arena/lineup', extra: cubit));
  }

  /// Mesma lógica dos outros dois jogos — carrega o catálogo (Supabase com
  /// fallback local) antes de navegar. O Cubit já cuida sozinho de
  /// retomar/sortear a rodada assim que é construído (ver `GuessPlayerCubit`).
  Future<void> _openGuessPlayer(BuildContext context) async {
    final cubit = await GlobalLoading.run(context, () async {
      final catalog = await sl<GuessPlayerRepository>().load();
      final storage = sl<GuessPlayerStorage>();
      return GuessPlayerCubit(
        catalog: catalog,
        loadRound: storage.loadActiveRound,
        saveRound: storage.saveActiveRound,
        clearRound: storage.clearActiveRound,
        recordRoundResult: storage.recordRoundResult,
        ranking: sl<ArenaRankingRepository>(),
        loadSeenIds: storage.loadSeenIds,
        addSeenId: storage.addSeenId,
        clearSeenIds: storage.clearSeenIds,
        loadSeenSignature: storage.loadSeenSignature,
        saveSeenSignature: storage.saveSeenSignature,
      );
    });
    if (!context.mounted) return;
    unawaited(context.push('/arena/guess-player', extra: cubit));
  }

  /// Carrega a escalação salva do usuário ANTES de navegar, pra "Escalação
  /// da Torcida" já abrir com jogadores/formação restaurados — mesma lógica
  /// que já existia na Home antes deste card se mudar pra cá.
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

  String? _subtitleFor(String gameId) {
    return switch (gameId) {
      'quiz' => context.l10n.arenaSubtitleQuiz,
      'lineup' => context.l10n.arenaSubtitleLineup,
      'career_path' => context.l10n.arenaSubtitleCareer,
      'guess_player' => context.l10n.arenaSubtitleGuessPlayer,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const games = ArenaCatalog.games;
    final featuredList = games.where((game) => game.featured).toList();
    final featured = featuredList.isEmpty ? null : featuredList.first;
    final others = games.where((game) => !game.featured).toList();

    return BlocListener<HomeShellCubit, HomeShellState>(
      listenWhen: (previous, current) =>
          previous.index != _arenaTabIndex && current.index == _arenaTabIndex,
      listener: (context, state) => _reloadProgress(),
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: FutureBuilder<ArenaProgressSnapshot>(
            future: _progressFuture,
            builder: (context, snapshot) {
              final progress = snapshot.data;
              if (progress != null) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _maybeCelebrate(progress),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ContentWidth.wide.maxWidth,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      Text(
                        'ARENA ESMERALDINA',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.arenaSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      ArenaSectionHeader(
                        context.l10n.arenaHighlightsSectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Destaque de escalação (mesmo card que já existia na
                      // Home, só movido pra cá) — só aparece quando há
                      // próximo jogo. `HomeCubit` é singleton (pré-carregado
                      // desde a Splash), então basta ler o estado atual, sem
                      // recarregar nada aqui.
                      BlocBuilder<HomeCubit, HomeState>(
                        bloc: sl<HomeCubit>(),
                        builder: (context, homeState) {
                          final nextMatch = homeState.nextMatch;
                          if (nextMatch == null) return const SizedBox.shrink();
                          final hasVoted = homeState.hasVotedForNextMatch;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: ArenaHighlightCard(
                              leading: ArenaHighlightLeading(
                                child: Image.asset(
                                  AppAssets.tacticsBoardIllustration,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              topBadge: context.l10n.arenaNextMatchBadge,
                              title: hasVoted
                                  ? context.l10n.crowdCardTitleVoted
                                  : context.l10n.crowdCardTitleNew,
                              description: hasVoted
                                  ? context.l10n.crowdCardDescVoted
                                  : context.l10n.crowdCardDescNew,
                              ctaLabel: hasVoted
                                  ? context.l10n.arenaHighlightViewLineup
                                  : context.l10n.arenaHighlightEscaleLineup,
                              onTap: () => _openCrowdLineup(context, nextMatch),
                            ),
                          );
                        },
                      ),
                      FutureBuilder<({int rank, int totalScore})?>(
                        future: _myRankFuture,
                        builder: (context, snapshot) {
                          final myRank = snapshot.data?.rank;
                          return ArenaHighlightCard(
                            leading: ArenaHighlightLeading(
                              child: Icon(
                                Icons.emoji_events_rounded,
                                color: colors.primary,
                                size: 26,
                              ),
                            ),
                            title: context.l10n.arenaRankingTitle,
                            description: context.l10n.arenaRankingHighlightDesc,
                            extra: myRank != null
                                ? ArenaHighlightPositionPill(
                                    label: context.l10n
                                        .arenaYourPosition(myRank)
                                        .toUpperCase(),
                                  )
                                : Text(
                                    context.l10n.arenaRankingPlayToRank,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textHint,
                                    ),
                                  ),
                            ctaLabel: context.l10n.arenaHighlightViewRanking,
                            onTap: () => _openRanking(context),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      ArenaSectionHeader(
                        context.l10n.arenaGamesSectionTitle,
                        subtitle: context.l10n.arenaGamesSectionSubtitle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (featured != null) ...[
                        _SectionLabel(context.l10n.arenaSectionPlayNow),
                        const SizedBox(height: AppSpacing.md),
                        // Nenhum jogo é `featured` hoje (Pênaltis está
                        // oculto) — este bloco fica pronto pra quando algum
                        // jogo voltar a ser destaque.
                        ArenaFeaturedCard(
                          game: featured,
                          onTap: () => switch (featured.id) {
                            'quiz' => _openQuizLevels(context),
                            'career_path' => _openCareerPath(context),
                            'lineup' => _openLineup(context),
                            'guess_player' => _openGuessPlayer(context),
                            _ => context.push(featured.route),
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SectionLabel(context.l10n.arenaSectionMoreChallenges),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      LayoutBuilder(
                        builder: (context, constraints) => GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: responsiveColumnCount(
                            constraints.maxWidth,
                            itemWidth: 260,
                            maxColumns: 3,
                          ),
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.08,
                          children: [
                            for (final game in others)
                              ArenaCompactCard(
                                game: game,
                                subtitle: _subtitleFor(game.id),
                                footer: _footerFor(game.id, progress),
                                decorativeBackground: game.id == 'guess_player'
                                    ? const ArenaCardFaceDecoration()
                                    : null,
                                onTap: () => switch (game.id) {
                                  'quiz' => _openQuizLevels(context),
                                  'career_path' => _openCareerPath(context),
                                  'lineup' => _openLineup(context),
                                  'guess_player' => _openGuessPlayer(context),
                                  _ => context.push(game.route),
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: context.colors.textHint,
      ),
    );
  }
}
