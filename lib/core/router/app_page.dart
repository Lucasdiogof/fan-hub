import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// No Flutter Web, `Theme.of(context).platform` detecta iOS pelo user-agent
/// e o `PageTransitionsTheme` padrão instala o `_CupertinoBackGestureDetector`
/// (gesto de arrastar da borda) em toda rota — mesmo dentro do navegador. No
/// PWA instalado no iPhone, esse gesto do Flutter coexiste com o gesto nativo
/// do WKWebView sobre `window.history` (que o go_router espelha via
/// `usePathUrlStrategy()`), e um único arrasto disparava duas navegações de
/// "voltar" ao mesmo tempo. `NoTransitionPage` nunca passa pelo
/// `PageTransitionsTheme` (sobrescreve `buildTransitions` direto), então o
/// gesto do Flutter nunca chega a ser instalado — o gesto nativo do navegador
/// fica como único responsável por voltar. Fora da web, mantém `MaterialPage`
/// normal.
Page<void> appPage(GoRouterState state, Widget child) => kIsWeb
    ? NoTransitionPage<void>(key: state.pageKey, child: child)
    : MaterialPage<void>(key: state.pageKey, child: child);

/// Mesmo princípio de [appPage], pra `Navigator.push` avulso fora do router
/// (poucos casos no app; a maioria das rotas passa pelo go_router acima).
Route<T> appRoute<T>(Widget child) => kIsWeb
    ? PageRouteBuilder<T>(
        pageBuilder: (_, _, _) => child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      )
    : MaterialPageRoute<T>(builder: (_) => child);
