import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';

/// Um item selecionável num `AppOptionPicker` — [value] é o que volta pra
/// quem chamou, [label] é o texto mostrado.
class AppPickerOption<T> {
  const AppPickerOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Lista de opções pra escolher UMA — estado, cidade, nacionalidade, país,
/// setor de ingresso etc. Cada um desses pickers reimplementava a mesma
/// combinação "sheet + `ListView.separated` com altura fixa" do zero; isto
/// centraliza esse padrão numa só implementação (adaptativa: sheet no
/// mobile, `Dialog` no desktop, via `AppModalSheet`).
class AppOptionPicker {
  const AppOptionPicker._();

  static Future<T?> show<T>(
    BuildContext context, {
    required List<AppPickerOption<T>> options,
    T? selected,
  }) {
    return AppModalSheet.show<T>(
      context,
      builder: (sheetContext) =>
          _OptionList<T>(options: options, selected: selected),
    );
  }
}

class _OptionList<T> extends StatelessWidget {
  const _OptionList({required this.options, required this.selected});

  final List<AppPickerOption<T>> options;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: options.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
          itemBuilder: (itemContext, index) {
            final option = options[index];
            return ListTile(
              title: Text(
                option.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              trailing: option.value == selected
                  ? Icon(Icons.check_rounded, color: colors.primary)
                  : null,
              onTap: () => Navigator.of(itemContext).pop(option.value),
            );
          },
        ),
      ),
    );
  }
}
