import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/release/release_gate.dart';
import 'package:goias_app/core/router/splash_gate.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
import 'package:goias_app/features/splash/presentation/widgets/static_logo_splash.dart';
import 'package:goias_app/features/splash/presentation/widgets/video_splash_view.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Mesma cor do `flutter_native_splash` (pubspec.yaml) — não é branco puro
/// de propósito, é a continuação exata da splash nativa, que não tem uma
/// variante dark configurada.
const _splashBackground = Color(0xFFF6F8F7);

/// O conteúdo (vídeo ou o brasão estático) dura poucos segundos — isto é só
/// a rede de segurança. Cobre autoplay bloqueado, imagem que falha ao
/// carregar, erro de rede/decodificação e qualquer outro jeito da splash
/// não terminar sozinha. Começa a contar no `initState()`, antes de
/// qualquer tentativa de mostrar conteúdo — é a única coisa que garante que
/// o usuário nunca fica preso na splash.
const _fallbackTimeout = Duration(seconds: 7);

/// iOS no navegador (Safari, PWA instalado, WebView do WhatsApp — todos
/// baseados em WebKit) bloqueia autoplay de vídeo silenciosamente, sem
/// lançar nenhum erro: o vídeo fica parado no primeiro frame pra sempre.
/// Uma sequência de imagens animadas já foi tentada aqui e tinha o mesmo
/// problema de fundo (peso de imagem grande demais pra terminar de
/// carregar antes do timer de segurança em rede móvel ruim) — pra essa
/// plataforma restrita, o mais confiável é o mais simples: só o brasão
/// oficial parado sobre o fundo da splash (`StaticLogoSplash`), sem vídeo
/// nem timeline. Mesmo `kIsWeb && defaultTargetPlatform == TargetPlatform.
/// iOS` usado em `ClubBadge` pro bug do CanvasKit — mesma raiz (Safari/
/// WebKit se comportando diferente do resto), sinalização de plataforma
/// consistente no app inteiro.
bool get _isIosWeb => kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Pura (sem `BuildContext`/widget) — decide vídeo (`VideoSplashView`) vs.
/// brasão estático (`StaticLogoSplash`), testável sozinha, mesmo padrão do
/// `capabilityGateRedirect`. `splashVideoAsset` vem de `ClubConfig.assets.
/// splashVideo` — `null` (clube sem vídeo oficial ainda) nunca cai pro
/// vídeo de outro clube, sempre pro brasão estático.
bool shouldPlaySplashVideo({
  required bool isIosWeb,
  required String? splashVideoAsset,
}) => !isIosWeb && splashVideoAsset != null;

class SplashVideoPage extends StatefulWidget {
  const SplashVideoPage({super.key});

  @override
  State<SplashVideoPage> createState() => _SplashVideoPageState();
}

class _SplashVideoPageState extends State<SplashVideoPage> {
  late final Future<void> _homePreload;
  bool _finished = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _homePreload = _preloadDestination();
    // Antes de tentar mostrar qualquer conteúdo, de propósito — se o
    // vídeo/precache nunca resolver, a splash ainda sai sozinha.
    _fallbackTimer = Timer(_fallbackTimeout, _finishSplash);
  }

  /// Se o usuário vai cair na Home (autenticado), pré-carrega o `HomeCubit`
  /// (singleton — ver `injection_container.dart`) por trás do próprio
  /// conteúdo da splash, em paralelo com ele tocando. Quando a splash
  /// termina, a Home já está pronta e a transição não passa por um segundo
  /// loading do outro lado. Indo pro Login não tem nada assíncrono pra
  /// esperar.
  Future<void> _preloadDestination() async {
    final authState = sl<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;
    final homeCubit = sl<HomeCubit>();
    if (homeCubit.state.status == LoadStatus.loading) {
      await homeCubit.stream.firstWhere(
        (state) => state.status != LoadStatus.loading,
      );
    }
    final membershipCubit = sl<MembershipStatusCubit>();
    if (membershipCubit.state.status != LoadStatus.success) {
      await membershipCubit.stream.firstWhere(
        (state) => state.status == LoadStatus.success,
      );
    }
  }

  /// Ponto único de conclusão da splash — idempotente por causa do guard
  /// `_finished`, então não importa se quem chamou foi o fim normal do
  /// conteúdo, um erro de carregamento ou o timer de segurança disparando
  /// perto de um desses: só a primeira chamada vale, e o usuário nunca
  /// fica preso esperando.
  void _finishSplash() {
    if (_finished || !mounted) return;
    _finished = true;
    _fallbackTimer?.cancel();
    // Sem fade interno aqui: o conteúdo fica congelado no último estado (ou
    // na cor de fundo, se nem chegou a aparecer) e a transição de saída
    // (fade de verdade) é a da própria rota '/splash' no router — evita
    // mostrar a cor de fundo "pelada" entre a splash e a Home/Login.
    unawaited(_completeGateAfterPreload());
  }

  /// Só libera o gate (e portanto a navegação) depois que o pré-carregamento
  /// da Home E a checagem de versão mínima (`ReleaseGate`) também tiverem
  /// terminado — na prática quase sempre já terminaram nesse ponto (rodam
  /// em paralelo com a splash), então isso raras vezes segura a splash por
  /// mais tempo do que ela já levaria sozinha. `ReleaseGate.ensureChecked()`
  /// nunca lança (timeout próprio, fail-open) — `Future.wait` aqui é seguro.
  Future<void> _completeGateAfterPreload() async {
    await Future.wait([_homePreload, sl<ReleaseGate>().ensureChecked()]);
    sl<SplashGate>().complete();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Conteúdo visível desde o primeiro frame — sem período invisível
    // esperando um "pronto pra revelar" (removido 2026-09-22, junto com a
    // revelação em círculo antiga). Esse período de espera coincidia
    // exatamente com o pior trecho do cold start (engine anexando,
    // primeiros frames pulados/travados — visto no log real: "Davey!
    // duration=905ms" bem nessa janela), e o usuário via isso como a
    // splash "piscando"/aparecendo duas vezes. Mostrar direto elimina essa
    // janela em vez de tentar decorar em cima dela.
    return Scaffold(
      backgroundColor: _splashBackground,
      body: _buildSplashContent(),
    );
  }

  /// `splashVideo == null` (clube sem vídeo oficial ainda — ver
  /// `ClubAssets.splashVideo`) cai pro mesmo fallback do iOS Web: nunca um
  /// vídeo de outro clube.
  Widget _buildSplashContent() {
    final splashVideo = sl<ClubConfig>().assets.splashVideo;
    if (!shouldPlaySplashVideo(
      isIosWeb: _isIosWeb,
      splashVideoAsset: splashVideo,
    )) {
      return StaticLogoSplash(onReady: () {}, onCompleted: _finishSplash);
    }
    return VideoSplashView(
      videoAsset: splashVideo!,
      onReady: () {},
      onCompleted: _finishSplash,
      onFailure: _finishSplash,
    );
  }
}
