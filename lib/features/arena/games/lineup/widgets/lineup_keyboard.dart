import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';

const _rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];

/// Teclado próprio (não o do sistema) — precisa refletir o estado
/// acumulado de cada letra pra aquele jogador especificamente (ver
/// [keyboardState]), nunca um teclado global compartilhado entre os 11.
class LineupKeyboard extends StatelessWidget {
  const LineupKeyboard({
    required this.keyboardState,
    required this.onLetter,
    required this.onDelete,
    required this.onEnter,
    required this.canSubmit,
    super.key,
  });

  final Map<String, LetterStatus> keyboardState;
  final ValueChanged<String> onLetter;
  final VoidCallback onDelete;
  final VoidCallback onEnter;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const perKeyMargin = 4.0;
        final keyWidth = ((constraints.maxWidth - perKeyMargin * 10) / 10)
            .clamp(22.0, 40.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in _rows) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final letter in row.split(''))
                      _Key(
                        label: letter,
                        status: keyboardState[letter],
                        onTap: () => onLetter(letter),
                        width: keyWidth,
                      ),
                  ],
                ),
              ),
              if (row == 'ZXCVBNM')
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 3,
                    horizontal: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Key(
                          label: context.l10n.keyboardDelete,
                          wide: true,
                          onTap: onDelete,
                          icon: Icons.backspace_outlined,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: _Key(
                          label: context.l10n.keyboardConfirm,
                          wide: true,
                          onTap: canSubmit ? onEnter : null,
                          icon: Icons.check_rounded,
                          emphasize: canSubmit,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    this.status,
    required this.onTap,
    this.wide = false,
    this.icon,
    this.emphasize = false,
    this.width,
  });

  final String label;
  final LetterStatus? status;
  final VoidCallback? onTap;
  final bool wide;
  final IconData? icon;
  final bool emphasize;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (status) {
      LetterStatus.correct => (const Color(0xFF278A52), Colors.white),
      LetterStatus.present => (const Color(0xFFC79A3D), Colors.white),
      LetterStatus.absent => (colors.border, colors.textHint),
      null =>
        emphasize
            ? (colors.primary, colors.onPrimary)
            : (colors.surfaceRaised, colors.textPrimary),
    };

    final textColor = foreground.withValues(alpha: onTap == null ? 0.5 : 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: wide ? double.infinity : (width ?? 32),
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: icon != null && wide
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: textColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  )
                : icon != null
                ? Icon(icon, size: 20, color: textColor)
                : Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
