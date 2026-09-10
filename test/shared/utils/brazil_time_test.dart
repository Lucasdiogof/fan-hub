// Correção 2026-09-12: a contagem regressiva da Home variava com o fuso
// configurado no aparelho porque `DateTime.parse` num horário "nu" (sem
// timezone — convenção histórica do Worker pra `/current-round`/`/team`/
// `/fixtures`) trata os números como se já fossem hora LOCAL DO APARELHO,
// não do Brasil. `parseKickoffInstant` corrige isso na origem; `toBrazilTime`
// garante que a EXIBIÇÃO sempre mostra horário de Brasília, nunca o do
// dispositivo (`.toLocal()` é proibido pra isto, ver comentário no arquivo).
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';

void main() {
  setUpAll(initializeBrazilTimeZone);

  group('parseKickoffInstant', () {
    test('string sem timezone -> interpretada como America/Sao_Paulo (UTC-3)', () {
      final instant = parseKickoffInstant('2026-08-21T21:30:00');
      expect(instant, isNotNull);
      expect(instant!.isUtc, isTrue);
      // 21:30 em Brasília = 00:30 UTC do dia seguinte.
      expect(instant.year, 2026);
      expect(instant.month, 8);
      expect(instant.day, 22);
      expect(instant.hour, 0);
      expect(instant.minute, 30);
    });

    test('string com "Z" (UTC real, ex.: pernas de mata-mata) -> respeitada sem novo deslocamento', () {
      final instant = parseKickoffInstant('2026-08-21T21:30:00Z');
      expect(instant!.isUtc, isTrue);
      expect(instant.hour, 21);
      expect(instant.minute, 30);
      expect(instant.day, 21);
    });

    test('string com offset explícito diferente de -03:00 -> respeitada, nunca sobrescrita', () {
      // +00:00 (ex.: um provider hipotético que manda offset europeu).
      final instant = parseKickoffInstant('2026-08-21T21:30:00+00:00');
      expect(instant!.hour, 21);
      expect(instant.minute, 30);
    });

    test('null -> null, nunca lança exceção', () {
      expect(parseKickoffInstant(null), isNull);
    });

    test(
      'o instante correto (com timezone) é sempre um instante ABSOLUTO — o '
      'mesmo momento real, independente de qual dos dois formatos a fonte usou',
      () {
        // 21:30 em Brasília == 00:30 UTC do dia seguinte: os dois devem
        // produzir o MESMO instante absoluto.
        final naive = parseKickoffInstant('2026-08-21T21:30:00');
        final explicit = parseKickoffInstant('2026-08-22T00:30:00Z');
        expect(naive, explicit);
      },
    );
  });

  group('toBrazilTime — nunca depende do fuso do dispositivo rodando o app', () {
    test('converte um instante UTC pro horário de parede de Brasília', () {
      final utcInstant = DateTime.utc(2026, 8, 22, 0, 30);
      final brazil = toBrazilTime(utcInstant);
      expect(brazil.hour, 21);
      expect(brazil.day, 21);
      expect(brazil.month, 8);
    });

    test(
      'contagem regressiva: a diferença entre "agora" e o kickoff é a MESMA '
      'independente de qual fuso o DateTime de entrada usa — só a leitura '
      'de campos (hora/dia) muda, nunca a aritmética de instante',
      () {
        final kickoffNaiveInterpretation = parseKickoffInstant(
          '2026-08-21T21:30:00',
        )!;
        final kickoffExplicitUtc = DateTime.parse(
          '2026-08-22T00:30:00Z',
        ).toUtc();
        final reference = DateTime.utc(2026, 8, 21, 12);
        expect(
          kickoffNaiveInterpretation.difference(reference),
          kickoffExplicitUtc.difference(reference),
        );
      },
    );
  });
}
