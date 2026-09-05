import 'package:goias_app/features/club/domain/entities/club_timeline_event.dart';

const _sourceName = 'Red Bull Bragantino';
const _sourceUrl = 'https://www.redbullbragantino.com/br-pt/historia';

/// Mesmos marcos de [BragantinoHistoryData], em formato de linha do tempo.
class BragantinoTimelineData {
  const BragantinoTimelineData._();

  static const List<ClubTimelineEvent> events = [
    ClubTimelineEvent(
      year: 1928,
      title: 'Fundação do Clube Atlético Bragantino',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1931,
      title: 'Taça Raul Leme e nascimento do apelido "Massa Bruta"',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1965,
      title: 'Acesso à elite do Campeonato Paulista',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1989,
      title: 'Primeiro título da Série B do Brasileiro',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1990,
      title: 'Título do Campeonato Paulista',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 1991,
      title: 'Vice-campeonato do Campeonato Brasileiro',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2007,
      title: 'Título da Série C do Campeonato Brasileiro',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2019,
      title: 'Parceria com a Red Bull e novo título da Série B',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2021,
      title: 'Vice-campeonato da Copa Sul-Americana',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
    ClubTimelineEvent(
      year: 2022,
      title: 'Estreia na fase de grupos da Copa Libertadores',
      sourceName: _sourceName,
      sourceUrl: _sourceUrl,
    ),
  ];
}
