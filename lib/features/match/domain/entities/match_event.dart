import 'package:equatable/equatable.dart';

enum MatchEventType { goal, yellowCard, redCard, substitution, other }

enum MatchEventSide { home, away }

/// Um lance da partida — gol, cartão ou substituição — na ordem em que
/// aconteceu. `player` é quem marcou/recebeu o cartão/entrou em campo;
/// `detail` é informação extra (ex.: "Pênalti" num gol, ou quem saiu numa
/// substituição). Os dois são `null` quando não se aplicam ao tipo.
class MatchEvent extends Equatable {
  const MatchEvent({
    required this.minute,
    required this.side,
    required this.type,
    this.player,
    this.detail,
  });

  final String minute;
  final MatchEventSide side;
  final MatchEventType type;
  final String? player;
  final String? detail;

  @override
  List<Object?> get props => [minute, side, type, player, detail];
}
