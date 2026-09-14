import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/home/presentation/widgets/main_navigation_items.dart';

const _barHeight = 78.0;
const _crestSize = 68.0;
const _crestImageSize = 58.0;
const _crestRaise = 24.0;
const _sideIconSize = 25.0;
const _labelFontSize = 11.0;
const _crestGapWidth = _crestSize + 18;
const _animationDuration = Duration(milliseconds: 220);

/// Bottom nav flutuante do shell principal — 4 abas lineares em volta de um
/// quinto slot central que não é um ícone, é o escudo oficial do clube ativo
/// (`ClubConfig.assets.crestBadge`), ligeiramente elevado sobre a barra. Home é
/// esse escudo, não um item normal: não tem label visível (só
/// `Semantics`), e o toque nele sempre chama [onSelected] com
/// [homeTabIndex]. Ver `main_navigation_items.dart` pra ordem/índices das
/// abas — mudar a ordem das abas é lá, não aqui.
class GoiasBottomNavigationBar extends StatelessWidget {
  const GoiasBottomNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final capabilities = sl<ClubConfig>().capabilities;
    final items = mainNavItems(context, capabilities);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottomInset + AppSpacing.sm,
      ),
      child: SizedBox(
        height: _barHeight + _crestRaise,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _barHeight,
              child: _NavPill(
                isDark: isDark,
                colors: colors,
                child: Row(
                  children: [
                    Expanded(
                      child: _navSlot(
                        index: jogosTabIndex,
                        items: items,
                        capabilities: capabilities,
                        selectedIndex: selectedIndex,
                        onSelected: onSelected,
                      ),
                    ),
                    Expanded(
                      child: _navSlot(
                        index: socioTabIndex,
                        items: items,
                        capabilities: capabilities,
                        selectedIndex: selectedIndex,
                        onSelected: onSelected,
                      ),
                    ),
                    const SizedBox(width: _crestGapWidth),
                    Expanded(
                      child: _navSlot(
                        index: lojaTabIndex,
                        items: items,
                        capabilities: capabilities,
                        selectedIndex: selectedIndex,
                        onSelected: onSelected,
                      ),
                    ),
                    Expanded(
                      child: _navSlot(
                        index: midiaTabIndex,
                        items: items,
                        capabilities: capabilities,
                        selectedIndex: selectedIndex,
                        onSelected: onSelected,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: _HomeCrestButton(
                  selected: selectedIndex == homeTabIndex,
                  onTap: () => onSelected(homeTabIndex),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// M4.2A — aba sem a capability correspondente NUNCA aparece: vira um
/// espaço vazio (nunca escondida trocando o layout de 4 `Expanded` pra 2/3,
/// que reajustaria proporções e criaria um "pulo" visual toda vez que a
/// capability mudasse) — no Goiás (todas `true`) o resultado é
/// pixel-idêntico ao de antes desta etapa, nunca uma regressão perceptível.
Widget _navSlot({
  required int index,
  required List<MainNavItemData> items,
  required ClubCapabilities capabilities,
  required int selectedIndex,
  required ValueChanged<int> onSelected,
}) {
  if (!isTabEnabled(index, capabilities)) return const SizedBox.shrink();
  return _SideNavItem(
    data: items[index],
    selected: selectedIndex == index,
    onTap: () => onSelected(index),
  );
}

/// Superfície da pílula flutuante — cor, borda, sombra e o degradê quase
/// imperceptível do tema escuro moram só aqui, isolados do conteúdo (itens
/// laterais) que a `Row` do pai desenha por cima.
class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.isDark,
    required this.colors,
    required this.child,
  });

  final bool isDark;
  final AppColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        // Gradiente vertical quase imperceptível só no escuro — topo um
        // fiapo mais claro que a base, pra sugerir profundidade sem lembrar
        // "gaming RGB". No claro a superfície fica sólida mesmo.
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(colors.surface, colors.surfaceRaised, 0.55)!,
                  colors.surface,
                ],
              )
            : null,
        color: isDark ? null : colors.surface,
        border: Border.all(
          color: isDark
              ? colors.primary.withValues(alpha: 0.14)
              : colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: child,
      ),
    );
  }
}

class _SideNavItem extends StatefulWidget {
  const _SideNavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final MainNavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SideNavItem> createState() => _SideNavItemState();
}

class _SideNavItemState extends State<_SideNavItem>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: _animationDuration,
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.08), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 1),
  ]).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOutCubic));

  @override
  void didUpdateWidget(covariant _SideNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      if (MediaQuery.of(context).disableAnimations) return;
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = widget.selected ? colors.primary : colors.textSecondary;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.data.label,
      child: InkWell(
        onTap: widget.onTap,
        customBorder: const StadiumBorder(),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: color),
                  duration: _animationDuration,
                  curve: Curves.easeOut,
                  builder: (context, animatedColor, _) => Icon(
                    widget.selected
                        ? widget.data.selectedIcon
                        : widget.data.icon,
                    size: _sideIconSize,
                    color: animatedColor,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: _animationDuration,
                curve: Curves.easeOut,
                builder: (context, animatedColor, _) => Text(
                  widget.data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: _labelFontSize,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: animatedColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                opacity: widget.selected ? 1 : 0,
                duration: _animationDuration,
                curve: Curves.easeOut,
                child: Container(
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O elemento central — escudo do Goiás sobre uma superfície circular
/// "elevada" (própria sombra, própria cor, ligeiramente mais clara que a
/// pílula atrás dela no escuro), representando a Home. Sem ícone de casa,
/// sem label visível (ver doc de [GoiasBottomNavigationBar]).
class _HomeCrestButton extends StatefulWidget {
  const _HomeCrestButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  State<_HomeCrestButton> createState() => _HomeCrestButtonState();
}

class _HomeCrestButtonState extends State<_HomeCrestButton> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: l10n.navHome,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // Área de toque generosa: cobre o escudo e a "reentrância" central
        // da barra logo abaixo dele, não só o círculo visível.
        child: SizedBox(
          width: _crestGapWidth,
          height: _barHeight + _crestRaise,
          child: Column(
            children: [
              AnimatedScale(
                scale: widget.selected ? 1.045 : 1.0,
                duration: _animationDuration,
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: _animationDuration,
                  curve: Curves.easeOut,
                  width: _crestSize,
                  height: _crestSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceRaised,
                    border: Border.all(
                      color: colors.primary.withValues(
                        alpha: widget.selected ? 0.32 : 0.16,
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.42 : 0.14,
                        ),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                      if (widget.selected)
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.18),
                          blurRadius: 18,
                        ),
                    ],
                  ),
                  child: Image.asset(
                    sl<ClubConfig>().assets.crestBadge,
                    width: _crestImageSize,
                    height: _crestImageSize,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnimatedOpacity(
                  opacity: widget.selected ? 1 : 0,
                  duration: _animationDuration,
                  curve: Curves.easeOut,
                  child: Container(
                    width: 30,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
