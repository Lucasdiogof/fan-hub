import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
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
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Área de Sócio > Dúvidas Frequentes — conteúdo estruturado localmente
/// (ver [MembershipFaqDataSource]), sem WebView e sem depender do site.
class MembershipFaqPage extends StatelessWidget {
  const MembershipFaqPage({this.initialCategoryId, this.initialQuery, super.key});

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
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButtonCircle(onTap: () => context.pop()),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'DÚVIDAS FREQUENTES',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: colors.textPrimary, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Encontre respostas sobre planos, pagamentos, check-in e benefícios.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  BlocBuilder<MembershipFaqCubit, MembershipFaqState>(
                    buildWhen: (prev, curr) => prev.query != curr.query,
                    builder: (context, state) => FaqSearchField(initialValue: state.query, onChanged: cubit.setQuery),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  BlocBuilder<MembershipFaqCubit, MembershipFaqState>(
                    buildWhen: (prev, curr) =>
                        prev.categories != curr.categories || prev.selectedCategoryId != curr.selectedCategoryId,
                    builder: (context, state) => FaqCategorySelector(
                      categories: state.categories,
                      selectedCategoryId: state.selectedCategoryId,
                      onSelected: cubit.selectCategory,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: BlocBuilder<MembershipFaqCubit, MembershipFaqState>(
                      builder: (context, state) {
                        if (state.status == LoadStatus.initial || state.status == LoadStatus.loading) {
                          return Center(child: CircularProgressIndicator(color: colors.primary));
                        }
                        if (state.status == LoadStatus.error) {
                          return Center(
                            child: StateMessage(
                              icon: Icons.error_outline_rounded,
                              title: 'Não foi possível carregar as dúvidas frequentes.',
                              message: state.errorMessage,
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
                        return ListView(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                          children: [
                            for (final category in filtered) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                  ),
                ],
              ),
            ),
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
            Text('Nenhuma dúvida encontrada', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tente outro termo ou fale com o atendimento do Sócio Esmeralda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => openExternalUrl(context, MembershipContactConfig.whatsappUrl),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.3),
              ),
              child: const Text('FALAR COM O ATENDIMENTO'),
            ),
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
      decoration: BoxDecoration(color: colors.secondary, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NÃO FIQUE NA DÚVIDA',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.primary, letterSpacing: 0.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Não encontrou a resposta que procurava?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => openExternalUrl(context, MembershipContactConfig.whatsappUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.3),
              ),
              child: const Text('FALAR COM O ATENDIMENTO'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Dúvidas sobre o clube, categorias de base, elenco e outros assuntos fora do Sócio Esmeralda não são respondidas por este canal.',
            style: TextStyle(fontSize: 11, color: colors.textHint, height: 1.4),
          ),
        ],
      ),
    );
  }
}
