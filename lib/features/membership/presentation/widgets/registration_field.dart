import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goias_app/core/theme/app_colors.dart';

class RegistrationTextField extends StatelessWidget {
  const RegistrationTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.prefixText,
    this.suffixIcon,
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? prefixText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          key: readOnly ? ValueKey(value) : null,
          initialValue: value,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            prefixText: prefixText,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: colors.surface,
            errorText: errorText,
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
              borderSide: BorderSide(color: colors.error),
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
    this.errorText,
    this.placeholder = 'Selecionar',
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? errorText;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textSecondary)),
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
              border: Border.all(color: errorText != null ? colors.error : colors.border),
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
          Text(errorText!, style: TextStyle(fontSize: 12, color: colors.error)),
        ],
      ],
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
