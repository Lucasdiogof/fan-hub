import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/career_players.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Banco de jogadores do Adivinhe o Jogador. Fonte da verdade é o Supabase
/// (editável sem republicar o app); o const `careerPlayers` fica como
/// fallback offline / tabela vazia, pro jogo nunca ficar sem jogadores.
class CareerPlayerRepository {
  CareerPlayerRepository(this._client);

  final SupabaseClient _client;

  Future<List<CareerPlayer>> load() async {
    try {
      final rows = await _client
          .from('career_players')
          .select(
            'id, answer, accepted_answers, position, club_career, national_teams',
          )
          .eq('is_active', true)
          .order('sort_order');
      final parsed = <CareerPlayer>[];
      for (final row in rows) {
        final player = _map(row);
        if (player != null) parsed.add(player);
      }
      return parsed.isEmpty ? careerPlayers : parsed;
    } catch (_) {
      return careerPlayers;
    }
  }

  CareerPlayer? _map(Map<String, dynamic> row) {
    final id = row['id'] as String?;
    final answer = row['answer'] as String?;
    final clubCareerRaw = row['club_career'] as List?;
    if (id == null || answer == null || clubCareerRaw == null) return null;

    final clubCareer = clubCareerRaw
        .map((e) => _mapEntry(e as Map<String, dynamic>))
        .whereType<CareerEntry>()
        .toList();
    if (clubCareer.isEmpty) return null;

    final nationalTeams = ((row['national_teams'] as List?) ?? [])
        .map((e) => _mapEntry(e as Map<String, dynamic>))
        .whereType<CareerEntry>()
        .toList();

    final acceptedAnswers = ((row['accepted_answers'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    return CareerPlayer(
      id: id,
      answer: answer,
      acceptedAnswers: acceptedAnswers.isEmpty ? [answer] : acceptedAnswers,
      position: row['position'] as String?,
      clubCareer: clubCareer,
      nationalTeams: nationalTeams,
    );
  }

  CareerEntry? _mapEntry(Map<String, dynamic> json) {
    final period = json['period'] as String?;
    final team = json['team'] as String?;
    if (period == null || team == null) return null;
    return CareerEntry(
      period: period,
      team: team,
      appearances: (json['appearances'] as num?)?.toInt(),
      goals: (json['goals'] as num?)?.toInt(),
      loan: json['loan'] as bool? ?? false,
      isGoias: json['is_goias'] as bool? ?? false,
    );
  }
}
