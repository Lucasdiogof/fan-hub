import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/widgets/session_expiry_listener.dart';

/// Repositório falso — dá ao teste controle direto sobre o stream de
/// eventos de sessão (`sessionEvents`), sem precisar de um Supabase de
/// verdade. Só os membros usados pelo `AuthCubit` têm comportamento real;
/// o resto (fluxos de login/cadastro) nunca é exercitado por este teste,
/// que cobre só o listener de sessão expirada.
class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthSessionEvent>.broadcast();
  AuthUser? _user = const AuthUser(id: 'u1', email: 'torcedor@goias.com');

  void emitSessionExpired() => _controller.add(AuthSessionEvent.sessionExpired);

  void emitManualSignOut() {
    _user = null;
    _controller.add(AuthSessionEvent.signedOut);
  }

  Future<void> dispose() => _controller.close();

  @override
  bool get isAuthenticated => _user != null;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthSessionEvent> get sessionEvents => _controller.stream;

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async => const Success(null);

  @override
  Future<Result<bool>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
    required String phone,
    required bool marketingOptIn,
  }) async => const Success(false);

  @override
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  }) async => const Success(null);

  @override
  Future<Result<bool>> isCpfTaken(String cpf) async => const Success(false);

  @override
  Future<Result<void>> signOut() async {
    emitManualSignOut();
    return const Success(null);
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async =>
      const Success(null);

  @override
  Future<Result<void>> resendConfirmationEmail(String email) async =>
      const Success(null);

  @override
  Future<Result<void>> updatePassword(String newPassword) async =>
      const Success(null);

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => const Success(null);

  @override
  Future<Result<void>> deleteAccount({required String password}) async =>
      const Success(null);
}

/// Mesma função do `_AuthRefresh` privado de `app_router.dart` — replicado
/// aqui só porque não é exportado; a lógica de fato testada
/// (`SessionExpiryListener`) é a classe de produção real, sem duplicação.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

const _sheetTitle = 'Sua sessão expirou';
const _sheetCta = 'Entrar novamente';

/// Frames suficientes pra cobrir a retentativa de `SessionExpiryListener`
/// quando o `Navigator` está momentaneamente desmontado no frame do
/// redirect (ver `session_expiry_listener.dart`) — bem menos que o limite
/// de tentativas real do widget, só o bastante pra nunca ser a causa de um
/// teste flaky.
const _maxSheetRetryPumps = 3;

/// Espera o evento de auth (sessionExpired/signedOut) atravessar toda a
/// cadeia real: stream do repositório fake → `AuthCubit` → stream do
/// próprio Cubit → dois listeners independentes (`_AuthRefreshListenable` e
/// `SessionExpiryListener`). `tester.pump()` sozinho não é suficiente —
/// essa cadeia passa por mais de um `StreamController.broadcast`
/// encadeado, e sem um gap assíncrono REAL entre cada pump (não só
/// microtasks) a entrega fica presa até o `tearDown` (confirmado: nem 15
/// `pump()` seguidos bastavam sem isso).
Future<void> _settleAfterAuthEvent(WidgetTester tester) async {
  for (var i = 0; i < _maxSheetRetryPumps; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  late _FakeAuthRepository authRepo;
  late AuthCubit authCubit;
  late GoRouter router;
  // Chave própria por teste (não a `rootNavigatorKey` de produção) — evita
  // qualquer risco de um teste reaproveitar/colidir com o Navigator de
  // outro, já que é uma `GlobalKey` só, reaproveitada entre testes.
  late GlobalKey<NavigatorState> navigatorKey;

  setUp(() {
    authRepo = _FakeAuthRepository();
    authCubit = AuthCubit(authRepo);
    navigatorKey = GlobalKey<NavigatorState>();
    router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      refreshListenable: _AuthRefreshListenable(authCubit.stream),
      redirect: (context, state) {
        final loggedIn = authCubit.state is AuthAuthenticated;
        final onLogin = state.matchedLocation == '/login';
        if (!loggedIn && !onLogin) return '/login';
        if (loggedIn && onLogin) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('HOME PROTEGIDA'))),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('TELA DE LOGIN'))),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await authCubit.close();
    await authRepo.dispose();
  });

  Widget buildApp() {
    return SessionExpiryListener(
      authCubit: authCubit,
      navigatorKey: navigatorKey,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('pt'),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  testWidgets(
    'sessão expira: uma única sheet aparece, router redireciona pro login, sheet continua válida, CTA fecha e deixa no login',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // 1. usuário autenticado numa tela protegida.
      expect(find.text('HOME PROTEGIDA'), findsOneWidget);
      expect(find.text(_sheetTitle), findsNothing);

      // 2. ocorre sessionExpired.
      authRepo.emitSessionExpired();
      await _settleAfterAuthEvent(tester);
      expect(tester.takeException(), isNull);

      // 3. exatamente uma sheet.
      expect(find.text(_sheetTitle), findsOneWidget);

      // 4. o router já redirecionou pro /login por baixo da sheet.
      expect(find.text('TELA DE LOGIN'), findsOneWidget);
      expect(find.text('HOME PROTEGIDA'), findsNothing);

      // 5. a sheet continua válida depois do redirect — sem exception,
      // sem context descartado.
      expect(find.text(_sheetTitle), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 6. tocar "Entrar novamente" fecha a sheet e deixa o usuário no
      // login, sem exception.
      await tester.tap(find.text(_sheetCta));
      await tester.pumpAndSettle();
      expect(find.text(_sheetTitle), findsNothing);
      expect(find.text('TELA DE LOGIN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '7. várias emissões simultâneas de sessionExpired nunca criam mais de uma sheet',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      authRepo
        ..emitSessionExpired()
        ..emitSessionExpired()
        ..emitSessionExpired();
      await _settleAfterAuthEvent(tester);

      expect(find.text(_sheetTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('8. logout manual normal não mostra a sheet de sessão expirada', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    authRepo.emitManualSignOut();
    await _settleAfterAuthEvent(tester);

    expect(find.text(_sheetTitle), findsNothing);
    // O redirect pro login continua acontecendo normalmente — só a sheet
    // de "sessão expirou" é que nunca deveria aparecer aqui.
    expect(find.text('TELA DE LOGIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
