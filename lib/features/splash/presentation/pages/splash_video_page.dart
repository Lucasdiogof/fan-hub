import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/splash_gate.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
import 'package:goias_app/features/splash/presentation/widgets/circle_reveal_clipper.dart';
import 'package:goias_app/features/splash/presentation/widgets/reveal_glow_painter.dart';
import 'package:goias_app/features/splash/presentation/widgets/static_logo_splash.dart';
import 'package:goias_app/features/splash/presentation/widgets/video_splash_view.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Mesma cor do `flutter_native_splash` (pubspec.yaml) — não é branco puro
/// de propósito, é a continuação exata da splash nativa, que não tem uma
/// variante dark configurada.
const _splashBackground = Color(0xFFF6F8F7);

const _startRadius = 14.0;
const _revealDuration = Duration(milliseconds: 550);

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
/// nem timeline. Em qualquer outro ambiente (Android, iOS nativo, Web fora
/// do iOS) o vídeo `goias_splash.mp4` continua normalmente, sem mudança.
/// Mesmo `kIsWeb && defaultTargetPlatform == TargetPlatform.iOS` usado em
/// `ClubBadge` pro bug do CanvasKit — mesma raiz (Safari/WebKit se comportando diferente
/// do resto), sinalização de plataforma consistente no app inteiro.
bool get _shouldUseStaticLogo =>
    kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class SplashVideoPage extends StatefulWidget {
  const SplashVideoPage({super.key});

  @override
  State<SplashVideoPage> createState() => _SplashVideoPageState();
}

class _SplashVideoPageState extends State<SplashVideoPage>
    with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _revealAnimation;
  late final Future<void> _homePreload;
  bool _finished = false;
  bool _revealed = false;
  Timer? _fallbackTimer;

  /// O conteúdo (vídeo/brasão) troca de pai conforme a revelação avança
  /// (`Opacity` → `ClipPath` dentro de `Stack` → filho direto). Sem uma
  /// `GlobalKey` estável, essa troca de pai faz o Flutter remontar o
  /// `VideoSplashView` — o controller reinicia e o vídeo volta ao primeiro
  /// frame ("pisca" no começo da revelação). A key preserva o mesmo elemento
  /// nas três posições, então o vídeo toca sem reiniciar.
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: _revealDuration,
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutCubic,
    );
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
    if (homeCubit.state.loading) {
      await homeCubit.stream.firstWhere((state) => !state.loading);
    }
    final membershipCubit = sl<MembershipStatusCubit>();
    if (membershipCubit.state.status != LoadStatus.success) {
      await membershipCubit.stream.firstWhere(
        (state) => state.status == LoadStatus.success,
      );
    }
  }

  /// Chamado pelo conteúdo (vídeo ou imagens) quando está pronto pra
  /// aparecer — dispara a revelação em círculo. Idempotente: só a primeira
  /// chamada conta.
  void _reveal() {
    if (_revealed || !mounted) return;
    _revealed = true;
    _revealController.forward();
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
  /// da Home também tiver terminado — na prática quase sempre já terminou
  /// nesse ponto (rodou em paralelo com a splash), então isso raras vezes
  /// segura a splash por mais tempo do que ela já levaria sozinha.
  Future<void> _completeGateAfterPreload() async {
    await _homePreload;
    sl<SplashGate>().complete();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: _splashBackground,
      body: AnimatedBuilder(
        animation: _revealAnimation,
        child: KeyedSubtree(key: _contentKey, child: _buildSplashContent()),
        builder: (context, child) {
          // `child` PRECISA continuar na árvore mesmo antes de `_revealed`
          // virar true — é o próprio `child` (vídeo/logo) que chama
          // `_reveal()` quando fica pronto; se ele nunca for montado (ex.:
          // um branch anterior aqui devolvia um `SizedBox.expand()` solto,
          // sem `child` dentro), nada nunca dispara `onReady()` e a splash
          // fica presa até o timer de segurança — tela branca até o fim.
          if (!_revealed) return Opacity(opacity: 0, child: child);
          if (reducedMotion) {
            return Opacity(opacity: _revealAnimation.value, child: child);
          }

          final t = _revealAnimation.value;
          if (t >= 1) return child!;

          final center = Offset(size.width / 2, size.height / 2);
          final maxRadius = sqrt(
            pow(size.width / 2, 2) + pow(size.height / 2, 2),
          );
          final radius = Tween<double>(
            begin: _startRadius,
            end: maxRadius,
          ).transform(t);

          return Stack(
            fit: StackFit.expand,
            children: [
              ClipPath(
                clipper: CircleRevealClipper(center: center, radius: radius),
                child: child,
              ),
              CustomPaint(
                painter: RevealGlowPainter(
                  center: center,
                  radius: radius,
                  opacity: 1 - t,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSplashContent() {
    if (_shouldUseStaticLogo) {
      return StaticLogoSplash(onReady: _reveal, onCompleted: _finishSplash);
    }
    return VideoSplashView(
      onReady: _reveal,
      onCompleted: _finishSplash,
      onFailure: _finishSplash,
    );
  }
}
