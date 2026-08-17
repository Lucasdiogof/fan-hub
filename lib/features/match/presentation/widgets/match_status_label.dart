import 'package:goias_app/features/match/domain/entities/match.dart';

String matchStatusLabel(MatchStatus status) => switch (status) {
  MatchStatus.scheduled => 'Agendada',
  MatchStatus.live => 'Ao vivo',
  MatchStatus.halftime => 'Intervalo',
  MatchStatus.finished => 'Encerrada',
  MatchStatus.postponed => 'Adiada',
  MatchStatus.cancelled => 'Cancelada',
  MatchStatus.suspended => 'Suspensa',
  MatchStatus.unknown => 'Indefinido',
};
