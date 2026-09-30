import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/data/membership_contact_config.dart';
import 'package:goias_app/features/membership/data/membership_faq_data_source.dart';
import 'package:goias_app/features/membership/domain/faq_search.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_faq_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_faq_state.dart';
import 'package:goias_app/features/membership/presentation/widgets/faq_accordion_item.dart';
import 'package:goias_app/features/membership/presentation/widgets/faq_category_selector.dart';
import 'package:goias_app/features/membership/presentation/widgets/faq_search_field.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Área de Sócio > Dúvidas Frequentes — conteúdo estruturado localmente
/// (ver [MembershipFaqDataSource]), sem WebView e sem depender do site.
class MembershipFaqPage extends StatelessWidget {
  const MembershipFaqPage({
    this.initialCategoryId,
    this.initialQuery,
    super.key,
  });

  final String? initialCategoryId;
  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MembershipFaqCubit(
        sl<MembershipFaqDataSource>(),
        initialCategoryId: initialCategoryId,
        initialQuery: initialQuery,
      ),
      child: const _MembershipFaqView(),
    );
  }
}

class _MembershipFaqView extends StatelessWidget {
  const _MembershipFaqView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<MembershipFaqCubit>();
    final title = context.l10n.membershipFaqTitle;
    return Scaffold(
      backgroundColor: colors.background,
      body: DetailPageHeader(
        title: title,
        heroTitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.membershipFaqSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BlocBuilder<MembershipFaqCubit, MembershipFaqState>(
                buildWhen: (prev, curr) => prev.query != curr.query,
                builder: (context, state) => FaqSearchField(
                  initialValue: state.query,
                  onChanged: cubit.setQuery,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              BlocBuilder<MembershipFaqCubit, MembershipFaqState>(
                buildWhen: (prev, curr) =>
                    prev.categories != curr.categories ||
                    prev.selectedCategoryId != curr.selectedCategoryId,
                builder: (context, state) => FaqCategorySelector(
                  categories: state.categories,
                  selectedCategoryId: state.selectedCategoryId,
                  onSelected: cubit.selectCategory,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<MembershipFaqCubit, MembershipFaqState>(
                builder: (context, state) {
                  if (state.status == LoadStatus.initial ||
                      state.status == LoadStatus.loading) {
                    return const SizedBox(
                      height: 320,
                      child: Center(child: GoiasLoadingIndicator()),
                    );
                  }
                  if (state.status == LoadStatus.error) {
                    return SizedBox(
                      height: 320,
                      child: Center(
                        child: StateMessage(
                          icon: Icons.error_outline_rounded,
                          title: context.l10n.membershipFaqLoadError,
                          message: state.errorMessage,
                        ),
                      ),
                    );
                  }
                  final filtered = filterFaqCategories(
                    categories: state.categories,
                    selectedCategoryId: state.selectedCategoryId,
                    query: state.query,
                  );
                  if (filtered.isEmpty) {
                    return const _FaqEmptyResult();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final category in filtered) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              category.title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: colors.textHint,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                        for (final item in category.items)
                          FaqAccordionItem(
                            item: item,
                            expanded: state.expandedItemId == item.id,
                            onTap: () => cubit.toggleItem(item.id),
                          ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      const _FaqHelpFooter(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqEmptyResult extends StatelessWidget {
  const _FaqEmptyResult();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 38, color: colors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.membershipFaqNoResults,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.membershipFaqNoResultsMessage(
                sl<ClubConfig>().productNames.membershipProgramName,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            if (MembershipContactConfig.hasWhatsapp) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: () => openExternalUrl(
                  context,
                  MembershipContactConfig.whatsappUrl,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 0.3,
                  ),
                ),
                child: Text(context.l10n.membershipTalkToSupport),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqHelpFooter extends StatelessWidget {
  const _FaqHelpFooter();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.membershipDontStayInDoubt,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.membershipDidntFindAnswer,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          if (MembershipContactConfig.hasWhatsapp) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => openExternalUrl(
                  context,
                  MembershipContactConfig.whatsappUrl,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 0.3,
                  ),
                ),
                child: Text(context.l10n.membershipTalkToSupport),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.membershipFaqScopeNote(
              sl<ClubConfig>().productNames.membershipProgramName,
            ),
            style: TextStyle(fontSize: 11, color: colors.textHint, height: 1.4),
          ),
        ],
      ),
    );
  }
}
