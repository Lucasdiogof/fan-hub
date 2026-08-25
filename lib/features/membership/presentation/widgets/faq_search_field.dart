import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

class FaqSearchField extends StatelessWidget {
  const FaqSearchField({
    required this.initialValue,
    required this.onChanged,
    super.key,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: colors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Buscar uma dúvida...',
        hintStyle: TextStyle(color: colors.textHint, fontSize: 14),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colors.textHint,
          size: 20,
        ),
        isDense: true,
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}
