import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Team extends Equatable {
  const Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
    this.logoUrl,
    this.crestAsset,
  });

  /// ID do time na fonte de dado ao vivo (OneFootball).
  final int id;
  final String name;
  final String shortName;

  /// Cor de fallback usada no badge desenhado quando não há [logoUrl]. A
  /// API-Football não fornece cor de time — isso é só um ajuste visual local.
  final Color color;

  /// Escudo oficial vindo da API-Football (rede).
  final String? logoUrl;

  /// Vetor local — usado só para a marca do próprio Goiás fora do contexto
  /// de partidas (header/banner da Home), não relacionado a `logoUrl`.
  final String? crestAsset;

  /// `1863` é o id do Goiás no OneFootball — o mesmo número do slug
  /// `goias-1863` (`GOIAS_ONEFOOTBALL_SLUG` no `wrangler.toml`), extraído
  /// pelo Worker direto da URL do escudo/path do time (ver
  /// `extractTeamIdFromCrest`/`extractTeamIdFromPath` em
  /// `src/football/normalize/*.ts`) — o mesmo padrão que as standings já
  /// usam pra decidir `isGoias` no backend. Nome só entra como fallback
  /// defensivo (cobre `MockData`/id ausente), nunca como regra principal.
  static const int goiasId = 1863;

  bool get isGoias => id == goiasId || name.toLowerCase().contains('goi');

  @override
  List<Object?> get props => [id, name, shortName, color, logoUrl, crestAsset];
}
