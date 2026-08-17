import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/domain/match_ordering.dart';

const _goias = Team(id: 1, name: 'Goiás', shortName: 'GO', color: Color(0xFF004C1B));
const _opponent = Team(id: 2, name: 'Coritiba', shortName: 'CFC', color: Color(0xFF1F6F4A));

Match _match({
  required String id,
  required DateTime kickoff,
  required MatchStatus status,
  int? homeScore,
  int? awayScore,
}) {
  return Match(
    id: id,
    competition: 'Brasileirão Série B',
    round: 'Rodada 1',
    homeTeam: _goias,
    awayTeam: _opponent,
    stadium: 'Serrinha',
    kickoff: kickoff,
    status: status,
    homeScore: homeScore,
    awayScore: awayScore,
  );
}

void main() {
  final now = DateTime(2026, 8, 17, 12);

  group('MatchOrdering.isOpen', () {
    test('scheduled, live and halftime count as open', () {
      expect(MatchOrdering.isOpen(_match(id: 'a', kickoff: now, status: MatchStatus.scheduled)), isTrue);
      expect(MatchOrdering.isOpen(_match(id: 'b', kickoff: now, status: MatchStatus.live)), isTrue);
      expect(MatchOrdering.isOpen(_match(id: 'c', kickoff: now, status: MatchStatus.halftime)), isTrue);
    });

    test('finished, postponed, cancelled and suspended are not open', () {
      expect(MatchOrdering.isOpen(_match(id: 'a', kickoff: now, status: MatchStatus.finished)), isFalse);
      expect(MatchOrdering.isOpen(_match(id: 'b', kickoff: now, status: MatchStatus.postponed)), isFalse);
      expect(MatchOrdering.isOpen(_match(id: 'c', kickoff: now, status: MatchStatus.cancelled)), isFalse);
      expect(MatchOrdering.isOpen(_match(id: 'd', kickoff: now, status: MatchStatus.suspended)), isFalse);
    });
  });

  group('MatchOrdering.chronological', () {
    test('sorts ascending regardless of input order, never trusting provider order', () {
      final matches = [
        _match(id: 'later', kickoff: now.add(const Duration(days: 10)), status: MatchStatus.scheduled),
        _match(id: 'soonest', kickoff: now.add(const Duration(days: 1)), status: MatchStatus.scheduled),
        _match(id: 'middle', kickoff: now.add(const Duration(days: 5)), status: MatchStatus.live),
      ];

      final result = MatchOrdering.chronological(matches);
      expect(result.map((m) => m.id), ['soonest', 'middle', 'later']);
    });
  });
}
