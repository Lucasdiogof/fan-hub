import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _playerA = LineupPlayer(
  id: 'a',
  position: 'GK',
  x: 0.5,
  y: 0.9,
  shirtNumber: 1,
  fullName: 'Jogador A da Silva',
  displayName: 'Silva',
  puzzleAnswer: 'SILVA',
  answerParts: [5],
  normalizedAnswer: 'SILVA',
);

const _playerB = LineupPlayer(
  id: 'b',
  position: 'ST',
  x: 0.5,
  y: 0.1,
  shirtNumber: 9,
  fullName: 'Jogador B Moura',
  displayName: 'Moura',
  puzzleAnswer: 'MOURA',
  answerParts: [5],
  normalizedAnswer: 'MOURA',
);

final _testMatch = LineupMatch(
  id: 'test-match',
  competition: 'Teste',
  season: '2024',
  phase: 'Final',
  date: DateTime(2024, 1, 1),
  homeTeam: 'Goiás',
  awayTeam: 'Adversário',
  homeScore: 1,
  awayScore: 0,
  teamToGuess: 'Goiás',
  formation: '4-4-2',
  formationConfidence: FormationConfidence.confirmed,
  players: const [_playerA, _playerB],
);

/// Storage falso em memória — evita depender de SharedPreferences real
/// nesses testes, e deixa explícito o que foi salvo em cada chamada.
class _FakeStorage {
  final Map<String, LineupGameState> _byMatchId = {};
  String? _selectedMatchId;
  int saveCalls = 0;

  Future<LineupGameState?> load(String matchId) async => _byMatchId[matchId];

  Future<void> save(LineupGameState state) async {
    saveCalls++;
    _byMatchId[state.matchId] = state;
  }

  Future<String?> loadSelectedMatchId() async => _selectedMatchId;

  Future<void> saveSelectedMatchId(String matchId) async =>
      _selectedMatchId = matchId;

  Future<Set<String>> completedIds() async => const {};
}

LineupCubit _buildCubit(_FakeStorage storage) {
  return LineupCubit(
    matches: [_testMatch],
    loadState: storage.load,
    saveState: storage.save,
    loadSelectedMatchId: storage.loadSelectedMatchId,
    saveSelectedMatchId: storage.saveSelectedMatchId,
    loadCompletedIds: storage.completedIds,
  )..loadSelectedMatch();
}

Future<void> _typeAndSubmit(LineupCubit cubit, String letters) async {
  for (final letter in letters.split('')) {
    cubit.addLetter(letter);
  }
  await cubit.submitGuess();
}

