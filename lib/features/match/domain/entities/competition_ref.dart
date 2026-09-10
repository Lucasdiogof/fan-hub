import 'package:equatable/equatable.dart';

/// Só os formatos com dado real confirmado (auditoria multi-competição
/// 2026-09-09) — nunca um enum "genérico" pra formato sem uma fonte real
/// por trás. Mata-mata/híbrido ficam de fora de propósito: a única
/// competição com fase eliminatória hoje (CONMEBOL Sudamericana do
/// Bragantino) não tem fonte de confronto/chaveamento disponível, então a
/// tela mostra só a fase de grupos, nunca inventa bracket.
enum CompetitionFormat { leagueTable, groupStage }

/// Uma competição que o clube ativo disputa e pode ser escolhida no
/// seletor de Classificação — sempre a principal (`isPrimary: true`) mais
/// qualquer secundária configurada no Worker (`SECONDARY_COMPETITIONS`).
/// Nunca inventado no cliente: a lista inteira vem de `/api/football/
/// competitions`.
class CompetitionRef extends Equatable {
  const CompetitionRef({
    required this.id,
    required this.name,
    required this.format,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final CompetitionFormat format;
  final bool isPrimary;

  @override
  List<Object?> get props => [id, name, format, isPrimary];
}
