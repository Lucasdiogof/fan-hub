import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/match/domain/calendar_month_grid.dart';

void main() {
  group('monthGridDays', () {
    test(
      'agosto de 2026 (começa num sábado) tem 6 espaços em branco antes do dia 1',
      () {
        final days = monthGridDays(DateTime(2026, 8));

        expect(days[0], isNull);
        expect(days[1], isNull);
        expect(days[2], isNull);
        expect(days[3], isNull);
        expect(days[4], isNull);
        expect(days[5], isNull);
        expect(days[6], DateTime(2026, 8, 1));
      },
    );

    test('nunca mostra dia de mês vizinho — só null antes/depois do mês', () {
      final days = monthGridDays(DateTime(2026, 8));
      final realDays = days.whereType<DateTime>();

      expect(realDays.every((d) => d.month == 8 && d.year == 2026), isTrue);
    });

    test('a grade sempre tem um número de células múltiplo de 7', () {
      for (var month = 1; month <= 12; month++) {
        final days = monthGridDays(DateTime(2026, month));
        expect(days.length % 7, 0, reason: 'mês $month');
      }
    });

    test('fevereiro de 2028 (ano bissexto) tem 29 dias', () {
      final days = monthGridDays(DateTime(2028, 2));
      final realDays = days.whereType<DateTime>().toList();

      expect(realDays.length, 29);
      expect(realDays.last, DateTime(2028, 2, 29));
    });

    test('fevereiro de 2026 (não bissexto) tem 28 dias', () {
      final days = monthGridDays(DateTime(2026, 2));
      final realDays = days.whereType<DateTime>().toList();

      expect(realDays.length, 28);
      expect(realDays.last, DateTime(2026, 2, 28));
    });

    test(
      'mês que começa num domingo não tem espaço em branco antes do dia 1',
      () {
        // Novembro de 2026 começa num domingo.
        final days = monthGridDays(DateTime(2026, 11));

        expect(days.first, DateTime(2026, 11, 1));
      },
    );

    test('dezembro tem 31 dias e o último dia bate certo', () {
      final days = monthGridDays(DateTime(2026, 12));
      final realDays = days.whereType<DateTime>().toList();

      expect(realDays.length, 31);
      expect(realDays.last, DateTime(2026, 12, 31));
    });
  });

  group('addMonths', () {
    test('vira o ano ao somar além de dezembro', () {
      expect(addMonths(DateTime(2026, 12), 1), DateTime(2027, 1));
    });

    test('vira o ano ao subtrair antes de janeiro', () {
      expect(addMonths(DateTime(2026, 1), -1), DateTime(2025, 12));
    });

    test('soma normal dentro do mesmo ano', () {
      expect(addMonths(DateTime(2026, 3), 2), DateTime(2026, 5));
    });
  });

  group('startOfMonth', () {
    test('zera o dia, mantém mês e ano', () {
      expect(startOfMonth(DateTime(2026, 8, 17)), DateTime(2026, 8));
    });
  });
}
