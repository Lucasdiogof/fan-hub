import 'package:equatable/equatable.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/shared/state/load_status.dart';

class RankingState extends Equatable {
  const RankingState({
    this.status = LoadStatus.initial,
    this.period = RankingPeriod.allTime,
    this.entries = const [],
    this.myRank,
  });

  final LoadStatus status;
  final RankingPeriod period;
  final List<RankingEntry> entries;

  /// `null` quando o usuário ainda não pontuou nada no período selecionado.
  final ({int rank, int totalScore})? myRank;

  /// O card fixo "Sua posição" só aparece quando o usuário pontuou mas não
  /// está entre as linhas já carregadas — se ele já aparece na lista, o
  /// card seria uma repetição.
  bool get showPinnedPosition => myRank != null && !entries.any((e) => e.isMe);

  RankingState copyWith({
    LoadStatus? status,
    RankingPeriod? period,
    List<RankingEntry>? entries,
    ({int rank, int totalScore})? myRank,
    bool clearMyRank = false,
  }) {
    return RankingState(
      status: status ?? this.status,
      period: period ?? this.period,
      entries: entries ?? this.entries,
      myRank: clearMyRank ? null : (myRank ?? this.myRank),
    );
  }

  @override
  List<Object?> get props => [status, period, entries, myRank];
}
