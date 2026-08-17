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

  group('MatchOrdering.nextMatch', () {
    test('picks the earliest valid future/live match, not just the first item', () {
      final matches = [
        _match(id: 'far', kickoff: now.add(const Duration(days: 30)), status: MatchStatus.scheduled),
        _match(id: 'cancelled-soon', kickoff: now.add(const Duration(days: 1)), status: MatchStatus.cancelled),
        _match(id: 'closest', kickoff: now.add(const Duration(days: 3)), status: MatchStatus.scheduled),
      ];

      expect(MatchOrdering.nextMatch(matches)?.id, 'closest');
    });

    test('a live match in progress still counts as next even though kickoff is in the past', () {
      final matches = [
        _match(id: 'live-now', kickoff: now.subtract(const Duration(minutes: 30)), status: MatchStatus.live),
        _match(id: 'future', kickoff: now.add(const Duration(days: 2)), status: MatchStatus.scheduled),
      ];

      expect(MatchOrdering.nextMatch(matches)?.id, 'live-now');
    });

    test('returns null when there is no valid upcoming match', () {
      final matches = [
        _match(id: 'past', kickoff: now.subtract(const Duration(days: 1)), status: MatchStatus.finished),
        _match(id: 'postponed', kickoff: now.add(const Duration(days: 1)), status: MatchStatus.postponed),
      ];

      expect(MatchOrdering.nextMatch(matches), isNull);
    });
  });

  group('MatchOrdering.upcoming', () {
    test('sorts ascending (soonest first) and excludes finished/cancelled', () {
      final matches = [
        _match(id: 'later', kickoff: now.add(const Duration(days: 10)), status: MatchStatus.scheduled),
        _match(id: 'soonest', kickoff: now.add(const Duration(days: 1)), status: MatchStatus.scheduled),
        _match(id: 'done', kickoff: now.subtract(const Duration(days: 1)), status: MatchStatus.finished),
      ];

      final result = MatchOrdering.upcoming(matches);
      expect(result.map((m) => m.id), ['soonest', 'later']);
    });
  });

  group('MatchOrdering.results', () {
    test('sorts descending (most recent first) and only includes finished', () {
      final matches = [
        _match(id: 'oldest', kickoff: now.subtract(const Duration(days: 20)), status: MatchStatus.finished),
        _match(id: 'newest', kickoff: now.subtract(const Duration(days: 1)), status: MatchStatus.finished),
        _match(id: 'scheduled', kickoff: now.add(const Duration(days: 1)), status: MatchStatus.scheduled),
      ];

      final result = MatchOrdering.results(matches);
      expect(result.map((m) => m.id), ['newest', 'oldest']);
    });
  });

  group('MatchOrdering.groupByMonth', () {
    test('groups by month derived from kickoff, preserving chronological order', () {
      final matches = [
        _match(id: 'aug-1', kickoff: DateTime(2026, 8, 5), status: MatchStatus.scheduled),
        _match(id: 'aug-2', kickoff: DateTime(2026, 8, 20), status: MatchStatus.scheduled),
        _match(id: 'sep-1', kickoff: DateTime(2026, 9, 3), status: MatchStatus.scheduled),
      ];

      final groups = MatchOrdering.groupByMonth(matches);
      expect(groups.keys.toList(), ['AGOSTO', 'SETEMBRO']);
      expect(groups['AGOSTO']!.map((m) => m.id), ['aug-1', 'aug-2']);
      expect(groups['SETEMBRO']!.map((m) => m.id), ['sep-1']);
    });
  });
}
