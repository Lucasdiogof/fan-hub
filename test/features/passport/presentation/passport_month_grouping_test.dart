import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/presentation/passport_month_grouping.dart';
import 'package:intl/date_symbol_data_local.dart';

PassportMatch _match(String date) => PassportMatch.fromMap({
  'id': 'm_$date',
  'season': int.parse(date.substring(0, 4)),
  'match_date': date,
  'match_time': '20:00:00',
  'status': 'FINISHED',
  'competition': 'Brasileirão Série A',
  'competition_code': 'BRASILEIRAO_A',
  'opponent': 'Adversário',
  'club_is_home': true,
  'home_team': 'Casa',
  'away_team': 'Adversário',
  'attended': false,
});

void main() {
  setUpAll(() => initializeDateFormatting('pt'));

  test('o mês mais recente vem primeiro', () {
    final groups = groupMatchesByMonth([
      _match('2026-01-15'),
      _match('2026-03-02'),
      _match('2026-09-06'),
      _match('2026-05-20'),
    ], 'pt');

    expect(groups.map((g) => g.label).toList(), [
      'Setembro de 2026',
      'Maio de 2026',
      'Março de 2026',
      'Janeiro de 2026',
    ]);
  });

  test('dentro do mês a partida mais recente também vem primeiro', () {
    final groups = groupMatchesByMonth([
      _match('2026-09-02'),
      _match('2026-09-20'),
      _match('2026-09-11'),
    ], 'pt');

    expect(groups, hasLength(1));
    expect(groups.single.matches.map((m) => m.id).toList(), [
      'm_2026-09-20',
      'm_2026-09-11',
      'm_2026-09-02',
    ]);
  });

  test('a ordem de entrada não muda o resultado', () {
    final crescente = ['2026-02-01', '2026-04-01', '2026-08-01'];
    final aOrdem = groupMatchesByMonth(
      crescente.map(_match).toList(),
      'pt',
    ).map((g) => g.label).toList();
    final aoContrario = groupMatchesByMonth(
      crescente.reversed.map(_match).toList(),
      'pt',
    ).map((g) => g.label).toList();

    expect(aOrdem, aoContrario);
    expect(aOrdem.first, 'Agosto de 2026');
  });

  test('não perde nem duplica partida', () {
    final datas = [
      '2026-01-05',
      '2026-01-31',
      '2026-02-14',
      '2025-12-30',
      '2026-07-07',
    ];
    final groups = groupMatchesByMonth(datas.map(_match).toList(), 'pt');
    final ids = groups.expand((g) => g.matches).map((m) => m.id).toList();

    expect(ids, hasLength(datas.length));
    expect(ids.toSet(), hasLength(datas.length));
  });

  test('dezembro do ano anterior não se mistura com dezembro deste ano', () {
    final groups = groupMatchesByMonth([
      _match('2025-12-10'),
      _match('2026-12-10'),
    ], 'pt');

    expect(groups, hasLength(2));
    expect(groups.first.label, 'Dezembro de 2026');
    expect(groups.last.label, 'Dezembro de 2025');
  });

  test('o rótulo do mês começa com maiúscula', () {
    final groups = groupMatchesByMonth([_match('2026-09-06')], 'pt');
    expect(groups.single.label[0], 'S');
  });

  test('lista vazia não quebra', () {
    expect(groupMatchesByMonth(const [], 'pt'), isEmpty);
  });
}
