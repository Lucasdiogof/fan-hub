import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/domain/calendar_competition_filter.dart';

void main() {
  group('classifyCompetition', () {
    test('reconhece Brasileirão mesmo com patrocinador no nome', () {
      expect(
        classifyCompetition('Brasileirão Série B Superbet'),
        CalendarCompetitionFilter.brasileirao,
      );
    });

    test('reconhece Copa do Brasil mesmo com patrocinador no nome', () {
      expect(
        classifyCompetition('Copa Betano do Brasil'),
        CalendarCompetitionFilter.copaDoBrasil,
      );
    });

    test('reconhece Goiano', () {
      expect(classifyCompetition('Goiano'), CalendarCompetitionFilter.goiano);
    });

    test('qualquer coisa fora das 3 nomeadas cai em outros', () {
      expect(
        classifyCompetition('Copa Verde'),
        CalendarCompetitionFilter.outros,
      );
    });
  });

  group('matchesCompetitionFilter', () {
    test('filtro "all" aceita qualquer competição', () {
      expect(
        matchesCompetitionFilter(CalendarCompetitionFilter.all, 'Goiano'),
        isTrue,
      );
      expect(
        matchesCompetitionFilter(CalendarCompetitionFilter.all, 'Copa Verde'),
        isTrue,
      );
    });

    test('filtro específico só aceita a própria categoria', () {
      expect(
        matchesCompetitionFilter(CalendarCompetitionFilter.goiano, 'Goiano'),
        isTrue,
      );
      expect(
        matchesCompetitionFilter(
          CalendarCompetitionFilter.goiano,
          'Brasileirão Série B Superbet',
        ),
        isFalse,
      );
    });
  });
}
