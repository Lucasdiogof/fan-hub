import 'package:flutter/widgets.dart';

/// Permite que uma tela dentro do `IndexedStack` da Home (mantida viva ao
/// trocar de aba) saiba quando uma rota empurrada por cima dela — Perfil,
/// por exemplo — foi fechada, pra recarregar dados que podem ter mudado
/// enquanto ela estava oculta (ex.: status de sócio alterado no Perfil).
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
