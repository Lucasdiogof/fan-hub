import 'dart:convert';

import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CareerPathStorage {
  static const _prefix = 'career_path_round_';
  static const _selectedKey = 'career_path_selected_player_id';

  Future<CareerRoundState?> load(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$playerId');
    if (raw == null) return null;
    try {
      return CareerRoundState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CareerRoundState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix${state.playerId}', jsonEncode(state.toJson()));
  }

  Future<String?> loadSelectedPlayerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedKey);
  }

  Future<void> saveSelectedPlayerId(String playerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, playerId);
  }
}
