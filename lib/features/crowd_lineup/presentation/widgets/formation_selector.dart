import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';

class FormationSelector extends StatefulWidget {
  const FormationSelector({
    required this.selectedId,
    required this.onSelect,
    this.enabled = true,
    super.key,
  });

  final String selectedId;
  final ValueChanged<String> onSelect;
  final bool enabled;

  @override
  State<FormationSelector> createState() => _FormationSelectorState();
}

class _FormationSelectorState extends State<FormationSelector> {
  final _keys = {for (final formation in formations) formation.id: GlobalKey()};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusSelected());
  }

  @override
  void didUpdateWidget(covariant FormationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusSelected());
    }
  }

  /// Formação selecionada some da tela se ela estiver longe no scroll
  /// horizontal (lista de formações cresce, a escolhida antes pode acabar
  /// ficando fora da área visível) — sempre traz ela pro centro ao abrir a
  /// tela ou quando a seleção muda.
  void _focusSelected() {
    final context = _keys[widget.selectedId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final formation in formations) ...[
            KeyedSubtree(
              key: _keys[formation.id],
              child: _Chip(
                label: formation.label,
                selected: formation.id == widget.selectedId,
                onTap: widget.enabled
                    ? () => widget.onSelect(formation.id)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.primary : colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: selected ? colors.onPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
