import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/faq_block.dart';
import 'package:goias_app/features/membership/domain/entities/faq_item.dart';
import 'package:goias_app/features/membership/presentation/widgets/faq_rich_text.dart';

class FaqAccordionItem extends StatelessWidget {
  const FaqAccordionItem({
    required this.item,
    required this.expanded,
    required this.onTap,
    super.key,
  });

  final FaqItem item;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.question,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      expanded ? Icons.remove_rounded : Icons.add_rounded,
                      key: ValueKey(expanded),
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: _FaqAnswerView(blocks: item.answer),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

class _FaqAnswerView extends StatelessWidget {
  const _FaqAnswerView({required this.blocks});

  final List<FaqBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = TextStyle(
      fontSize: 13,
      height: 1.5,
      color: colors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: switch (block) {
              FaqParagraphBlock(:final spans) => FaqRichText(
                spans: spans,
                style: style,
              ),
              FaqListBlock(:final items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final spans in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '•  ',
                            style: style.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                          ),
                          Expanded(
                            child: FaqRichText(spans: spans, style: style),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            },
          ),
      ],
    );
  }
}
