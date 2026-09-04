import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
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
    // Este smoke test é pré-multiclub (skip: true no único testWidgets, ver
    // comentário abaixo) — sempre configurado pro Goiás explicitamente,
    // nunca depende de --dart-define/APP_CLUB do ambiente de teste.
    SupabaseConfig.configure(goiasClubConfig);
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  });

  setUp(setupDependencies);

  tearDown(() async {
    await GetIt.instance.reset();
  });

  // Boota o app inteiro (splash com vídeo + init do Supabase), o que trava no
  // VM headless de teste (o vídeo nunca inicializa e o boot não assenta). A
  // cobertura de boot fica nos testes de feature; smoke test desligado.
  testWidgets('App renders without crashing', skip: true, (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('pt');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    final errors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError!;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('overflowed')) return;
      errors.add(details);
    };

    await tester.pumpWidget(const GoiasApp());
    // Não usamos pumpAndSettle: a splash/o fundo do login têm animações
    // contínuas que nunca "assentam" no ambiente de teste (o vídeo da splash
    // não inicializa sem plataforma). Bombeamos por tempo limitado até a tela
    // de login aparecer.
    final loginButton = find.text('ENTRAR');
    for (var i = 0; i < 40 && loginButton.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Sem sessão persistida, o router redireciona pro /login.
    expect(loginButton, findsWidgets);
    expect(errors, isEmpty);

    FlutterError.onError = originalOnError;
  });
}
