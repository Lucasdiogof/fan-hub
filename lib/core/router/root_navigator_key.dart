import 'package:flutter/material.dart';

/// Chave do `Navigator` raiz do app — permite abrir UI (ex.: a bottom
/// sheet de sessão expirada) a partir de código que não tem um
/// `BuildContext` de tela nenhuma, como o interceptor HTTP do Supabase
/// (ver `SessionAwareHttpClient`/`main.dart`).
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
