import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/passport/domain/passport_level.dart';

void main() {
  group('passportLevelForMatches — boundaries', () {
    final cases = {
      0: PassportLevel.primeirosPassos,
      9: PassportLevel.primeirosPassos,
      10: PassportLevel.torcedorPresente,
      24: PassportLevel.torcedorPresente,
      25: PassportLevel.esmeraldinoDeArquibancada,
      49: PassportLevel.esmeraldinoDeArquibancada,
      50: PassportLevel.verdaoRaiz,
      99: PassportLevel.verdaoRaiz,
      100: PassportLevel.lendaEsmeraldina,
    };

    for (final entry in cases.entries) {
      test('${entry.key} jogos → ${entry.value}', () {
        expect(passportLevelForMatches(entry.key), entry.value);
      });
    }

    test('43 jogos (caso real) → esmeraldinoDeArquibancada', () {
      expect(
        passportLevelForMatches(43),
        PassportLevel.esmeraldinoDeArquibancada,
      );
    });

    test('um número bem grande continua lendaEsmeraldina', () {
      expect(passportLevelForMatches(500), PassportLevel.lendaEsmeraldina);
    });

    test('nunca recebe negativo, mas não deve quebrar se receber', () {
      expect(passportLevelForMatches(-1), PassportLevel.primeirosPassos);
    });
  });
}
