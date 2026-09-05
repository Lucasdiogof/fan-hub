// Auditoria 2026-09-05 — o payload do QR do ingresso demonstrativo precisa
// ser inequivocamente diferente de uma emissão real (namespace `DEMO-`),
// nunca só o texto ao redor do QR na tela/PDF.
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/ticket/presentation/ticket_pdf.dart';

void main() {
  group('ticketQrPayload', () {
    test('isDemo:true usa o namespace DEMO-GOIAS-EC-', () {
      expect(ticketQrPayload('abc123', isDemo: true), 'DEMO-GOIAS-EC-abc123');
    });

    test(
      'isDemo:false usa o namespace real GOIAS-EC- (comportamento pré-existente preservado)',
      () {
        expect(ticketQrPayload('abc123', isDemo: false), 'GOIAS-EC-abc123');
      },
    );

    test('os dois payloads nunca coincidem pro mesmo id', () {
      const id = 'xyz789';
      expect(
        ticketQrPayload(id, isDemo: true),
        isNot(ticketQrPayload(id, isDemo: false)),
      );
    });
  });
}
