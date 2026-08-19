import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/membership/domain/entities/faq_block.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';

/// Renderiza spans com negrito/link do FAQ — `StatefulWidget` só pra poder
/// descartar os `TapGestureRecognizer` corretamente (`TextSpan` não faz
/// isso sozinho).
class FaqRichText extends StatefulWidget {
  const FaqRichText({required this.spans, required this.style, super.key});

  final List<FaqSpan> spans;
  final TextStyle style;

  @override
  State<FaqRichText> createState() => _FaqRichTextState();
}

class _FaqRichTextState extends State<FaqRichText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final colors = context.colors;

    final children = <InlineSpan>[
      for (final span in widget.spans)
        if (span.link != null)
          TextSpan(
            text: span.text,
            style: widget.style.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
            recognizer: _recognizers
                .addAndReturn(TapGestureRecognizer()..onTap = () => openExternalUrl(context, span.link!)),
          )
        else
          TextSpan(
            text: span.text,
            style: span.bold ? widget.style.copyWith(fontWeight: FontWeight.w800, color: colors.textPrimary) : widget.style,
          ),
    ];

    return Text.rich(TextSpan(children: children));
  }
}

extension _AddAndReturn<T> on List<T> {
  T addAndReturn(T value) {
    add(value);
    return value;
  }
}
