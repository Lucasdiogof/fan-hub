import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/resolve_active_club.dart';
import 'package:goias_app/core/config/sentry_config.dart';
import 'package:goias_app/core/config/supabase_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/locale_cubit.dart';
import 'package:goias_app/core/network/session_aware_http_client.dart';
import 'package:goias_app/core/release/release_gate.dart';
import 'package:goias_app/core/router/app_router.dart';
import 'package:goias_app/core/router/root_navigator_key.dart';
import 'package:goias_app/core/router/splash_gate.dart';
import 'package:goias_app/core/session/account_session_cache_guard.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/core/theme/theme_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
import 'package:goias_app/features/notifications/presentation/push_notification_service.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_cubit.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:goias_app/shared/widgets/session_expiry_listener.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Puro (só lê `String.fromEnvironment` + faz lookup num Map) — não precisa
  // do binding do Flutter, por isso pode ser resolvido ANTES de qualquer
  // outra coisa, inclusive antes do `SentryFlutter.init` abaixo.
  final clubConfig = resolveActiveClub();

  // O binding do Flutter (`WidgetsFlutterBinding.ensureInitialized`) e todo
  // o resto do boot (Firebase/Supabase/DI) agora vivem DENTRO do
  // `appRunner`, não antes do `SentryFlutter.init`. Motivo: no Web, o
  // próprio Sentry usa `runZonedGuarded` pra capturar erro de `Future` (o
  // `PlatformDispatcher.onError` não funciona no Web — ver
  // `sentry_flutter`), criando uma ZONA NOVA em volta do `appRunner`. Se o
  // binding for criado ANTES dessa zona existir (como estava antes), o
  // Flutter registra a zona “errada” pro binding, e o `runApp` (já dentro
  // da zona nova) dispara o assert de "Zone mismatch" — só em modo debug no
  // Web (o assert cai fora em release, por isso nunca apareceu no build).
  // Criando o binding já DENTRO do `appRunner`, as duas zonas batem sempre.
  // Em Android/iOS/desktop isso não muda nada de verdade: `SentryFlutter`
  // só usa `runZonedGuarded` no Web (`isOnErrorSupported = !isWeb`) — nas
  // outras plataformas o `appRunner` já rodava direto, sem zona nenhuma, e
  // continua rodando exatamente assim.
  // Capturado na configuração síncrona abaixo pra poder ser atualizado de
  // dentro do `appRunner` (ver `release` mais abaixo) — evita depender de
  // `Sentry.currentHub` (API interna do pacote) só pra reobter as mesmas
  // options depois.
  late final SentryFlutterOptions sentryOptions;
  await SentryFlutter.init(
    (options) {
      sentryOptions = options;
      options.dsn = SentryConfig.dsn;
      options.environment = SentryConfig.environment;
      options.sendDefaultPii = false;
      options.tracesSampleRate = 1.0;
      // Sem isto, o Sentry usa o default (`['.*']`) e injeta `sentry-trace`/
      // `baggage` em QUALQUER request — inclusive a chamada cross-origin
      // pro Worker do próprio clube durante dev local (`API_BASE_URL`
      // apontando pro Worker publicado), o que faz o Dio disparar preflight
      // CORS. O Worker já foi corrigido pra aceitar esses headers (ver
      // `src/index.ts`), então tracing pro Worker CONTINUA ligado — só
      // restringe o alvo ao Worker do clube ativo, em vez de "qualquer
      // request", que nunca teve benefício real (o app não fala com mais
      // nada além do próprio Worker/Supabase, e o Supabase já tem seu
      // próprio tracing). `tracePropagationTargets` é `final` (a LISTA, não
      // a referência) — por isso `clear`/`add` em vez de reatribuir.
      options.tracePropagationTargets.clear();
      if (clubConfig.integrations.workerBaseUrl case final workerBaseUrl?) {
        options.tracePropagationTargets.add(RegExp.escape(workerBaseUrl));
      }
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      initializeBrazilTimeZone();
      // Nunca derruba o app se a config nativa do Firebase (google-services.
      // json/GoogleService-Info.plist) ainda não tiver sido adicionada — só
      // fica sem push até isso existir (ver `PushNotificationService`, que
      // também é defensivo pelo mesmo motivo). No Web, FCM já é
      // deliberadamente desativado (`PushNotificationService._initialize`
      // sai cedo com `kIsWeb`) e não existe `FirebaseOptions` Web
      // configurado — chamar `Firebase.initializeApp()` mesmo assim só
      // derruba a inicialização com "FirebaseOptions cannot be null" sem
      // nenhum benefício (nunca implementamos Web Push), então nem tenta.
      if (!kIsWeb) {
        try {
          await Firebase.initializeApp();
          FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler,
          );
        } catch (error, stackTrace) {
          debugPrint('Firebase.initializeApp falhou: $error\n$stackTrace');
        }
      }
      // Resolve o Supabase do clube ATIVO (flavor) antes de qualquer outra
      // coisa — nunca depende de `--dart-define`/Additional run args pra
      // saber qual projeto usar, e nunca cai pro Goiás se o clube ativo não
      // tiver config real (ver `SupabaseConfig.configure`).
      SupabaseConfig.configure(clubConfig);
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
        // Renova a sessão sozinho e tenta de novo quando o servidor rejeita
        // um token que o relógio local ainda achava válido (ver
        // `SessionAwareHttpClient`) — único ponto pra isso, cobre todo
        // repositório que fala com o Supabase, sem precisar mexer em cada
        // um.
        httpClient: SessionAwareHttpClient(http.Client()),
      );
      setupDependencies();
      // Lido do build instalado (funciona igual em Web/PWA — mesma fonte já
      // usada em `profile_page.dart` pra mostrar a versão no Perfil), nunca
      // hardcoded — assim o release no Sentry nunca desalinha do
      // `pubspec.yaml`. Só dá pra ler DEPOIS do binding existir, por isso
      // atualiza `options.release` aqui (mesmo objeto vivo lido por
      // referência em todo evento, nunca um snapshot antigo) em vez de na
      // configuração síncrona do `SentryFlutter.init` acima.
      final packageInfo = await PackageInfo.fromPlatform();
      sentryOptions.release =
          'goias_app@${packageInfo.version}+${packageInfo.buildNumber}';
      runApp(const GoiasApp());
    },
  );
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
  final ClubConfig _clubConfig = sl<ClubConfig>();
  // Nunca lido depois — só precisa existir cedo pro listener de
  // logout/sessão expirada já estar de pé (ver `AccountSessionCacheGuard`).
  // ignore: unused_field
  final AccountSessionCacheGuard _accountSessionCacheGuard =
      sl<AccountSessionCacheGuard>();
  // Mesma razão — liga o ciclo de vida do FCM ao login/logout desde o
  // início (ver `PushNotificationService`).
  // ignore: unused_field
  final PushNotificationService _pushNotificationService =
      sl<PushNotificationService>();
  late final GoRouter _router = createAppRouter(
    _authCubit,
    sl<SplashGate>(),
    sl<ReleaseGate>(),
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _themeCubit),
        BlocProvider.value(value: _localeCubit),
        // Singleton acessado via `context.read`/`context.select` de
        // qualquer rota da Store (carrinho) — sem isto, toda tela fora da
        // IndexedStack da Home (empurrada via `context.push`, ex.
        // `/store/product/:id`) não encontra o Provider e quebra em tempo
        // de execução. `HomeShellPage` continua responsável por chamar
        // `.load()` cedo; aqui só disponibilizamos o mesmo singleton do
        // GetIt pra árvore inteira.
        BlocProvider.value(value: sl<CartCubit>()),
        BlocProvider.value(value: sl<MembershipStatusCubit>()),
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
                  title:
                      _clubConfig.productNames.appDisplayName ??
                      _clubConfig.identity.displayName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light(_clubConfig.branding.light),
                  darkTheme: AppTheme.dark(_clubConfig.branding.dark),
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
