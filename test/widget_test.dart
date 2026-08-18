import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:goias_app/core/config/supabase_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/main.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // main() does both before runApp. AuthRemoteDataSource touches
    // Supabase.instance.client the moment AuthCubit is first resolved
    // (during GoiasApp's own construction), and Supabase's local session
    // storage needs a mocked shared_preferences channel to init in tests.
    SharedPreferences.setMockInitialValues({});
    initializeBrazilTimeZone();
    await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
  });

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
    await tester.pumpAndSettle();

    // Sem sessão persistida, o router redireciona pro /login.
    expect(find.text('Entrar'), findsWidgets);
    expect(errors, isEmpty);

    FlutterError.onError = originalOnError;
  });
}
