import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/router/root_navigator_key.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Handler de background do FCM — precisa ser função de topo (não método),
/// anotada `vm:entry-point`, e registrada ANTES de `runApp` (ver `main.dart`).
/// Não faz nada de propósito: o payload `notification` já é exibido pelo SO
/// sozinho com o app em background/terminated; só a batida em foreground
/// (ver `_handleForegroundMessage`) precisa de tratamento nosso.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Liga o ciclo de vida do FCM ao login/logout — mesmo padrão de
/// `MembershipStatusCubit`/`ProfileCubit`: registra token ao autenticar,
/// desativa ao deslogar. Nunca deixa uma falha de configuração do Firebase
/// (ex.: google-services.json/GoogleService-Info.plist ainda não
/// adicionados) derrubar o app — só fica sem push até isso existir.
class PushNotificationService {
  PushNotificationService(this._repository, this._authCubit) {
    if (_authCubit.state is AuthAuthenticated) unawaited(_initialize());
    _authSubscription = _authCubit.stream.listen(_onAuthChanged);
  }

  final NotificationRepository _repository;
  final AuthCubit _authCubit;
  late final StreamSubscription<AuthState> _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _tapSubscription;
  bool _initialized = false;

  Future<void> _onAuthChanged(AuthState state) async {
    switch (state) {
      case AuthAuthenticated():
        await _initialize();
      case AuthUnauthenticated():
      case AuthSessionExpired():
        await _teardown();
      case AuthInitial():
      case AuthPasswordRecovery():
        break;
    }
  }

  Future<void> _initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      // Sem isto, o iOS mostra o banner nativo por cima MESMO com o app em
      // foreground, duplicando o feedback visual próprio que
      // `_handleForegroundMessage` já cuida de exibir (ver
      // `FirebaseMessaging.onMessage` abaixo). No Android isso é ignorado.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );

      final token = await messaging.getToken();
      if (token != null) await _registerToken(token);
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        _registerToken,
      );

      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      _tapSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_navigate);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _navigate(initialMessage);

      _initialized = true;
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
    }
  }

  Future<void> _registerToken(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    await _repository.registerToken(fcmToken: token, platform: platform);
  }

  Future<void> _teardown() async {
    if (!_initialized) return;
    _initialized = false;
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _tapSubscription?.cancel();
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _repository.deactivateToken(token);
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
    }
  }

  /// Em foreground o SO nunca exibe nada sozinho — mostra o feedback do
  /// próprio design system (mesma `AppBottomSheet` usada pros outros
  /// avisos do app), nunca um dialog genérico.
  void _handleForegroundMessage(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    final title = message.notification?.title;
    if (context == null || title == null) return;
    unawaited(
      AppBottomSheet.show(
        context,
        icon: _iconForType(message.data['type'] as String?),
        title: title,
        description: message.notification?.body,
        confirmLabel: context.l10n.notificationsForegroundCta,
        onConfirm: () => _navigate(message),
      ),
    );
  }

  void _navigate(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final type = message.data['type'] as String?;
    final matchId = message.data['matchId'] as String?;
    switch (type) {
      case 'goal':
      case 'full_time':
        if (matchId != null) context.push('/match/$matchId');
      case 'checkin':
      case 'tickets':
        context.push('/tickets');
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'goal':
      case 'full_time':
        return Icons.sports_soccer_rounded;
      case 'checkin':
      case 'tickets':
        return Icons.confirmation_number_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Future<void> dispose() async {
    await _authSubscription.cancel();
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _tapSubscription?.cancel();
  }
}
