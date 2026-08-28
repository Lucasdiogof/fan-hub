import 'package:equatable/equatable.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/shared/state/load_status.dart';

enum PassportFilter { all, attended, notAttended, home, away }

class PassportState extends Equatable {
  const PassportState({
    this.seasonsStatus = LoadStatus.initial,
    this.seasons = const [],
    this.selectedYear,
    this.matchesStatus = LoadStatus.initial,
    this.matches = const [],
    this.matchesErrorMessage,
    this.pendingChanges = const {},
    this.filter = PassportFilter.all,
    this.competitionFilter,
    this.summary = PassportSummary.empty,
    this.saveStatus = LoadStatus.initial,
    this.saveErrorMessage,
  });

  final LoadStatus seasonsStatus;
  final List<PassportSeason> seasons;
  final int? selectedYear;
  final LoadStatus matchesStatus;
  final List<PassportMatch> matches;
  final String? matchesErrorMessage;

  /// matchId -> novo valor de presença, só pras que diferem do que já está
  /// salvo no servidor. Sobrevive à troca de ano — o usuário pode marcar
  /// partidas de anos diferentes antes de salvar tudo de uma vez.
  final Map<String, bool> pendingChanges;
  final PassportFilter filter;

  /// Filtro adicional e independente do [filter] principal — combina com
  /// ele (ex.: "Casa" + "Campeonato Goiano" ao mesmo tempo). `null` = todas
  /// as competições.
  final String? competitionFilter;
  final PassportSummary summary;
  final LoadStatus saveStatus;
  final String? saveErrorMessage;

  bool get hasUnsavedChanges => pendingChanges.isNotEmpty;
  int get pendingChangeCount => pendingChanges.length;

  bool effectiveAttended(PassportMatch match) =>
      pendingChanges[match.id] ?? match.attended;

  List<String> get availableCompetitions =>
      matches.map((m) => m.competitionCode).toSet().toList(growable: false)
        ..sort();

  List<PassportMatch> get filteredMatches {
    return matches.where((match) {
      if (competitionFilter != null &&
          match.competitionCode != competitionFilter) {
        return false;
      }
      switch (filter) {
        case PassportFilter.all:
          return true;
        case PassportFilter.attended:
          return effectiveAttended(match);
        case PassportFilter.notAttended:
          return !effectiveAttended(match);
        case PassportFilter.home:
          return match.goiasIsHome == true;
        case PassportFilter.away:
          return match.goiasIsHome == false;
      }
    }).toList(growable: false);
  }

  int get yearFinishedCount =>
      matches.where((m) => m.isFinished).length;

  int get yearMarkedCount =>
      matches.where((m) => m.isFinished && effectiveAttended(m)).length;

  PassportState copyWith({
    LoadStatus? seasonsStatus,
    List<PassportSeason>? seasons,
    int? Function()? selectedYear,
    LoadStatus? matchesStatus,
    List<PassportMatch>? matches,
    String? Function()? matchesErrorMessage,
    Map<String, bool>? pendingChanges,
    PassportFilter? filter,
    String? Function()? competitionFilter,
    PassportSummary? summary,
    LoadStatus? saveStatus,
    String? Function()? saveErrorMessage,
  }) {
    return PassportState(
      seasonsStatus: seasonsStatus ?? this.seasonsStatus,
      seasons: seasons ?? this.seasons,
      selectedYear: selectedYear != null ? selectedYear() : this.selectedYear,
      matchesStatus: matchesStatus ?? this.matchesStatus,
      matches: matches ?? this.matches,
      matchesErrorMessage: matchesErrorMessage != null
          ? matchesErrorMessage()
          : this.matchesErrorMessage,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      filter: filter ?? this.filter,
      competitionFilter: competitionFilter != null
          ? competitionFilter()
          : this.competitionFilter,
      summary: summary ?? this.summary,
      saveStatus: saveStatus ?? this.saveStatus,
      saveErrorMessage: saveErrorMessage != null
          ? saveErrorMessage()
          : this.saveErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    seasonsStatus,
    seasons,
    selectedYear,
    matchesStatus,
    matches,
    matchesErrorMessage,
    pendingChanges,
    filter,
    competitionFilter,
    summary,
    saveStatus,
    saveErrorMessage,
  ];
}
