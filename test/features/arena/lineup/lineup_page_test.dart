import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/arena/games/lineup/data/supabase_lineup_storage.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/lineup/pages/lineup_page.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeRanking implements ArenaRankingRepository {
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
  }) async => const Success(
    ScoreResult(pointsEarned: 0, itemScore: 0, totalScore: 0, gameScore: 0),
  );

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
}
