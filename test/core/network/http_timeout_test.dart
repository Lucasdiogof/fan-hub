import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/connectivity_error.dart';
import 'package:goias_app/core/network/session_aware_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  // GOI-OFF-002: sem timeout, modo avião deixava telas em loading eterno.
  test('request that never answers ends in TimeoutException', () async {
    final never = Completer<http.StreamedResponse>();
    final client = SessionAwareHttpClient(
      _HangingClient(never),
      requestTimeout: const Duration(milliseconds: 50),
    );
    final future = client.get(Uri.parse('https://x.supabase.co/rest/v1/t'));
    await expectLater(future, throwsA(isA<TimeoutException>()));
  });

  test('auth traffic times out as ClientException (retryable for GoTrue)', () {
    final client = SessionAwareHttpClient(
      _HangingClient(Completer<http.StreamedResponse>()),
      requestTimeout: const Duration(milliseconds: 50),
    );
    expect(
      client.get(Uri.parse('https://x.supabase.co/auth/v1/token')),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('fast responses are untouched', () async {
    final client = SessionAwareHttpClient(
      MockClient((_) async => http.Response('ok', 200)),
      requestTimeout: const Duration(milliseconds: 50),
    );
    final response = await client.get(Uri.parse('https://x.co/rest/v1/t'));
    expect(response.body, 'ok');
  });

  test('isConnectivityError classifies network-ish failures only', () {
    expect(isConnectivityError(TimeoutException('t')), isTrue);
    expect(isConnectivityError(http.ClientException('offline')), isTrue);
    expect(isConnectivityError(StateError('bug')), isFalse);
  });
}

class _HangingClient extends http.BaseClient {
  _HangingClient(this._completer);

  final Completer<http.StreamedResponse> _completer;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _completer.future;
}
