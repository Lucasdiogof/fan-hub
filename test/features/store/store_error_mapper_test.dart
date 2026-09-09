import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/features/store/data/store_error_mapper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Transport falso — nunca toca rede, só grava os envelopes que o SDK
/// tentou enviar. Prova que `mapStoreError` realmente aciona o Sentry (e
/// quantas vezes), sem depender de um DSN de verdade.
class _RecordingTransport implements Transport {
  final List<SentryEnvelope> envelopes = [];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    envelopes.add(envelope);
    return SentryId.newId();
  }
}

void main() {
  late _RecordingTransport transport;

  setUp(() async {
    transport = _RecordingTransport();
    await Sentry.init((options) {
      options.dsn = 'https://public@example.com/1';
      options.transport = transport;
    });
  });

  tearDown(() async {
    await Sentry.close();
  });

  test('SocketException (sem rede) vira NetworkFailure', () {
    final failure = mapStoreError(
      const SocketException('sem rede'),
      StackTrace.current,
    );
    expect(failure, isA<NetworkFailure>());
  });

  test('PostgrestException vira ServerFailure amigável', () {
    final failure = mapStoreError(
      const PostgrestException(message: 'constraint violation on store_orders'),
      StackTrace.current,
    );
    expect(failure, isA<ServerFailure>());
    // A mensagem exposta pro usuário nunca é o erro cru do Postgres — evita
    // vazar detalhe interno de schema/coluna pra UI.
    expect(failure.message, isNot(contains('constraint')));
  });

  test('erro genérico vira ServerFailure, nunca propaga o texto original', () {
    final failure = mapStoreError(
      Exception('detalhe interno sensível'),
      StackTrace.current,
    );
    expect(failure, isA<ServerFailure>());
    expect(failure.message, isNot(contains('detalhe interno sensível')));
  });

  test(
    'cada chamada aciona o Sentry exatamente uma vez, nunca duplicado',
    () async {
      mapStoreError(Exception('a'), StackTrace.current);
      mapStoreError(Exception('b'), StackTrace.current);
      mapStoreError(Exception('c'), StackTrace.current);
      // `Sentry.captureException` é chamado via `unawaited` dentro do mapper —
      // drena a fila de microtasks pra garantir que os 3 envios já rodaram.
      await pumpEventQueue();

      expect(transport.envelopes, hasLength(3));
    },
  );

  test('o envelope carrega a stack trace original, não descartada', () async {
    Object caught;
    StackTrace caughtStack;
    try {
      throw StateError('falha rastreável');
    } catch (error, stackTrace) {
      caught = error;
      caughtStack = stackTrace;
    }

    mapStoreError(caught, caughtStack);
    await pumpEventQueue();

    expect(transport.envelopes, hasLength(1));
    final eventItem = transport.envelopes.single.items.firstWhere(
      (item) => item.header.type == 'event',
    );
    final event = eventItem.originalObject as SentryEvent;
    expect(event.exceptions, isNotNull);
    expect(event.exceptions, isNotEmpty);
    expect(event.exceptions!.first.stackTrace, isNotNull);
  });
}
