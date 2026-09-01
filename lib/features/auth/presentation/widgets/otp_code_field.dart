import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Campo de código de 6 dígitos — a grade de caixinhas é só visual; quem
/// captura de verdade é um `TextField` invisível por trás (mesma técnica
/// de `NativeLineupInput`, já validada nesta base de código: mais
/// confiável que 6 `TextField`s separados pra colar os 6 dígitos de uma
/// vez, que é justamente o caso que mais importa aqui).
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    required this.length,
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
    super.key,
  });

  final int length;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  State<OtpCodeField> createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField> {
  late final _focusNode = FocusNode();
  late final _controller = TextEditingController(text: widget.value);

  void requestFocus() => _focusNode.requestFocus();

  @override
  void didUpdateWidget(covariant OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final truncated = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    widget.onChanged(truncated);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: requestFocus,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < widget.length; i++)
                _DigitBox(
                  digit: i < widget.value.length ? widget.value[i] : '',
                  focused: _focusNode.hasFocus && i == widget.value.length,
                ),
            ],
          ),
          // Invisível — só captura teclado/colar. `visiblePassword` evita
          // sugestão de preenchimento automático de SENHA por engano (o
          // teclado não sabe que isto é um código, só que é numérico).
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _onChanged(value);
                  setState(() {});
                },
                onSubmitted: (_) => widget.onSubmitted(),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({required this.digit, required this.focused});

  final String digit;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filled = digit.isNotEmpty;
    return Container(
      width: 44,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused
              ? colors.primary
              : (filled ? colors.primary.withValues(alpha: 0.5) : colors.border),
          width: focused ? 1.5 : 1,
        ),
      ),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}
