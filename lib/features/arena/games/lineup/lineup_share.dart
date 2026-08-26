import 'package:goias_app/features/arena/games/lineup/cubit/lineup_state.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/l10n/app_localizations.dart';

/// Texto de resultado pra copiar/compartilhar — resumo em texto e uma
/// linha de quadradinhos por jogador (última tentativa enviada, ou ❌ se
/// não foi descoberto). Formato próprio, não uma cópia do Missing XI.
String buildLineupShareText(AppLocalizations l10n, LineupState state) {
  final match = state.match;
  final game = state.game;
  if (match == null || game == null) return '';

  final elapsed = state.elapsed ?? Duration.zero;
  final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

  final buffer = StringBuffer()
    ..writeln(
      '${l10n.arenaGameLineupTitle.toUpperCase()} — ${match.teamToGuess.toUpperCase()}',
    )
    ..writeln('${match.competition} · ${match.phase}')
    ..writeln(
      l10n.lineupShareStats(
        state.solvedCount,
        state.totalPlayers,
        state.totalAttempts,
        '$minutes:$seconds',
      ),
    )
    ..writeln();

  for (final player in match.players) {
    final playerState = game.playerStates[player.id];
    final numberLabel = (player.shirtNumber?.toString() ?? '—').padLeft(2);
    buffer.writeln('$numberLabel ${_playerLine(playerState)}');
  }

  return buffer.toString().trimRight();
}

String _playerLine(LineupPlayerState? playerState) {
  if (playerState == null || playerState.guesses.isEmpty) return '❌';
  if (playerState.failed && !playerState.solved) return '❌';
  final last = playerState.guesses.last;
  return last.statuses
      .map(
        (status) => switch (status) {
          LetterStatus.correct => '🟩',
          LetterStatus.present => '🟨',
          LetterStatus.absent => '⬛',
        },
      )
      .join();
}
