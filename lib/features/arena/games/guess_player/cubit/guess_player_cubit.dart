import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/arena/games/guess_player/cubit/guess_player_state.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_comparison.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_round_state.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/shared/state/load_status.dart';

class GuessPlayerCubit extends Cubit<GuessPlayerState> {
  GuessPlayerCubit({
    required this._catalog,
    required this._loadRound,
    required this._saveRound,
    required this._clearRound,
    required this._recordRoundResult,
    required this._ranking,
    required this._loadSeenIds,
    required this._addSeenId,
    required this._clearSeenIds,
    required this._loadSeenSignature,
    required this._saveSeenSignature,
  }) : super(const GuessPlayerState()) {
    _init();
  }

  final List<GuessPlayer> _catalog;

  List<GuessPlayer> get catalog => _catalog;
  final Future<GuessPlayerRoundState?> Function() _loadRound;
  final Future<void> Function(GuessPlayerRoundState state) _saveRound;
  final Future<void> Function() _clearRound;
  final Future<void> Function({required bool won}) _recordRoundResult;
  final ArenaRankingRepository _ranking;
  final Future<Set<String>> Function() _loadSeenIds;
  final Future<void> Function(String id) _addSeenId;
  final Future<void> Function() _clearSeenIds;
  final Future<String?> Function() _loadSeenSignature;
  final Future<void> Function(String signature) _saveSeenSignature;
  final _random = Random();
  Set<String> _seenIds = {};

  List<GuessPlayer> get _eligibleSecrets => _catalog
      .where((player) => player.eligibleAsSecret)
      .toList(growable: false);

  /// Se vazio, `nextPlayer()` só levaria pro estado vazio de novo — a tela
  /// usa isso pra decidir entre oferecer "Próximo Jogador" ou "Voltar" no
  /// fim da rodada.
  bool get hasEligibleSecret => _eligibleSecrets.isNotEmpty;

  GuessPlayer? _byId(String id) {
    for (final player in _catalog) {
      if (player.id == id) return player;
    }
    return null;
  }

  Future<void> _init() async {
    emit(state.copyWith(status: LoadStatus.loading));
    _seenIds = await _loadSeenIds();
    await _resetSeenIfCatalogChanged();
    final savedRound = await _loadRound();
    final secret = savedRound == null ? null : _byId(savedRound.secretPlayerId);

    if (savedRound != null && secret != null) {
      _emitRound(savedRound, secret);
      return;
    }

    await _startNewRound();
  }

  /// "Visto" é por id, então jogadores novos no catálogo sempre nascem
  /// como não-vistos — sem isso, logo depois de adicionar um lote de
  /// jogadores o sorteio fica enviesado pros recém-adicionados até o
  /// baralho inteiro ser visto de novo (o resto já estava marcado como
  /// visto de antes). Comparando a assinatura do catálogo elegível com a
  /// última vez que os "vistos" foram montados, detecta esse caso e
  /// embaralha tudo de novo — reseta os vistos, não o catálogo em si.
  Future<void> _resetSeenIfCatalogChanged() async {
    final signature = (_eligibleSecrets.map((p) => p.id).toList()..sort()).join(
      ',',
    );
    final lastSignature = await _loadSeenSignature();
    if (lastSignature != null && lastSignature != signature) {
      _seenIds = {};
      await _clearSeenIds();
    }
    if (lastSignature != signature) {
      await _saveSeenSignature(signature);
    }
  }

  Future<void> _startNewRound() async {
    final pool = _eligibleSecrets;
    if (pool.isEmpty) {
      emit(state.copyWith(status: LoadStatus.empty));
      return;
    }

    var unseen = pool.where((p) => !_seenIds.contains(p.id)).toList();
    if (unseen.isEmpty) {
      await _clearSeenIds();
      _seenIds = {};
      unseen = pool;
    }

    final secret = unseen[_random.nextInt(unseen.length)];
    _seenIds.add(secret.id);
    await _addSeenId(secret.id);

    final round = GuessPlayerRoundState(secretPlayerId: secret.id);
    await _saveRound(round);
    _emitRound(round, secret);
  }

  void _emitRound(GuessPlayerRoundState round, GuessPlayer secret) {
    final comparisons = [
      for (final id in round.guessedPlayerIds)
        if (_byId(id) case final guess?)
          compareGuess(secret: secret, guess: guess),
    ];
    emit(
      state.copyWith(
        status: LoadStatus.success,
        secretPlayer: secret,
        round: round,
        comparisons: comparisons,
      ),
    );
  }

  Future<void> submitGuess(GuessPlayer guess) async {
    final round = state.round;
    final secret = state.secretPlayer;
    if (round == null || secret == null || round.isOver) return;

    final guessedIds = [...round.guessedPlayerIds, guess.id];
    final won = guess.id == secret.id;
    final lost = !won && guessedIds.length >= maxGuessAttempts;
    final updated = round.copyWith(
      guessedPlayerIds: guessedIds,
      won: won,
      lost: lost,
    );

    if (updated.isOver) {
      await _clearRound();
      await _recordRoundResult(won: updated.won);
      unawaited(
        _ranking.recordScore(
          gameId: ArenaGameIds.guessPlayer,
          itemId: secret.id,
          eventType: won
              ? (updated.attemptsUsed == 1
                    ? 'first_try_correct'
                    : 'correct_after_errors')
              : 'attempts_exhausted',
          attemptNumber: won ? updated.attemptsUsed : null,
          wasRevealed: !won,
        ),
      );
    } else {
      await _saveRound(updated);
    }
    _emitRound(updated, secret);
  }

  Future<void> nextPlayer() async {
    await _clearRound();
    await _startNewRound();
  }
}
