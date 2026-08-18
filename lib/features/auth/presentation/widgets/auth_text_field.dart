import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hintText,
    this.obscurable = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.errorText,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hintText;
  final bool obscurable;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _obscured = true;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? colors.error
        : _focused
        ? colors.primary
        : colors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: borderColor, width: _focused || hasError ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
                child: Icon(widget.icon, size: 18, color: _focused ? colors.primary : colors.textHint),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscurable && _obscured,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  inputFormatters: widget.keyboardType == TextInputType.emailAddress
                      ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
                      : null,
                  style: TextStyle(fontSize: 15, color: colors.textPrimary),
                  cursorColor: colors.primary,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 17),
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(fontSize: 15, color: colors.textHint),
                  ),
                ),
              ),
              if (widget.obscurable)
                _EyeButton(
                  obscured: _obscured,
                  color: colors.textHint,
                  onTap: () => setState(() => _obscured = !_obscured),
                )
              else
                const SizedBox(width: AppSpacing.md),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Text(
                    widget.errorText!,
                    style: TextStyle(fontSize: 12, color: colors.error),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _EyeButton extends StatelessWidget {
  const _EyeButton({required this.obscured, required this.color, required this.onTap});

  final bool obscured;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 19, color: color),
      splashRadius: 20,
      tooltip: obscured ? 'Mostrar senha' : 'Ocultar senha',
    );
  }
}
