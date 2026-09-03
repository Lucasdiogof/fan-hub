import 'dart:io';

import 'package:flutter/foundation.dart';

/// Mesma convenção de string já usada em `push_notification_service.dart`
/// (`platform` gravado em `user_notification_tokens`) — só que também
/// cobre `web` (a PWA nunca registra token de push, mas participa do
/// release gate). `kIsWeb` é checado ANTES de tocar `Platform.*` de
/// propósito — `dart:io` nunca deve ser chamado em runtime web.
String currentPlatformKey() {
  if (kIsWeb) return 'web';
  return Platform.isIOS ? 'ios' : 'android';
}
