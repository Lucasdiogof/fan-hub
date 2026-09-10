import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_scoped_storage_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferência manual de competição na aba Classificação, só neste
/// aparelho — namespaçada por clube (Parte 3 da spec de multi-competição:
/// "preferência isolada por clube", nunca compartilhada entre Goiás e
/// Bragantino no mesmo device). Feature nova (2026-09-09), sem chave
/// legacy pra migrar.
class SelectedCompetitionStorage {
  SelectedCompetitionStorage(this._clubConfig);

  static const _key = 'games_selected_competition_id';

  final ClubConfig _clubConfig;

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ClubScopedStorageKey(_clubConfig).scoped(_key));
  }

  Future<void> save(String competitionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      ClubScopedStorageKey(_clubConfig).scoped(_key),
      competitionId,
    );
  }
}
