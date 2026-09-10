import 'package:goias_app/features/match/domain/entities/competition_ref.dart';

/// Casa o nome cru de uma competição (o que vem por PARTIDA do OneFootball,
/// ex.: "Brasileirão Série B Superbet", com patrocinador) com o id de uma
/// competição do catálogo (nome limpo, ex.: "Brasileirão Série B") — usado
/// pra abrir a aba Jogos já na competição do PRÓXIMO JOGO (spec
/// multi-competição, item 1), sem exigir que os dois nomes sejam idênticos.
///
/// Normaliza os dois lados (minúsculo, sem acento, só letras/números/
/// espaço) e casa por contenção — nunca igualdade exata, já que o nome por
/// partida costuma vir com sufixo de patrocinador que o catálogo não tem.
/// Sem correspondência confiável -> `null`, nunca um chute.
class CompetitionAliasMatcher {
  const CompetitionAliasMatcher._();

  static String? matchId(String rawCompetitionName, List<CompetitionRef> catalog) {
    final normalizedRaw = _normalize(rawCompetitionName);
    if (normalizedRaw.isEmpty) return null;
    for (final competition in catalog) {
      final normalizedCatalog = _normalize(competition.name);
      if (normalizedCatalog.isEmpty) continue;
      if (normalizedRaw.contains(normalizedCatalog) ||
          normalizedCatalog.contains(normalizedRaw)) {
        return competition.id;
      }
    }
    return null;
  }

  static String _normalize(String input) {
    final withoutDiacritics = _stripDiacritics(input.toLowerCase());
    return withoutDiacritics
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const _withDiacritics = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  static const _withoutDiacritics = 'aaaaaeeeeiiiiooooouuuucn';

  static String _stripDiacritics(String input) {
    var result = input;
    for (var i = 0; i < _withDiacritics.length; i++) {
      result = result.replaceAll(_withDiacritics[i], _withoutDiacritics[i]);
    }
    return result;
  }
}
