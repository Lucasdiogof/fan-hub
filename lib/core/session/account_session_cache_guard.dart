import 'dart:async';

import 'package:goias_app/core/session/local_game_cache.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_cubit.dart';

/// Singleton do app (mesmo padrão de `MembershipStatusCubit`) — ouve
/// `AuthCubit` pra garantir que nada vinculado à conta anterior (carrinho,
/// progresso local de jogos) sobrevive num logout ou numa sessão expirada,
/// nem é herdado por outra conta que faça login em seguida no mesmo
/// aparelho. Preferências realmente globais (tema, idioma, volume do
/// player) nunca passam por aqui.
class AccountSessionCacheGuard {
  AccountSessionCacheGuard(AuthCubit authCubit, this._cartCubit) {
    _authSubscription = authCubit.stream.listen(_onAuthChanged);
  }

  final CartCubit _cartCubit;
  late final StreamSubscription<AuthState> _authSubscription;

  void _onAuthChanged(AuthState state) {
    switch (state) {
      case AuthUnauthenticated():
      case AuthSessionExpired():
        unawaited(_clearAll());
      case AuthAuthenticated():
      case AuthInitial():
      case AuthPasswordRecovery():
        break;
    }
  }

  Future<void> _clearAll() async {
    await clearAccountScopedLocalCache();
    await _cartCubit.clear();
  }

  Future<void> dispose() => _authSubscription.cancel();
}
