import 'package:equatable/equatable.dart';

/// KNOCKOUT: competição só de mata-mata (Copa do Brasil) — sem renderer
/// próprio ainda no app (Fase C da rearquitetura multi-competição); a tela
/// mostra o estado de "ainda não disponível" (`dataGap`), nunca inventa
/// bracket.
enum CompetitionFormat { leagueTable, groupStage, knockout }

/// Uma competição do catálogo GLOBAL (ver `/api/football/competitions`) —
/// NUNCA só as que o clube ativo disputa (spec multi-competição, item 3:
/// "competição do clube ≠ únicas opções disponíveis"). [isClubParticipating]
/// é a única coisa específica do clube ativo: decide destaque/linha
/// marcada, nunca se a competição pode ser consultada.
class CompetitionRef extends Equatable {
  const CompetitionRef({
    required this.id,
    required this.name,
    required this.format,
    this.region = '',
    this.isClubParticipating = false,
    this.logoUrl,
  });

  final String id;
  final String name;
  final CompetitionFormat format;
  final String region;
  final bool isClubParticipating;

  /// Escudo da própria competição — só vem populado quando esta ref nasceu
  /// da resposta de `/standings` (que tem o dado real do OneFootball);
  /// refs do catálogo estático (`getCompetitions`) nunca têm.
  final String? logoUrl;

  @override
  List<Object?> get props => [
    id,
    name,
    format,
    region,
    isClubParticipating,
    logoUrl,
  ];
}
