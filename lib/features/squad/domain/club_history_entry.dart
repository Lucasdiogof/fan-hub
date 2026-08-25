class ClubHistoryEntry {
  const ClubHistoryEntry({
    required this.period,
    required this.team,
    this.appearances,
    this.goals,
    this.loan = false,
    this.isGoias = false,
    this.dataQuality = 'verified',
    this.notes,
  });

  final String period;
  final String team;
  final int? appearances;
  final int? goals;
  final bool loan;
  final bool isGoias;

  /// 'verified' | 'partial' | 'review' — vem direto da fonte de dados; nunca
  /// inferido. 'partial' = falta algum total; 'review' = fonte teve alguma
  /// divergência/anomalia e o dado não deve ser tratado como definitivo.
  final String dataQuality;
  final String? notes;

  factory ClubHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ClubHistoryEntry(
      period: json['period'] as String,
      team: json['team'] as String,
      appearances: json['appearances'] as int?,
      goals: json['goals'] as int?,
      loan: json['loan'] as bool? ?? false,
      isGoias: json['is_goias'] as bool? ?? false,
      dataQuality: json['data_quality'] as String? ?? 'verified',
      notes: json['notes'] as String?,
    );
  }
}
