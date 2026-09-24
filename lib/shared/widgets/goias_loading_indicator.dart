import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Escudo do clube ativo pulsando — mostra a identidade visual real (não um
/// traço tingido), já que o badge tem contraste suficiente pra qualquer
/// fundo (claro, escuro, ou sempre-escuro do `GlobalLoading`). [color] fica
/// só por compatibilidade de API com quem já chamava este widget; não tem
/// mais efeito, o badge sempre aparece com as cores reais. Via
/// `ClubBadge.activeClub` (não `StyledTeamBadge` direto) de propósito:
/// mantém o rollback de `useStyledTeamBadges` funcionando aqui também.
class GoiasLoadingBadge extends StatelessWidget {
  const GoiasLoadingBadge({this.size = 64, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // 2026-09-24: religado — com `useStyledTeamBadges=false` isto mostra
    // o escudo OFICIAL pulsando (não a mascote estilizada que motivou a
    // remoção de 2026-09-23), que é exatamente a identidade que este
    // widget sempre existiu pra mostrar.
    return ClubBadge.activeClub(size: size);
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
    // Anel indeterminado ao redor do brasão — reforça a leitura de
    // "carregando" além do pulso sozinho (feedback: parecia parado
    // demais). Gira sozinho (`CircularProgressIndicator` sem `value`),
    // sem precisar de um segundo `AnimationController`.
    final ringColor = widget.color ?? context.colors.primary;
    final ringSize = widget.size * 1.7;
    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              backgroundColor: ringColor.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation(
                ringColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          ScaleTransition(
            scale: _pulse,
            child: GoiasLoadingBadge(size: widget.size, color: widget.color),
          ),
        ],
      ),
    );
  }
}
