import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Brasão do Goiás tingido de uma cor sólida — o SVG em si é só um traço
/// branco monocromático, então aplicamos a cor direto nele (sem nenhum
/// fundo/selo ao redor) via `colorFilter`. [color] é opcional: por padrão o
/// brasão segue o tema atual (branco no dark, verde da marca no light) —
/// no dark o fundo já é um verde bem escuro, então o verde padrão da marca
/// quase desaparece nele; só quem usa sobre um fundo sempre escuro
/// independente do tema (ver `GlobalLoading`) passa branco explícito.
class GoiasLoadingBadge extends StatelessWidget {
  const GoiasLoadingBadge({this.size = 64, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        AppAssets.goiasCrest,
        colorFilter: ColorFilter.mode(
          color ?? (isDark ? Colors.white : context.colors.primary),
          BlendMode.srcIn,
        ),
      ),
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
