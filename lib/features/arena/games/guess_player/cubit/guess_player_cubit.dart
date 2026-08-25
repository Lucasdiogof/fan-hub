import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/arena/games/guess_player/cubit/guess_player_state.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_comparison.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/features/arena/games/guess_player/domain/guess_round_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class GuessPlayerCubit extends Cubit<GuessPlayerState> {
  GuessPlayerCubit({
    required this._catalog,
    required this._loadRound,
    required this._saveRound,
    required this._clearRound,
  }) : super(const GuessPlayerState()) {
    _init();
  }

  final List<GuessPlayer> _catalog;
  final Future<GuessPlayerRoundState?> Function() _loadRound;
  final Future<void> Function(GuessPlayerRoundState state) _saveRound;
  final Future<void> Function() _clearRound;
  final _random = Random();
  String? _lastSecretId;

  List<GuessPlayer> get _eligibleSecrets => _catalog
      .where((player) => player.eligibleAsSecret)
      .toList(growable: false);

  GuessPlayer? _byId(String id) {
    for (final player in _catalog) {
      if (player.id == id) return player;
    }
    return null;
  }

  Future<void> _init() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final savedRound = await _loadRound();
    final secret = savedRound == null ? null : _byId(savedRound.secretPlayerId);

    if (savedRound != null && secret != null) {
      _emitRound(savedRound, secret);
      return;
    }

    await _startNewRound();
  }

  Future<void> _startNewRound() async {
    final pool = _eligibleSecrets;
    if (pool.isEmpty) {
      emit(state.copyWith(status: LoadStatus.empty));
      return;
    }
    GuessPlayer secret;
    if (pool.length == 1) {
      secret = pool.first;
    } else {
      do {
        secret = pool[_random.nextInt(pool.length)];
      } while (secret.id == _lastSecretId);
    }
    _lastSecretId = secret.id;

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
