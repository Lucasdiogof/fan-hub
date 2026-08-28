import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/data/store_category_catalog.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/store_listing_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/store_listing_state.dart';
import 'package:goias_app/features/store/presentation/store_display_labels.dart';
import 'package:goias_app/features/store/presentation/widgets/cart_icon_button.dart';
import 'package:goias_app/features/store/presentation/widgets/product_card.dart';
import 'package:goias_app/features/store/presentation/widgets/store_filters_sheet.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Uma listagem — categoria (quando [categoryId] vem preenchido) ou busca
/// livre (quando vem `null`, a tela abre já com foco no campo de busca).
/// Mesma tela pros dois casos: filtro/ordenação funcionam igual.
class StoreListingPage extends StatelessWidget {
  const StoreListingPage({this.categoryId, super.key});

  final String? categoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          StoreListingCubit(sl<StoreRepository>(), categoryId: categoryId)
            ..load(),
      child: _StoreListingView(isSearch: categoryId == null),
    );
  }
}

class _StoreListingView extends StatefulWidget {
  const _StoreListingView({required this.isSearch});

  final bool isSearch;

  @override
  State<_StoreListingView> createState() => _StoreListingViewState();
}

class _StoreListingViewState extends State<_StoreListingView> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.isSearch) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _searchFocus.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => context.read<StoreListingCubit>().setQuery(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final categoryId = context.read<StoreListingCubit>().state.categoryId;
    final title = widget.isSearch || categoryId == null
        ? null
        : (StoreCategoryCatalog.byId(categoryId) != null
              ? categoryDisplayName(l10n, categoryId)
              : null);

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
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: widget.isSearch
                            ? TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                onChanged: _onQueryChanged,
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: l10n.storeSearchHint,
                                  isDense: true,
                                  filled: true,
                                  fillColor: colors.secondary,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.button,
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  suffixIcon: _searchController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                          ),
                                          tooltip: l10n.commonClose,
                                          onPressed: () {
                                            _searchController.clear();
                                            context
                                                .read<StoreListingCubit>()
                                                .setQuery('');
                                            setState(() {});
                                          },
                                        ),
                                ),
                              )
                            : Text(
                                (title ?? l10n.storeListingDefaultTitle)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const CartIconButton(),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<StoreListingCubit, StoreListingState>(
                    builder: (context, state) {
                      if (state.status == LoadStatus.loading ||
                          state.status == LoadStatus.initial) {
                        return const Center(child: GoiasLoadingIndicator());
                      }
                      if (widget.isSearch && state.query.isEmpty) {
                        return Center(
                          child: StateMessage(
                            icon: Icons.search_rounded,
                            title: l10n.storeSearchEmptyTitle,
                            message: l10n.storeSearchEmptyMessage,
                          ),
                        );
                      }
                      return Column(
                        children: [
                          _FilterBar(state: state),
                          Expanded(
                            child: state.visibleProducts.isEmpty
                                ? Center(
                                    child: StateMessage(
                                      icon: Icons.search_off_rounded,
                                      title: l10n.storeListingNoResultsTitle,
                                      message:
                                          l10n.storeListingNoResultsMessage,
                                    ),
                                  )
                                : _ProductGrid(products: state.visibleProducts),
                          ),
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
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state});

  final StoreListingState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<StoreListingCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.storeListingProductCount(state.visibleProducts.length),
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
            ),
          ),
          _PillButton(
            icon: Icons.swap_vert_rounded,
            label: l10n.storeSortLabel,
            onTap: () => showStoreSortSheet(
              context,
              current: state.sort,
              onChanged: cubit.setSort,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _PillButton(
            icon: Icons.tune_rounded,
            label: state.filters.isEmpty
                ? l10n.storeFiltersLabel
                : l10n.storeFiltersLabelCount(state.filters.activeCount),
            highlighted: !state.filters.isEmpty,
            onTap: () => showStoreFiltersSheet(
              context,
              current: state.filters,
              onApply: cubit.setFilters,
              onClear: cubit.clearFilters,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: highlighted
          ? colors.primary.withValues(alpha: 0.12)
          : colors.secondary,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: highlighted ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: highlighted ? colors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<StoreProduct> products;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          < 500 => 2,
          < 840 => 3,
          _ => 4,
        };
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.56,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) =>
              ProductCard(product: products[index]),
        );
      },
    );
  }
}
