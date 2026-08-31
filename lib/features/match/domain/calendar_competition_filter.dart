/// Filtro de competição do Calendário — puramente sobre o texto que a
/// própria partida já carrega (`Match.competition`), nunca um código
/// separado por partida (a fonte não dá isso pra temporada inteira, só o
/// nome). `outros` pega qualquer competição que não bata com as 3
/// nomeadas — nunca lista vazia por falta de categoria.
enum CalendarCompetitionFilter {
  all,
  brasileirao,
  copaDoBrasil,
  goiano,
  outros,
}

CalendarCompetitionFilter classifyCompetition(String competitionName) {
  final lower = competitionName.toLowerCase();
  if (lower.contains('brasileir')) return CalendarCompetitionFilter.brasileirao;
  // Nunca `contains('copa do brasil')` direto: o nome real vem com
  // patrocinador no meio (confirmado contra a API: "Copa Betano do
  // Brasil") — checar as duas palavras separadas cobre isso sem never
  // colidir com "Brasileirão" (checado antes) nem com "Copa Verde" (tem
  // "copa" mas não "brasil").
  if (lower.contains('copa') && lower.contains('brasil')) {
    return CalendarCompetitionFilter.copaDoBrasil;
  }
  if (lower.contains('goian')) return CalendarCompetitionFilter.goiano;
  return CalendarCompetitionFilter.outros;
}

bool matchesCompetitionFilter(
  CalendarCompetitionFilter filter,
  String competitionName,
) {
  return filter == CalendarCompetitionFilter.all ||
      classifyCompetition(competitionName) == filter;
}
