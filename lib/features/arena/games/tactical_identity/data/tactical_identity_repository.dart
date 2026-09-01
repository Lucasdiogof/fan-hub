import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// Guarda só o ÚLTIMO resultado do usuário (uma linha por conta, upsert) —
/// nunca um histórico. A falha desta persistência nunca pode travar o jogo:
/// o resultado já foi calculado localmente e mostrado ANTES de qualquer
/// chamada daqui (ver `TacticalIdentityResultPage`).
abstract interface class TacticalIdentityRepository {
  Future<void> saveResult(TacticalIdentityResult result);

  /// `null` quando o usuário nunca completou o jogo.
  Future<TacticalIdentityResult?> loadLatestResult();
}