void main() {
  group('LineupCubit', () {
    test('carrega e inicia com progresso 0/2', () async {
      final cubit = _buildCubit(_FakeStorage());
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.solvedCount, 0);
      expect(cubit.state.totalPlayers, 2);
      await cubit.close();
    });

    test('addLetter/removeLetter só afetam o palpite em edição', () async {
      final cubit = _buildCubit(_FakeStorage());
      await Future<void>.delayed(Duration.zero);
      cubit.selectPlayer('a');

      cubit.addLetter('s');
      cubit.addLetter('i');
      expect(cubit.state.currentGuessLetters, ['S', 'I']);

      cubit.removeLetter();
      expect(cubit.state.currentGuessLetters, ['S']);
      await cubit.close();
    });

    test('addLetter não ultrapassa o tamanho da resposta', () async {
      final cubit = _buildCubit(_FakeStorage());
      await Future<void>.delayed(Duration.zero);
      cubit.selectPlayer('a'); // SILVA — 5 letras
      for (final letter in 'SILVAX'.split('')) {
        cubit.addLetter(letter);
      }
      expect(cubit.state.currentGuessLetters.length, 5);
      await cubit.close();
    });

    test('acertar marca solved e avança o progresso', () async {
      final cubit = _buildCubit(_FakeStorage());
      await Future<void>.delayed(Duration.zero);
      cubit.selectPlayer('a');

      await _typeAndSubmit(cubit, 'SILVA');

      expect(cubit.state.selectedPlayerState.solved, isTrue);
      expect(cubit.state.solvedCount, 1);
      await cubit.close();
    });

    test(
      'seis tentativas erradas marcam failed e revelam a resposta',
      () async {
        final cubit = _buildCubit(_FakeStorage());
        await Future<void>.delayed(Duration.zero);
        cubit.selectPlayer('a'); // SILVA

        for (var i = 0; i < 6; i++) {
          await _typeAndSubmit(cubit, 'ZZZZZ');
        }

        expect(cubit.state.selectedPlayerState.failed, isTrue);
        expect(cubit.state.selectedPlayerState.solved, isFalse);
        expect(cubit.state.selectedPlayerState.guesses.length, 6);
        await cubit.close();
      },
    );

    test('não aceita uma sétima tentativa depois de failed', () async {
      final cubit = _buildCubit(_FakeStorage());
      await Future<void>.delayed(Duration.zero);
      cubit.selectPlayer('a');
      for (var i = 0; i < 6; i++) {
        await _typeAndSubmit(cubit, 'ZZZZZ');
      }
      await _typeAndSubmit(cubit, 'SILVA');
      expect(cubit.state.selectedPlayerState.guesses.length, 6);
      expect(cubit.state.selectedPlayerState.solved, isFalse);
      await cubit.close();
    });

    test('estado de cada jogador é totalmente independente', () async {
      final cubit = _buildCubit(_FakeStorage());
      await Future<void>.delayed(Duration.zero);

      cubit.selectPlayer('a'); // SILVA
      await _typeAndSubmit(cubit, 'RATOS'); // R não existe em SILVA nem MOURA

      cubit.selectPlayer('b'); // MOURA
      // O R que ficou "absent" no jogador A não pode contaminar o teclado
      // do jogador B.
      expect(
        cubit.state.selectedPlayerState.keyboardState.containsKey('R'),
        isFalse,
      );
      expect(cubit.state.selectedPlayerState.guesses, isEmpty);
      await cubit.close();
    });

    test(
      'sair e reabrir o mesmo jogador preserva tentativas, teclado e contagem',
      () async {
        final cubit = _buildCubit(_FakeStorage());
        await Future<void>.delayed(Duration.zero);
        cubit.selectPlayer('a');
        await _typeAndSubmit(cubit, 'RATOS');
        await _typeAndSubmit(cubit, 'CARTA');

        cubit.closePlayer();
        expect(cubit.state.selectedPlayerId, isNull);

        cubit.selectPlayer('a');
        expect(cubit.state.selectedPlayerState.guesses.length, 2);
        expect(cubit.state.selectedPlayerState.keyboardState, isNotEmpty);
        await cubit.close();
      },
    );

    test(
      'progresso conta solved e completa 2/2 quando os dois terminam',
      () async {
        final cubit = _buildCubit(_FakeStorage());
        await Future<void>.delayed(Duration.zero);

        cubit.selectPlayer('a');
        await _typeAndSubmit(cubit, 'SILVA');
        expect(cubit.state.isComplete, isFalse);

        cubit.selectPlayer('b');
        await _typeAndSubmit(cubit, 'MOURA');

        expect(cubit.state.solvedCount, 2);
        expect(cubit.state.isComplete, isTrue);
        expect(cubit.state.game!.completedAt, isNotNull);
        await cubit.close();
      },
    );

    test(
      'desistir revela os jogadores restantes e marca surrendered',
      () async {
        final cubit = _buildCubit(_FakeStorage());
        await Future<void>.delayed(Duration.zero);

        cubit.selectPlayer('a');
        await _typeAndSubmit(
          cubit,
          'SILVA',
        ); // um já resolvido antes de desistir

        await cubit.giveUp();

        expect(cubit.state.game!.surrendered, isTrue);
        expect(
          cubit.state.game!.playerStates['a']!.solved,
          isTrue,
        ); // não sobrescreve o que já foi resolvido
        expect(cubit.state.game!.playerStates['b']!.failed, isTrue); // revelado
        expect(cubit.state.isComplete, isTrue);
        expect(cubit.state.selectedPlayerId, isNull);
        await cubit.close();
      },
    );

    test(
      'persiste a cada palpite enviado e restaura na próxima carga',
      () async {
        final storage = _FakeStorage();
        final cubit = _buildCubit(storage);
        await Future<void>.delayed(Duration.zero);
        cubit.selectPlayer('a');
        await _typeAndSubmit(cubit, 'SILVA');
        await cubit.close();

        expect(storage.saveCalls, greaterThan(0));

        final restored = _buildCubit(storage);
        await Future<void>.delayed(Duration.zero);
        expect(restored.state.game!.playerStates['a']!.solved, isTrue);
        await restored.close();
      },
    );
  });
}
