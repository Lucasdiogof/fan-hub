import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/club/data/club_titles_data.dart';

void main() {
  group('ClubTitlesData', () {
    test(
      'totalTitles sums every group and never counts historical campaigns',
      () {
        expect(ClubTitlesData.totalTitles, 34);
      },
    );

    test('no group is empty', () {
      for (final group in ClubTitlesData.groups) {
        expect(group.years, isNotEmpty, reason: group.competitionName);
      }
    });
  });
}
