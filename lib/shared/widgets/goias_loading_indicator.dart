import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_assets.dart';

/// Brasão oficial do Goiás pulsando — mostra a arte real (não um traço
/// tingido), já que o próprio brasão tem contraste suficiente pra qualquer
/// fundo (claro, escuro, ou sempre-escuro do `GlobalLoading`). [color] fica
/// só por compatibilidade de API com quem já chamava este widget; não tem
/// mais efeito, o brasão sempre aparece com as cores reais.
class GoiasLoadingBadge extends StatelessWidget {
  const GoiasLoadingBadge({this.size = 64, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.goiasCrestBadge,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Indicador de carregamento inline (não bloqueante, sem overlay) — mesma
/// identidade visual do `GlobalLoading`, só que menor, pra substituir um
/// `CircularProgressIndicator` solto em telas/seções ainda buscando dados.
class GoiasLoadingIndicator extends StatefulWidget {
  const GoiasLoadingIndicator({this.size = 44, this.color, super.key});

  final double size;
  final Color? color;

  @override
  State<GoiasLoadingIndicator> createState() => _GoiasLoadingIndicatorState();
}

class _GoiasLoadingIndicatorState extends State<GoiasLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = Tween<double>(
    begin: 0.92,
    end: 1.08,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: GoiasLoadingBadge(size: widget.size, color: widget.color),
    );
  }
}
