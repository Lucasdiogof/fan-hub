import 'package:equatable/equatable.dart';

enum MatchStatUnit { percent, count }

/// Uma estatística comparativa da partida (posse de bola, chutes, disputas
/// ganhas...). `home`/`away` ficam `null` quando a fonte ainda não tem esse
/// dado pra essa partida (comum bem no início do jogo) — nunca um 0
/// inventado.
class MatchStat extends Equatable {
  const MatchStat({
    required this.title,
    required this.unit,
    this.home,
    this.away,
  });

  final String title;
  final MatchStatUnit unit;
  final num? home;
  final num? away;

  bool get hasValues => home != null && away != null;

  @override
  List<Object?> get props => [title, unit, home, away];
}
