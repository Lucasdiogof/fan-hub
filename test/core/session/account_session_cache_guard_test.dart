import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/session/account_session_cache_guard.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/store/fakes/fake_store_repository.dart';

/// Mesmo padrão de `_FakeAuthRepository` em `session_expiry_listener_test.dart`
/// — só os membros que o `AuthCubit` de fato usa têm comportamento real.
class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthSessionEvent>.broadcast();
  AuthUser? _user = const AuthUser(id: 'u1', email: 'conta.a@goias.com');

  void emitSignedOut() {
    _user = null;
    _controller.add(AuthSessionEvent.signedOut);
  }

  void emitSessionExpired() {
    _user = null;
    _controller.add(AuthSessionEvent.sessionExpired);
  }

  void emitSignedIn(String userId) {
    _user = AuthUser(id: userId, email: '$userId@goias.com');
    _controller.add(AuthSessionEvent.signedIn);
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
    emitSignedOut();
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthRepository authRepo;
  late AuthCubit authCubit;
  late FakeStoreRepository storeRepo;
  late CartCubit cartCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'arena_best_quiz_torcedor': 8,
      'guess_player_seen_ids': ['p1'],
    });
    authRepo = _FakeAuthRepository();
    authCubit = AuthCubit(authRepo);
    storeRepo = FakeStoreRepository();
    cartCubit = CartCubit(storeRepo);

    // Simula a "Conta A" com dados reais no carrinho antes do guard
    // existir — mesma ordem que aconteceria de verdade (usuário usa o
    // app, depois desloga).
    await cartCubit.addItem(
      const CartItem(
        id: 'i1',
        productId: 'p1',
        productName: 'Camisa',
        thumbnail: 'thumb.jpg',
        size: 'M',
        unitPrice: 299.90,
      ),
    );
  });

  tearDown(() async {
    await authCubit.close();
    await cartCubit.close();
    await authRepo.dispose();
  });

  test('conta A tem dados antes do logout (sanity check do setUp)', () {
    expect(cartCubit.state.cart.items, isNotEmpty);
  });

  test('logout (signedOut) limpa carrinho e cache local de jogos', () async {
    AccountSessionCacheGuard(authCubit, cartCubit);

    authRepo.emitSignedOut();
    await pumpEventQueue();

    expect(cartCubit.state.cart.items, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });

  test('sessão expirada (sessionExpired) limpa os mesmos dados que o logout', () async {
    AccountSessionCacheGuard(authCubit, cartCubit);

    authRepo.emitSessionExpired();
    await pumpEventQueue();

    expect(cartCubit.state.cart.items, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });

  test('login (signedIn) nunca limpa nada por engano', () async {
    AccountSessionCacheGuard(authCubit, cartCubit);

    authRepo.emitSignedIn('outra-conta');
    await pumpEventQueue();

    expect(cartCubit.state.cart.items, isNotEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isNotEmpty);
  });

  test(
    'troca de conta completa: logout da conta A não deixa nada pra conta B',
    () async {
      AccountSessionCacheGuard(authCubit, cartCubit);

      // Conta A desloga.
      authRepo.emitSignedOut();
      await pumpEventQueue();

      // Conta B loga no mesmo aparelho e abre o carrinho/Arena.
      authRepo.emitSignedIn('conta-b');
      await cartCubit.load();

      expect(cartCubit.state.cart.items, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    },
  );
}
