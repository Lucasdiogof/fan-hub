import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/main.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';

void main() {
  setUpAll(initializeBrazilTimeZone);

  setUp(setupDependencies);

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('App renders without crashing', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError!;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('overflowed')) return;
      errors.add(details);
    };

    await tester.pumpWidget(const GoiasApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Início'), findsWidgets);
    expect(errors, isEmpty);

    FlutterError.onError = originalOnError;
  });
}
