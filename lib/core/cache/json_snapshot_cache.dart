import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Última resposta bem-sucedida de uma consulta de conteúdo público
/// (Diretoria, Transparência, Elenco...), guardada em `SharedPreferences`
/// pra a tela continuar útil sem rede. Guarda o JSON CRU devolvido pelo
/// backend — quem lê reaproveita o mesmo `fromJson` de sempre, então não
/// existe um segundo schema pra manter sincronizado.
///
/// Só para dado público do clube: nunca use pra dado privado de conta
/// (isso precisaria de isolamento por usuário e limpeza no logout).
class JsonSnapshotCache {
  const JsonSnapshotCache({this._preferences});

  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? await SharedPreferences.getInstance();

  /// Nunca lança — falha de armazenamento não pode derrubar uma consulta
  /// que acabou de dar certo.
  Future<void> write(String key, Object payload, {DateTime? now}) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(
        _storageKey(key),
        jsonEncode({
          'savedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
          'payload': payload,
        }),
      );
    } catch (_) {}
  }

  /// `null` quando nunca houve consulta bem-sucedida ou o registro está
  /// corrompido (descartado em vez de quebrar a tela).
  Future<CachedSnapshot?> read(String key) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_storageKey(key));
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.tryParse(decoded['savedAt'] as String? ?? '');
      final payload = decoded['payload'];
      if (savedAt == null || payload == null) return null;
      return CachedSnapshot(
        payload: payload as Object,
        savedAt: savedAt.toLocal(),
      );
    } catch (_) {
      return null;
    }
  }

  static String _storageKey(String key) => 'snapshot_cache:$key';
}

class CachedSnapshot {
  const CachedSnapshot({required this.payload, required this.savedAt});

  final Object payload;
  final DateTime savedAt;
}
