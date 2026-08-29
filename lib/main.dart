import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/config/sentry_config.dart';
import 'package:goias_app/core/config/supabase_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/locale_cubit.dart';
import 'package:goias_app/core/network/session_aware_http_client.dart';
import 'package:goias_app/core/router/app_router.dart';
import 'package:goias_app/core/router/root_navigator_key.dart';
import 'package:goias_app/core/router/splash_gate.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/core/theme/theme_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/favorites_cubit.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:goias_app/shared/widgets/session_expiry_listener.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeBrazilTimeZone();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    // Renova a sessão sozinho e tenta de novo quando o servidor rejeita um
    // token que o relógio local ainda achava válido (ver
    // `SessionAwareHttpClient`) — único ponto pra isso, cobre todo
    // repositório que fala com o Supabase, sem precisar mexer em cada um.
    httpClient: SessionAwareHttpClient(http.Client()),
  );
  setupDependencies();
  // Nunca manda PII automático (o app lida com CPF/telefone/e-mail real) —
  // o que queremos ver no Sentry é o erro, não dado pessoal do usuário.
  // `tracesSampleRate: 1.0` é seguro pro volume desse app (fã-clube, não
  // um app de milhões de usuários); baixar se algum dia isso mudar.
  await SentryFlutter.init((options) {
    options.dsn = SentryConfig.dsn;
    options.sendDefaultPii = false;
    options.tracesSampleRate = 1.0;
  }, appRunner: () => runApp(const GoiasApp()));
}

class GoiasApp extends StatefulWidget {
  const GoiasApp({super.key});

  @override
  State<GoiasApp> createState() => _GoiasAppState();
}

class _GoiasAppState extends State<GoiasApp> {
  final AuthCubit _authCubit = sl<AuthCubit>();
  final ThemeCubit _themeCubit = sl<ThemeCubit>();
  final LocaleCubit _localeCubit = sl<LocaleCubit>();
  late final GoRouter _router = createAppRouter(_authCubit, sl<SplashGate>());

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _themeCubit),
        BlocProvider.value(value: _localeCubit),
        // Singletons acessados via `context.read`/`context.select` de
        // qualquer rota da Store (carrinho/favoritos) — sem isto, toda tela
        // fora da IndexedStack da Home (empurrada via `context.push`, ex.
        // `/store/product/:id`) não encontra o Provider e quebra em tempo
        // de execução. `HomeShellPage` continua responsável por chamar
        // `.load()` cedo; aqui só disponibilizamos o mesmo singleton do
        // GetIt pra árvore inteira.
        BlocProvider.value(value: sl<CartCubit>()),
        BlocProvider.value(value: sl<FavoritesCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        bloc: _themeCubit,
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale?>(
            bloc: _localeCubit,
            builder: (context, locale) {
              return SessionExpiryListener(
                authCubit: _authCubit,
                navigatorKey: rootNavigatorKey,
                child: MaterialApp.router(
                  title: 'Goiás EC',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: themeMode,
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  routerConfig: _router,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
