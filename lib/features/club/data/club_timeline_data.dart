import 'package:goias_app/features/club/domain/entities/club_timeline_event.dart';

const _sourceName = 'Goiás Esporte Clube';
const _sourceUrl = 'https://www.goiasec.com.br/historia';

/// Mesmos marcos de [ClubHistoryData], em formato de linha do tempo.
class ClubTimelineData {
  const ClubTimelineData._();

  static const List<ClubTimelineEvent> events = [
    ClubTimelineEvent(
      year: 1943,
      title: 'Fundação do Goiás',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1960,
      title: 'Aquisição da área da Serrinha',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1966,
      title: 'Primeiro Campeonato Goiano',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1973,
      title: 'Estreia no Campeonato Brasileiro',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1990,
      title: 'Final da Copa do Brasil',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1995,
      title: 'Inauguração do Estádio Hailé Pinheiro',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1997,
      title: 'Clube dos 13',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1999,
      title: 'Campeão Brasileiro Série B',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2000,
      title: 'Copa Centro-Oeste',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2001,
      title: 'Copa Centro-Oeste',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2002,
      title: 'Copa Centro-Oeste',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2005,
      title: '3º lugar no Campeonato Brasileiro',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2006,
      title: 'Libertadores',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2010,
      title: 'Final da Sul-Americana',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2012,
      title: 'Bicampeão Brasileiro Série B',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2023,
      title: 'Campeão da Copa Verde',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
  ];
}
