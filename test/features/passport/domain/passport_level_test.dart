import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/passport/domain/passport_level.dart';

void main() {
  group('passportLevelForMatches — boundaries', () {
    final cases = {
      0: PassportLevel.starter,
      9: PassportLevel.starter,
      10: PassportLevel.present,
      24: PassportLevel.present,
      25: PassportLevel.bleacher,
      49: PassportLevel.bleacher,
      50: PassportLevel.roots,
      99: PassportLevel.roots,
      100: PassportLevel.legend,
    };

    for (final entry in cases.entries) {
      test('${entry.key} jogos → ${entry.value}', () {
        expect(passportLevelForMatches(entry.key), entry.value);
      });
    }

    test('43 jogos (caso real) → esmeraldinoDeArquibancada', () {
      expect(
        passportLevelForMatches(43),
        PassportLevel.bleacher,
      );
    });

    test('um número bem grande continua lendaEsmeraldina', () {
      expect(passportLevelForMatches(500), PassportLevel.legend);
    });

    test('nunca recebe negativo, mas não deve quebrar se receber', () {
      expect(passportLevelForMatches(-1), PassportLevel.starter);
    });
  });
}
