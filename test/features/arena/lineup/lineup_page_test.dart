import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/data/lineup_match_repository.dart';
import 'package:goias_app/features/arena/games/lineup/data/supabase_lineup_storage.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/lineup/pages/lineup_page.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeRanking implements ArenaRankingRepository {
  int recordScoreCallCount = 0;

  @override
  Future<Result<ScoreResult>> recordScore({
    required String gameId,
    required String itemId,
    required String eventType,
    int? attemptNumber,
    String? difficulty,
    int? wrongCount,
    int? foundCount,
    int? totalCount,
    bool wasRevealed = false,
    bool wasAbandoned = false,
  }) async {
    recordScoreCallCount++;
    return const Success(
      ScoreResult(pointsEarned: 0, itemScore: 0, totalScore: 0, gameScore: 0),
    );
  }

  @override
  Future<Result<List<RankingEntry>>> getRanking(
    RankingPeriod period, {
    int limit = 50,
  }) async => const Success([]);

  @override
  Future<Result<({int rank, int totalScore})?>> getMyRank(
    RankingPeriod period,
  ) async => const Success(null);

  @override
  Future<Result<RankingUserDetail>> getUserDetail(RankingEntry context) =>
      throw UnimplementedError();
}

/// `LineupPage` resolve `SupabaseLineupStorage` via DI — como o construtor
/// pede um `SupabaseClient` real, fazemos um dublê em memória que estende a
/// classe de verdade e sobrescreve os 5 métodos, em vez de bater na rede.
/// O `SupabaseClient` passado pro `super` nunca é usado.
class _FakeLineupStorage extends SupabaseLineupStorage {
  _FakeLineupStorage({String? initialSelectedId})
    : _selectedId = initialSelectedId,
      super(
        SupabaseClient(
          'https://example.supabase.co',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
        goiasClubConfig,
      );

  final _states = <String, LineupGameState>{};
  String? _selectedId;

  @override
  Future<LineupGameState?> load(String matchId) async => _states[matchId];

  @override
  Future<void> save(LineupGameState state) async =>
      _states[state.matchId] = state;

  @override
  Future<String?> loadSelectedMatchId() async => _selectedId;

  @override
  Future<void> saveSelectedMatchId(String matchId) async =>
      _selectedId = matchId;

  @override
  Future<Set<String>> completedIds() async => const {};
}

void main() {
  setUp(() async {
    await sl.reset();
    // Pré-seleciona a partida pelo id — desde que a ordem passou a
    // embaralhar a cada abertura (mantendo só as já concluídas paradas no
    // lugar, ver `shuffleKeepingDone`), depender de "a primeira do banco"
    // não é mais determinístico. Selecionar por id contorna isso do mesmo
    // jeito que um usuário retomando uma partida específica faria.
    sl.registerLazySingleton<SupabaseLineupStorage>(
      () => _FakeLineupStorage(
        initialSelectedId: '1990_flamengo_cdb_final_volta',
      ),
    );
    sl.registerLazySingleton<ArenaRankingRepository>(_FakeRanking.new);
    // `LineupPage` sem `cubit` preloaded busca as partidas via
    // `LineupMatchRepository` (M3.1) — o client nunca conecta de verdade
    // (mesmo padrão de `_FakeLineupStorage` acima), então a chamada real
    // falha e o repository cai no fallback local (`orderedLineupMatches`),
    // reproduzindo o mesmo dado que o teste já esperava antes da M3.1.
    sl.registerLazySingleton<LineupMatchRepository>(
      () => LineupMatchRepository(
        SupabaseClient(
          'https://example.supabase.co',
          'anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
        goiasClubConfig,
      ),
    );
  });

  testWidgets(
    'selecionar camisa, digitar, enviar, voltar e ver o progresso atualizado',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LineupPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Progresso inicial: nenhum jogador resolvido ainda.
      expect(find.text('0/11'), findsOneWidget);

      // Abre o goleiro da partida pré-selecionada (Copa do Brasil 1990 x
      // Flamengo, ver `initialSelectedId` acima). p0 é o Eduardo Heuser,
      // resposta "EDUARDO" (camisa sem número confirmado → "JOGADOR").
      // Digita pelo teclado físico pra não esbarrar na letra repetida ao
      // procurar as teclas.
      await tester.tap(
        find.byKey(const ValueKey('1990_flamengo_cdb_final_volta-p0')),
      );
      await tester.pumpAndSettle();

      expect(find.text('JOGADOR'), findsOneWidget);

      const keys = [
        LogicalKeyboardKey.keyE,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyU,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyR,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyO,
      ];
      for (final key in keys) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Resolvido: nome revelado na tela de adivinhação.
      expect(find.text('Eduardo Heuser'), findsOneWidget);

      // Volta pro campo sem perder o progresso.
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('1/11'), findsOneWidget);

      // Reabrir o mesmo jogador continua mostrando o resultado (não reseta).
      await tester.tap(
        find.byKey(const ValueKey('1990_flamengo_cdb_final_volta-p0')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Eduardo Heuser'), findsOneWidget);
    },
  );

  group('"Próximo jogo" no diálogo de resultado', () {
    // Banco mínimo de 2 partidas, 1 jogador cada — só pro teste de
    // navegação entre partidas, não precisa do dataset real de 31 partidas
    // nem de digitar respostas certas (usamos `giveUp()` pra completar).
    const player1 = LineupPlayer(
      id: 'p1',
      position: 'GK',
      x: 0.5,
      y: 0.9,
      shirtNumber: 1,
      fullName: 'Jogador Um',
      displayName: 'Um',
      puzzleAnswer: 'UM',
      answerParts: [2],
      normalizedAnswer: 'UM',
    );
    const player2 = LineupPlayer(
      id: 'p2',
      position: 'ST',
      x: 0.5,
      y: 0.1,
      shirtNumber: 9,
      fullName: 'Jogador Dois',
      displayName: 'Dois',
      puzzleAnswer: 'DOIS',
      answerParts: [4],
      normalizedAnswer: 'DOIS',
    );
    final match1 = LineupMatch(
      id: 'match-1',
      competition: 'Teste',
      season: '2024',
      phase: 'Final',
      date: DateTime(2024, 1, 1),
      homeTeam: 'Goiás',
      awayTeam: 'Adversário A',
      homeScore: 1,
      awayScore: 0,
      teamToGuess: 'Goiás',
      formation: '4-4-2',
      formationConfidence: FormationConfidence.confirmed,
      players: const [player1],
    );
    final match2 = LineupMatch(
      id: 'match-2',
      competition: 'Teste',
      season: '2024',
      phase: 'Semifinal',
      date: DateTime(2024, 1, 8),
      homeTeam: 'Goiás',
      awayTeam: 'Adversário B',
      homeScore: 2,
      awayScore: 1,
      teamToGuess: 'Goiás',
      formation: '4-4-2',
      formationConfidence: FormationConfidence.confirmed,
      players: const [player2],
    );

    late _FakeRanking ranking;
    late LineupCubit cubit;
    late GlobalKey<NavigatorState> navigatorKey;

    Future<void> pumpWithArenaBelow(WidgetTester tester) async {
      navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: AppTheme.light,
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Simula a Arena por baixo — é essencial pro teste provar o bug
          // (`LineupPage` empilhada sobre outra tela, não como raiz do
          // Navigator), já que é exatamente isso que expõe o problema do
          // antigo `popUntil((route) => route.isFirst)`.
          home: const Scaffold(body: Center(child: Text('ARENA'))),
        ),
      );
      await tester.pumpAndSettle();
      // Nunca resolve até a rota ser fechada de novo (é assim que o push
      // funciona) — não é pra esperar, só disparar a navegação.
      unawaited(
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => LineupPage(cubit: cubit)),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() async {
      ranking = _FakeRanking();
      cubit = LineupCubit(
        matches: [match1, match2],
        loadState: (_) async => null,
        saveState: (_) async {},
        loadSelectedMatchId: () async => null,
        saveSelectedMatchId: (_) async {},
        loadCompletedIds: () async => const {},
        ranking: ranking,
      );
      // `loadSelectedMatch()` reembaralha o banco quando nada está
      // concluído ainda (ver `shuffleKeepingDone`) — cada teste seleciona
      // depois a partida que precisa pela posição REAL pós-embaralhamento
      // (`state.matches.first`/`.last`), nunca assumindo que "match1" ficou
      // na posição 0.
      await cubit.loadSelectedMatch();
    });

    tearDown(() => cubit.close());

    testWidgets(
      'avança pra próxima partida e continua dentro da tela, sem voltar pra Arena',
      (tester) async {
        final first = cubit.state.matches.first;
        await cubit.selectMatch(first.id);
        await pumpWithArenaBelow(tester);
        expect(cubit.state.match!.id, first.id);
        expect(cubit.state.hasNext, isTrue);

        await cubit.giveUp(); // completa a partida sem precisar acertar.
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
        await tester.pumpAndSettle();

        // Continua dentro de Adivinhe a Escalação, agora na partida
        // seguinte — a tela "ARENA" de baixo nunca volta a aparecer.
        expect(find.text('ARENA'), findsNothing);
        expect(cubit.state.match!.id, cubit.state.matches[1].id);
      },
    );

    testWidgets(
      'na última partida, o diálogo não oferece "próximo jogo" e o usuário fica no campo',
      (tester) async {
        final last = cubit.state.matches.last;
        await cubit.selectMatch(last.id);
        await pumpWithArenaBelow(tester);
        expect(cubit.state.match!.id, last.id);
        expect(cubit.state.hasNext, isFalse);

        await cubit.giveUp();
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
        expect(find.text('ARENA'), findsNothing);
        expect(cubit.state.match!.id, last.id);
      },
    );

    testWidgets(
      'desistir e avançar pra próxima partida não dispara pontuação de novo',
      (tester) async {
        await cubit.selectMatch(cubit.state.matches.first.id);
        await pumpWithArenaBelow(tester);

        await cubit.giveUp();
        await tester.pumpAndSettle();
        expect(ranking.recordScoreCallCount, 1);

        await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
        await tester.pumpAndSettle();

        // Trocar de partida nunca chama `recordScore` de novo — só
        // `submitGuess`/`giveUp` chamam, e nenhum dos dois rodou na
        // partida 2 ainda.
        expect(ranking.recordScoreCallCount, 1);
      },
    );
  });
}
