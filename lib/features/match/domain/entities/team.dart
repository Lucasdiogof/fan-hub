import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';

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

  /// Compara este time contra o clube ATIVO (via `ClubConfig.integrations.
  /// oneFootballTeamId`) — nunca contra um id/nome hardcoded de um clube
  /// específico (M3.3: substitui o antigo `Team.isGoias`/`Team.goiasId`).
  /// Pura — recebe o config de fora, nunca resolve `GetIt` internamente
  /// (entity não deve depender de DI).
  bool matchesClub(ClubConfig config) =>
      id == config.integrations.oneFootballTeamId;

  @override
  List<Object?> get props => [id, name, shortName, color, logoUrl, crestAsset];
}
