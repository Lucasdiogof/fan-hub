import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/shared/widgets/session_expired_sheet.dart';

/// Mostra a bottom sheet global de sessão expirada quando [authCubit] emite
/// `AuthSessionExpired` — nunca depois de um logout comum (`AuthUnauthenticated`
/// simples), só perda involuntária de sessão (ver `AuthSessionEvent.sessionExpired`).
///
/// Ouve o stream direto (não um `BlocListener`) porque precisa funcionar
/// mesmo sem um `BuildContext` de tela por perto no momento exato da perda de
/// sessão — usa [navigatorKey] em vez disso, então continua válido mesmo que
/// o router já tenha trocado de rota por baixo. `AuthCubit` só emite
/// `AuthSessionExpired` de novo depois de um novo login bem-sucedido (Cubit
/// nunca reemite o mesmo estado duas vezes seguidas — ver `emit` do pacote
/// `bloc`), então mesmo várias chamadas detectando a perda de sessão ao
/// mesmo tempo resultam numa única emissão e, portanto, numa única sheet.
class SessionExpiryListener extends StatefulWidget {
  const SessionExpiryListener({
    required this.authCubit,
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  final AuthCubit authCubit;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<SessionExpiryListener> createState() => _SessionExpiryListenerState();
}

/// Quantas vezes tenta de novo, um frame por vez, se o `Navigator` de
/// [SessionExpiryListener.navigatorKey] ainda não tiver `context` no frame
/// em que o callback dispara (ver comentário em [_scheduleSheet] — reproduzido
/// em teste: o `GoRouter` pode desmontar/remontar o `Navigator` por causa do
/// próprio redirect que esse mesmo evento dispara, deixando `currentContext`
/// momentaneamente nulo por um frame). Generoso o bastante pra nunca ser o
/// motivo da sheet não aparecer, sem arriscar um loop infinito se o
/// `navigatorKey` simplesmente nunca for anexado a nada.
const _maxContextRetries = 5;

class _SessionExpiryListenerState extends State<SessionExpiryListener> {
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.authCubit.stream.listen((state) {
      if (state is! AuthSessionExpired) return;
      _scheduleSheet();
    });
  }

  // Espera o próximo frame de propósito: o `GoRouter` reage ao MESMO evento
  // (via `refreshListenable`) trocando de rota nesse meio tempo — como ele
  // gerencia o `Navigator` de forma declarativa (lista de páginas), empurrar
  // a sheet ANTES do redirect assentar corre o risco de ela ser descartada
  // quando o `GoRouter` reconcilia a lista na sequência (reproduzido em
  // teste: a sheet "fechava sozinha" quase instantaneamente, sem nenhuma
  // interação). Esperar o próximo frame garante que o redirect já aconteceu.
  //
  // Mas esse MESMO redirect pode, por um frame, desmontar/remontar o
  // `Navigator` do [widget.navigatorKey] — se o callback disparar
  // exatamente nesse frame, `currentContext` vem nulo. Tentar de novo no
  // frame seguinte (em vez de desistir) evita perder a sheet nesse caso
  // raro (também reproduzido em teste).
  void _scheduleSheet([int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = widget.navigatorKey.currentContext;
      if (context != null) {
        unawaited(showSessionExpiredSheet(context));
      } else if (attempt < _maxContextRetries) {
        _scheduleSheet(attempt + 1);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
