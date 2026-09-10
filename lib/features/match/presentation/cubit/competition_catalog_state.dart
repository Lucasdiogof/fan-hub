import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/competition_ref.dart';
import 'package:goias_app/shared/state/load_status.dart';

class CompetitionCatalogState extends Equatable {
  const CompetitionCatalogState({
    this.status = LoadStatus.initial,
    this.competitions = const [],
    this.query = '',
    this.errorMessage,
  });

  final LoadStatus status;
  final List<CompetitionRef> competitions;
  final String query;
  final String? errorMessage;

  List<CompetitionRef> get yours =>
      _filtered.where((c) => c.isClubParticipating).toList();

  /// Agrupado por região, na ordem em que cada região aparece pela primeira
  /// vez no catálogo — nunca alfabética (o Worker já manda "Brasil" antes
  /// de "Europa" de propósito, ver `competition_catalog.ts`).
  Map<String, List<CompetitionRef>> get othersByRegion {
    final others = _filtered.where((c) => !c.isClubParticipating);
    final grouped = <String, List<CompetitionRef>>{};
    for (final competition in others) {
      grouped.putIfAbsent(competition.region, () => []).add(competition);
    }
    return grouped;
  }

  List<CompetitionRef> get _filtered {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return competitions;
    return competitions
        .where((c) => c.name.toLowerCase().contains(normalized))
        .toList();
  }

  CompetitionCatalogState copyWith({
    LoadStatus? status,
    List<CompetitionRef>? competitions,
    String? query,
    String? errorMessage,
  }) {
    return CompetitionCatalogState(
      status: status ?? this.status,
      competitions: competitions ?? this.competitions,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, competitions, query, errorMessage];
}
