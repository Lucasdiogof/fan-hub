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

  /// ID oficial do time na API-Football. Usar sempre esse campo pra
  /// identificar o Goiás (`team.id == goiasTeamId`) — nunca comparar nome.
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

  @override
  List<Object?> get props => [id, name, shortName, color, logoUrl, crestAsset];
}
