import 'package:goias_app/features/club/presentation/cubit/club_song_player_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lembra o volume escolhido pelo usuário entre músicas/sessões — sem isso
/// cada `ClubSongPlayerCubit` novo (uma instância por visita à página de
/// detalhes) sempre abriria em [kDefaultPlayerVolume], mesmo que o usuário
/// já tivesse ajustado a preferência dele há um minuto.
class ClubSongVolumeStore {
  static const _key = 'club_song_user_volume';

  Future<double> loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key) ?? kDefaultPlayerVolume;
  }

  Future<void> saveVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, value);
  }
}
