import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';

/// Rótulo em português de cada dimensão — usado em toda a UI do jogo
/// (barras, marcas, bottom sheet de referência, card compartilhável).
/// Português puro, sem l10n, mesma convenção do resto do conteúdo editorial
/// deste jogo.
extension PlayerIdentityDimensionLabel on PlayerIdentityDimension {
  String get label => switch (this) {
    PlayerIdentityDimension.creativity => 'Criatividade',
    PlayerIdentityDimension.definition => 'Definição',
    PlayerIdentityDimension.leadership => 'Liderança',
    PlayerIdentityDimension.intensity => 'Intensidade',
    PlayerIdentityDimension.technique => 'Técnica',
    PlayerIdentityDimension.tactics => 'Tática',
  };
}
