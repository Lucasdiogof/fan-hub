import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/data/store_category_catalog.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/presentation/cubit/store_catalog_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/store_catalog_state.dart';
import 'package:goias_app/features/store/presentation/store_display_labels.dart';
import 'package:goias_app/features/store/presentation/widgets/cart_icon_button.dart';
import 'package:goias_app/features/store/presentation/widgets/product_card.dart';
import 'package:goias_app/features/ticket/presentation/widgets/matchday_entry_card.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Tela inicial da Loja — duas abas: "Ingressos" (matchday/check-in) e
/// "Roupas" (banner, categorias fixas e as seções de produto, todas
/// derivadas do catálogo carregado uma vez, ver `StoreCatalogState`).
/// Categorias de "Personalize seu manto"/"Infantil" foram unificadas num
/// único card editorial: com só um produto juvenil no catálogo hoje, duas
/// seções falando dele em sequência repetiriam o mesmo item — exatamente o
/// problema que motivou este redesenho.
class StoreHomePage extends StatelessWidget {
  const StoreHomePage({this.showBackButton = true, super.key});

  /// A Loja hoje vive em dois lugares: aba fixa da bottom nav (sem botão de
  /// voltar, como qualquer outra aba) e — se algum dia sobrar um link
  /// direto pra `/store` — uma rota empurrada normal (com botão de voltar).
  /// Nunca os dois ao mesmo tempo.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StoreCatalogCubit>()..load(),
      child: _StoreHomeView(showBackButton: showBackButton),
    );
  }
}

class _StoreHomeView extends StatefulWidget {
  const _StoreHomeView({required this.showBackButton});

  final bool showBackButton;

  @override
  State<_StoreHomeView> createState() => _StoreHomeViewState();
}

class _StoreHomeViewState extends State<_StoreHomeView>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showBackButton = widget.showBackButton;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      if (showBackButton) ...[
                        BackButtonCircle(
                          size: 34,
                          iconSize: 16,
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go('/'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        child: Text(
                          context.l10n.storeHomeTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: context.l10n.storeSearchHint,
                        child: InkWell(
                          onTap: () => context.push('/store/search'),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_rounded,
                              size: 17,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const CartIconButton(size: 34, iconSize: 16),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.textSecondary,
                  indicatorColor: colors.primary,
                  tabs: [
                    Tab(text: context.l10n.storeTabTickets),
                    Tab(text: context.l10n.storeTabClothing),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    // Ingressos não depende do catálogo de produtos — nunca
                    // deve ficar bloqueado por um erro/loading da Roupas.
                    children: [
                      const _TicketsTabContent(),
                      BlocBuilder<StoreCatalogCubit, StoreCatalogState>(
                        builder: (context, state) {
                          return switch (state.status) {
                            LoadStatus.initial || LoadStatus.loading =>
                              const Center(child: GoiasLoadingIndicator()),
                            LoadStatus.error => Center(
                              child: StateMessage(
                                icon: Icons.error_outline_rounded,
                                title: context.l10n.storeHomeLoadErrorTitle,
                                message: context.l10n.commonLoadError,
                              ),
                            ),
                            LoadStatus.empty => Center(
                              child: StateMessage(
                                icon: Icons.storefront_outlined,
                                title: context.l10n.storeHomeEmptyTitle,
                                message: context.l10n.storeHomeEmptyMessage,
                              ),
                            ),
                            LoadStatus.success => _ClothingTabContent(
                              state: state,
                            ),
                          };
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _fixedCategoryIds = ['masculine', 'feminine', 'kids', 'accessories'];

/// Aba "Ingressos" — card de matchday (já cobre os 6 estados de venda/
/// check-in) + atalhos pro que o usuário já comprou. Nunca depende do
/// catálogo de produtos, então funciona mesmo se a Roupas falhar ao
/// carregar.
class _TicketsTabContent extends StatelessWidget {
  const _TicketsTabContent();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.xxxl),
      children: [
        const MatchdayEntryCard(),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(l10n.storeMyPurchasesSectionTitle),
        const SizedBox(height: AppSpacing.sm),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _MyPurchasesRow(),
        ),
      ],
    );
  }
}

/// Aba "Roupas" — vitrine da Goiás Store (banner, categorias, seções de
/// produto), tudo derivado do catálogo carregado uma vez.
class _ClothingTabContent extends StatelessWidget {
  const _ClothingTabContent({required this.state});

  final StoreCatalogState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final launch = state.launches.isEmpty ? null : state.launches.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.xxxl),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _StoreBanner(
            launch:
                launch ??
                (state.officialJerseys.isEmpty
                    ? null
                    : state.officialJerseys.first),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(l10n.storeSectionCategories),
        const SizedBox(height: AppSpacing.sm),
        const _CategoryRow(),
        const SizedBox(height: AppSpacing.xl),
        _ProductSection(
          title: categoryDisplayName(l10n, 'masculine'),
          products: state.masculineProducts,
        ),
        _ProductSection(
          title: categoryDisplayName(l10n, 'feminine'),
          products: state.feminineProducts,
        ),
        _ProductSection(
          title: categoryDisplayName(l10n, 'kids'),
          products: state.kidsProducts,
        ),
        _ProductSection(
          title: categoryDisplayName(l10n, 'accessories'),
          products: state.accessoryProducts,
        ),
      ],
    );
  }
}

/// Banner de topo da home da loja — arte pronta (com textos e CTA já
/// embutidos na imagem), exibida na largura toda com cantos arredondados.
/// Toque leva ao produto em destaque quando há um.
class _StoreBanner extends StatelessWidget {
  const _StoreBanner({required this.launch});

  final StoreProduct? launch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.banner),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: launch == null
            ? null
            : () => context.push('/store/product/${launch!.id}'),
        child: Image.asset(
          'lib/assets/banner.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}

/// Atalhos compactos pro que o usuário já comprou/já tem — não replica a
/// tela de Ingressos nem a de Pedidos aqui, só leva pra elas.
class _MyPurchasesRow extends StatelessWidget {
  const _MyPurchasesRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _PurchaseShortcut(
            icon: Icons.confirmation_number_outlined,
            label: l10n.storeMyTicketsShortcut,
            onTap: () => context.push('/tickets/my'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _PurchaseShortcut(
            icon: Icons.receipt_long_outlined,
            label: l10n.storeMyOrdersShortcut,
            onTap: () => context.push('/store/orders'),
          ),
        ),
      ],
    );
  }
}

class _PurchaseShortcut extends StatelessWidget {
  const _PurchaseShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: colors.textHint,
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _fixedCategoryIds.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final id = _fixedCategoryIds[index];
          final icon =
              StoreCategoryCatalog.byId(id)?.icon ?? Icons.category_rounded;
          final name = categoryDisplayName(l10n, id);
          return Semantics(
            button: true,
            label: name,
            child: InkWell(
              onTap: () => context.push('/store/category/$id'),
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              child: Container(
                width: 64,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Icon(icon, size: 18, color: colors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({required this.title, required this.products});

  final String title;
  final List<StoreProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(title),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 256,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => SizedBox(
                width: 152,
                child: ProductCard(product: products[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
