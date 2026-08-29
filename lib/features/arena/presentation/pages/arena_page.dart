import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/error/result.dart';
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
import 'package:goias_app/features/arena/presentation/widgets/arena_challenge_card.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_header_bar.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_highlight_card.dart';
import 'package:goias_app/features/arena/presentation/widgets/arena_section_header.dart';
import 'package:goias_app/features/arena/presentation/widgets/crowd_lineup_hero_card.dart';
import 'package:goias_app/features/crowd_lineup/domain/crowd_lineup.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_state.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
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
  late Future<int?> _crowdParticipantsFuture = _loadCrowdParticipants();
  bool _celebrationShown = false;

  Future<({int rank, int totalScore})?> _loadMyRank() async {
    final result = await sl<ArenaRankingRepository>().getMyRank(
      RankingPeriod.allTime,
    );
    return result is Success<({int rank, int totalScore})?>
        ? result.data
        : null;
  }

  /// Só usado pro "X torcedores já escalaram" do hero — opcional por
  /// natureza (ver spec), então qualquer falha/ausência de próximo jogo
  /// simplesmente esconde essa linha, nunca quebra o hero.
  Future<int?> _loadCrowdParticipants() async {
    final matchId = sl<HomeCubit>().state.nextMatch?.id;
    if (matchId == null) return null;
    final result = await sl<CrowdLineupRepository>().getCrowdLineup(matchId);
    return result is Success<CrowdLineup> ? result.data.totalVotes : null;
  }

  void _reloadProgress() {
    setState(() {
      _progressFuture = sl<ArenaProgressRepository>().loadSnapshot();
      _myRankFuture = _loadMyRank();
      _crowdParticipantsFuture = _loadCrowdParticipants();
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

  /// Progresso de coleção finita por jogo — só os 3 com progressão
  /// persistente têm um valor; Quem Vestiu o Manto (`guess_player`) sempre
  /// `null` (ver `ArenaProgressSnapshot`).
  ({int completed, int total})? _progressFor(
    String gameId,
    ArenaProgressSnapshot? snapshot,
  ) {
    if (snapshot == null) return null;
    return switch (gameId) {
      'quiz' => (completed: snapshot.quizAnswered, total: snapshot.quizTotal),
      'lineup' => (
        completed: snapshot.lineupCompleted,
        total: snapshot.lineupTotal,
      ),
      'career_path' => (
        completed: snapshot.careerCompleted,
        total: snapshot.careerTotal,
      ),
      _ => null,
    };
  }

  /// Métrica alternativa pro único jogo sem coleção finita — mesmo texto
  /// que já existia no rodapé antigo, só realocado pro novo card unificado.
  String? _statLabelFor(
    BuildContext context,
    String gameId,
    ArenaProgressSnapshot? snapshot,
  ) {
    if (gameId != 'guess_player' || snapshot == null) return null;
    return snapshot.guessPlayerPlayed == 0
        ? context.l10n.arenaPlayFirstTime
        : context.l10n.arenaStatMatchesCorrect(
            snapshot.guessPlayerPlayed,
            snapshot.guessPlayerCorrect,
          );
  }

  Future<void> _openRanking(BuildContext context) async {
    final cubit = await GlobalLoading.run(context, () async {
      final cubit = RankingCubit(
        sl<ArenaRankingRepository>(),
        sl<MembershipStatusCubit>(),
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

  VoidCallback _openGame(BuildContext context, String gameId) {
    return () => switch (gameId) {
      'quiz' => _openQuizLevels(context),
      'career_path' => _openCareerPath(context),
      'lineup' => _openLineup(context),
      'guess_player' => _openGuessPlayer(context),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const games = ArenaCatalog.games;

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
                      FutureBuilder<({int rank, int totalScore})?>(
                        future: _myRankFuture,
                        builder: (context, rankSnapshot) => ArenaHeaderBar(
                          rank: rankSnapshot.data?.rank,
                          onRankingTap: () => _openRanking(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Hero da Escalação da Torcida — o elemento principal
                      // da página quando há próximo jogo (ver spec de
                      // reformulação). `HomeCubit` é singleton (pré-carregado
                      // desde a Splash), então basta ler o estado atual, sem
                      // recarregar nada aqui.
                      BlocBuilder<HomeCubit, HomeState>(
                        bloc: sl<HomeCubit>(),
                        builder: (context, homeState) {
                          final nextMatch = homeState.nextMatch;
                          if (nextMatch == null) {
                            return const CrowdLineupHeroEmptyCard();
                          }
                          return FutureBuilder<int?>(
                            future: _crowdParticipantsFuture,
                            builder: (context, participantsSnapshot) {
                              return CrowdLineupHeroCard(
                                match: nextMatch,
                                hasVoted: homeState.hasVotedForNextMatch,
                                participants: participantsSnapshot.data,
                                onTap: () =>
                                    _openCrowdLineup(context, nextMatch),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Passaporte — memória/coleção do torcedor, com
                      // identidade própria (fundo claro), nunca misturado
                      // com os desafios/minigames abaixo.
                      ArenaHighlightCard(
                        leading: ArenaHighlightLeading(
                          child: Icon(
                            Icons.confirmation_number_outlined,
                            color: colors.primary,
                            size: 24,
                          ),
                        ),
                        title: context.l10n.passportTitle,
                        description: context.l10n.passportCardDescription,
                        ctaLabel: context.l10n.passportCardCta,
                        onTap: () => context.push('/arena/passport'),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      ArenaSectionHeader(
                        context.l10n.arenaChallengesSectionTitle,
                        subtitle: context.l10n.arenaGamesSectionSubtitle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LayoutBuilder(
                        builder: (context, constraints) => GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: switch (constraints.maxWidth) {
                            < 500 => 2,
                            _ => 3,
                          },
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.05,
                          children: [
                            for (final game in games)
                              ArenaChallengeCard(
                                game: game,
                                progress: _progressFor(game.id, progress),
                                statLabel: _statLabelFor(
                                  context,
                                  game.id,
                                  progress,
                                ),
                                everStarted:
                                    game.id == 'guess_player' &&
                                    progress != null &&
                                    progress.guessPlayerPlayed > 0,
                                onTap: _openGame(context, game.id),
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
