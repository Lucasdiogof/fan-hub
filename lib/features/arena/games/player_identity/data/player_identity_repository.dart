import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';

/// Guarda só o ÚLTIMO resultado do usuário (uma linha por conta, upsert) —
/// nunca um histórico. A falha desta persistência nunca pode travar o jogo:
/// o resultado já foi calculado localmente e mostrado ANTES de qualquer
/// chamada daqui (ver `PlayerIdentityResultPage`).
abstract interface class PlayerIdentityRepository {
  Future<void> saveResult(PlayerIdentityResult result);

  /// `null` quando o usuário nunca completou o jogo.
  Future<PlayerIdentityResult?> loadLatestResult();
}
