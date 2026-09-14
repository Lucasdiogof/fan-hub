import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/l10n/locale_cubit.dart';
import 'package:goias_app/core/l10n/supported_locales.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final title = l10n.settingsLanguageTitle;
    return Scaffold(
      backgroundColor: colors.background,
      body: DetailPageHeader(
        maxWidth: ContentWidth.detail,
        title: title,
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        heroTitle: Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LanguageTile(
                    title: l10n.languageSystemLabel,
                    subtitle: l10n.languageSystemDescription,
                    icon: Icons.smartphone_rounded,
                    selected: locale == null,
                    onTap: () => context.read<LocaleCubit>().setLocale(null),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final option in kSupportedLocales) ...[
                    _LanguageTile(
                      title: languageEndonym(option.languageCode),
                      icon: Icons.language_rounded,
                      selected: locale?.languageCode == option.languageCode,
                      onTap: () =>
                          context.read<LocaleCubit>().setLocale(option),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? colors.primary : colors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
