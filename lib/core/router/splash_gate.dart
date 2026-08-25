import 'package:flutter/foundation.dart';

/// Controla o gate de bootstrap "splash com vídeo": enquanto `done` for
/// `false`, o redirect do [GoRouter] força qualquer rota inicial pra
/// `/splash`. Ao chamar [complete], notifica o `refreshListenable` do
/// router, que reavalia o redirect — como a sessão do Supabase já foi
/// resolvida antes de `runApp` (ver `AuthCubit._emitFromSession`), o
/// destino certo (Home ou Login) já está pronto no mesmo instante.
class SplashGate extends ChangeNotifier {
  bool _done = false;

  bool get done => _done;

  void complete() {
    if (_done) return;
    _done = true;
    notifyListeners();
  }
}
