import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
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
import 'package:goias_app/features/store/presentation/widgets/store_banner_carousel.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Tela inicial da Goiás Store — banner, categorias fixas e as seções de
/// produto, todas derivadas do catálogo carregado uma vez (ver
/// `StoreCatalogState`). Ingressos não vive mais aqui — a compra de
/// ingresso acontece a partir do próprio jogo, na aba Jogos
/// (`games_page.dart`), não da Loja.
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

class _StoreHomeView extends StatelessWidget {
  const _StoreHomeView({required this.showBackButton});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                  // Título e ações na MESMA linha, como em toda seção de
                  // aba (ver `social_feed_page.dart`): antes as ações vinham
                  // numa linha própria acima, o que empurrava o "GOIÁS STORE"
                  // uns 50px pra baixo e deixava a Loja desalinhada das
                  // outras telas do menu inferior.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (showBackButton) ...[
                            BackButtonCircle(
                              size: 34,
                              iconSize: 16,
                              onTap: () => context.canPop()
                                  ? context.pop()
                                  : context.go('/'),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Expanded(
                            child: PageTitle(
                              sl<ClubConfig>().productNames.storeName
                                  .toUpperCase(),
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: context.l10n.storeSearchHint(
                              sl<ClubConfig>().productNames.storeName,
                            ),
                            child: InkWell(
                              onTap: () => context.push('/store/search'),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 34,
                                height: 34,
                                margin: const EdgeInsets.only(
                                  right: AppSpacing.sm,
                                ),
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
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<StoreCatalogCubit, StoreCatalogState>(
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
                        LoadStatus.success => _StoreHomeContent(state: state),
                      };
                    },
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

/// Vitrine da Goiás Store (banner, categorias, seções de produto), tudo
/// derivado do catálogo carregado uma vez.
class _StoreHomeContent extends StatelessWidget {
  const _StoreHomeContent({required this.state});

  final StoreCatalogState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.xxxl),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _StoreBanner(),
        ),
        const SizedBox(height: AppSpacing.xl),
        _SectionLabel(l10n.storeMyPurchasesTitle),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: _PurchaseShortcut(
                  icon: Icons.confirmation_number_outlined,
                  label: l10n.profileMyTickets,
                  onTap: () => context.push('/tickets/my'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PurchaseShortcut(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.storeProfileMyOrders,
                  onTap: () => context.push('/store/orders'),
                ),
              ),
            ],
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
/// Puramente visual, sem navegação ao toque. Quantidade de imagens vem de
/// `ClubConfig.assets.storeHomeBanners` — 1 banner fica fixo (era hardcoded
/// `lib/assets/goias_store.png` direto aqui, agora só o Goiás tem essa
/// mesma imagem configurada); >1 vira carousel com autoplay (ver
/// `StoreBannerCarousel`), nunca um `if (club == ...)` aqui.
class _StoreBanner extends StatelessWidget {
  const _StoreBanner();

  @override
  Widget build(BuildContext context) {
    return StoreBannerCarousel(banners: sl<ClubConfig>().assets.storeHomeBanners);
  }
}

/// Acesso compacto pra "o que já é meu" (ingressos/pedidos) sem sair da
/// Loja — não substitui "Compras e Serviços" no Perfil (essa é a central
/// pessoal do usuário; esta é só um atalho contextual durante a compra),
/// reaproveita exatamente as mesmas rotas/telas.
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
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: colors.textHint,
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
