import 'package:goias_app/features/match/domain/entities/lineup.dart';

class LineupPlayerDto {
  const LineupPlayerDto({
    required this.name,
    required this.jerseyNumber,
    required this.photo,
    this.playerId,
  });

  final String name;
  final int jerseyNumber;
  final String photo;

  /// `playerId` é a fonte CANÔNICA da identidade: vem do Worker (link do
  /// jogador no OneFootball). Quando o Worker publicado ainda não o manda,
  /// vale o LEGACY FALLBACK [providerIdFromPhoto] — compatibilidade temporária
  /// de deploy, nunca a identidade primária (URL de imagem não é identidade).
  final int? playerId;

  factory LineupPlayerDto.fromJson(Map<String, dynamic> json) {
    final photo = json['photo'] as String? ?? '';
    return LineupPlayerDto(
      name: json['name'] as String? ?? '',
      jerseyNumber: json['jerseyNumber'] as int? ?? 0,
      photo: photo,
      // Payload novo: só `playerId` (a foto nem é lida). Payload antigo: legacy.
      playerId:
          (json['playerId'] as num?)?.toInt() ?? providerIdFromPhoto(photo),
    );
  }

  /// LEGACY FALLBACK — remover depois que o Worker com `playerId` estiver
  /// publicado em todos os ambientes.
  /// `https://images.onefootball.com/players/180/48597.jpg` -> `48597`. Só
  /// reconhece o padrão de foto de JOGADOR do provedor; qualquer outra coisa
  /// (vazio, outro host, silhueta removida pelo Worker) devolve `null`.
  static int? providerIdFromPhoto(String photo) {
    final match = _playerPhoto.firstMatch(photo);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static final _playerPhoto = RegExp(
    r'^https://images\.onefootball\.com/players/\d+/(\d+)\.(?:jpe?g|png|webp)$',
  );

  LineupPlayer toEntity() {
    return LineupPlayer(
      name: name,
      jerseyNumber: jerseyNumber,
      photo: photo,
      providerPlayerId: playerId,
    );
  }
}

class TeamLineupDto {
  const TeamLineupDto({required this.teamName, required this.rows});

  final String teamName;
  final List<List<LineupPlayerDto>> rows;

  factory TeamLineupDto.fromJson(Map<String, dynamic> json) {
    final rawRows = (json['rows'] as List?) ?? [];
    return TeamLineupDto(
      teamName: json['teamName'] as String? ?? '',
      rows: rawRows
          .map(
            (row) => ((row as List?) ?? [])
                .map((p) => LineupPlayerDto.fromJson(p as Map<String, dynamic>))
                .toList(),
          )
          .toList(),
    );
  }

  TeamLineup toEntity() {
    return TeamLineup(
      teamName: teamName,
      rows: rows.map((row) => row.map((p) => p.toEntity()).toList()).toList(),
    );
  }
}

class MatchLineupsDto {
  const MatchLineupsDto({required this.home, required this.away});

  final TeamLineupDto home;
  final TeamLineupDto away;

  factory MatchLineupsDto.fromJson(Map<String, dynamic> json) {
    return MatchLineupsDto(
      home: TeamLineupDto.fromJson(json['home'] as Map<String, dynamic>),
      away: TeamLineupDto.fromJson(json['away'] as Map<String, dynamic>),
    );
  }

  MatchLineups toEntity() {
    return MatchLineups(home: home.toEntity(), away: away.toEntity());
  }
}
