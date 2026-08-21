import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Padrão visual único pro `*` de campo obrigatório — não escrito à mão em
/// cada widget de formulário.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {required this.isRequired, super.key});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text.rich(
      TextSpan(
        text: label,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textSecondary),
        children: isRequired ? [TextSpan(text: ' *', style: TextStyle(color: colors.primary))] : null,
      ),
    );
  }
}

class RegistrationTextField extends StatefulWidget {
  const RegistrationTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.onBlur,
    this.prefixText,
    this.prefix,
    this.suffixIcon,
    this.hintText,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool isRequired;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final VoidCallback? onBlur;
  final String? prefixText;
  final Widget? prefix;
  final Widget? suffixIcon;
  final String? hintText;
  final TextCapitalization textCapitalization;

  @override
  State<RegistrationTextField> createState() => _RegistrationTextFieldState();
}

/// Controller explícito (não `initialValue`) porque este campo precisa
/// refletir tanto o que o usuário digita quanto atualizações externas (ex.:
/// CEP preenchendo Logradouro/Bairro/Cidade automaticamente) — com
/// `initialValue`, o texto na tela ficaria preso no valor de quando o
/// widget foi montado, mesmo com o Cubit já atualizado.
class _RegistrationTextFieldState extends State<RegistrationTextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant RegistrationTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(widget.label, isRequired: widget.isRequired),
        const SizedBox(height: 6),
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) widget.onBlur?.call();
          },
          child: TextFormField(
            controller: _controller,
            onChanged: widget.onChanged,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textCapitalization: widget.textCapitalization,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              prefixText: widget.prefixText,
              prefix: widget.prefix,
              suffixIcon: widget.suffixIcon,
              hintText: widget.hintText,
              hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colors.textHint),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              filled: true,
              fillColor: colors.surface,
              errorText: widget.errorText,
              errorMaxLines: 2,
              errorStyle: TextStyle(color: colors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: colors.primary),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Seletor tocável com o mesmo visual de [RegistrationTextField], usado
/// quando o valor vem de um picker (data, estado) em vez de digitação livre.
class RegistrationPickerField extends StatelessWidget {
  const RegistrationPickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.isRequired = false,
    this.errorText,
    this.placeholder = 'Selecionar',
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isRequired;
  final String? errorText;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, isRequired: isRequired),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: errorText != null ? colors.primary : colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? colors.textPrimary : colors.textHint,
                    ),
                  ),
                ),
                Icon(Icons.expand_more_rounded, size: 18, color: colors.textHint),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText!, style: TextStyle(fontSize: 12, color: colors.primary)),
        ],
      ],
    );
  }
}

class RegistrationOption<T> {
  const RegistrationOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Dropdown de verdade (bottom sheet com busca leve) — usado por
/// nacionalidade e país do endereço, entre outros.
class RegistrationDropdownField<T> extends StatelessWidget {
  const RegistrationDropdownField({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.errorText,
    this.placeholder = 'Selecionar',
    super.key,
  });

  final String label;
  final List<RegistrationOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final bool isRequired;
  final String? errorText;
  final String placeholder;

  String get _selectedLabel {
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return '';
  }

  Future<void> _open(BuildContext context) async {
    final colors = context.colors;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.7,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: options.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
              itemBuilder: (itemContext, index) {
                final option = options[index];
                return ListTile(
                  title: Text(
                    option.label,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                  ),
                  trailing: option.value == value ? Icon(Icons.check_rounded, color: colors.primary) : null,
                  onTap: () {
                    onChanged(option.value);
                    Navigator.of(itemContext).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationPickerField(
      label: label,
      value: _selectedLabel,
      isRequired: isRequired,
      errorText: errorText,
      placeholder: placeholder,
      onTap: () => _open(context),
    );
  }
}

class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({required this.options, required this.value, required this.onChanged, super.key});

  final List<(T value, String label)> options;
  final T? value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.secondary, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: value == option.$1 ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: value == option.$1 ? colors.onPrimary : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
