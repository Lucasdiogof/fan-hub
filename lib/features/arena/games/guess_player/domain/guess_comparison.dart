import 'package:goias_app/features/arena/games/guess_player/domain/guess_player.dart';
import 'package:goias_app/shared/domain/player_position.dart';

/// Resultado de uma comparação sem direção (POS/BASE): ou é o mesmo valor,
/// ou não é. `unknown` quando falta dado pra comparar (não conta como erro
/// nem acerto, só não dá pra saber).
enum MatchResult { match, mismatch, unknown }

/// Resultado de uma comparação com direção (CAMISA/ESTREIA): além de
/// igual/diferente, indica se o valor do jogador secreto é maior ou menor
/// que o do palpite.
enum DirectionalResult {
  match,

  /// O jogador secreto tem um valor MAIOR que o palpite (seta pra cima).
  higher,

  /// O jogador secreto tem um valor MENOR que o palpite (seta pra baixo).
  lower,
  unknown,
}

MatchResult comparePosition(PlayerPosition? secret, PlayerPosition? guess) {
  if (secret == null || guess == null) return MatchResult.unknown;
  return secret == guess ? MatchResult.match : MatchResult.mismatch;
}

DirectionalResult compareShirtNumber(int? secret, int? guess) {
  if (secret == null || guess == null) return DirectionalResult.unknown;
  if (secret == guess) return DirectionalResult.match;
  return guess < secret ? DirectionalResult.higher : DirectionalResult.lower;
}

MatchResult compareAcademy(String? secret, String? guess) {
  if (secret == null || guess == null) return MatchResult.unknown;
  return secret == guess ? MatchResult.match : MatchResult.mismatch;
}

DirectionalResult compareDebutYear(int? secret, int? guess) {
  if (secret == null || guess == null) return DirectionalResult.unknown;
  if (secret == guess) return DirectionalResult.match;
  return guess < secret ? DirectionalResult.higher : DirectionalResult.lower;
}

/// As 4 pistas de um palpite, já comparadas contra o jogador secreto.
class GuessComparisonResult {
  const GuessComparisonResult({
    required this.guessedPlayer,
    required this.position,
    required this.shirtNumber,
    required this.academy,
    required this.debutYear,
  });

  final GuessPlayer guessedPlayer;
  final MatchResult position;
  final DirectionalResult shirtNumber;
  final MatchResult academy;
  final DirectionalResult debutYear;
}

GuessComparisonResult compareGuess({
  required GuessPlayer secret,
  required GuessPlayer guess,
}) {
  return GuessComparisonResult(
    guessedPlayer: guess,
    position: comparePosition(secret.position, guess.position),
    shirtNumber: compareShirtNumber(secret.shirtNumber, guess.shirtNumber),
    academy: compareAcademy(secret.academyClub, guess.academyClub),
    debutYear: compareDebutYear(secret.clubDebutYear, guess.clubDebutYear),
  );
}
