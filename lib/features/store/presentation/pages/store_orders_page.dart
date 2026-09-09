import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/commerce_mode.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/domain/order_status_simulator.dart';
import 'package:goias_app/features/store/presentation/cubit/store_orders_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/store_orders_state.dart';
import 'package:goias_app/features/store/presentation/order_status_labels.dart';
import 'package:goias_app/features/store/presentation/widgets/store_price_block.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/widgets/demo_tag.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class StoreOrdersPage extends StatelessWidget {
  const StoreOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StoreOrdersCubit>()..load(),
      child: const _StoreOrdersView(),
    );
  }
}

class _StoreOrdersView extends StatelessWidget {
  const _StoreOrdersView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final title = l10n.storeOrdersTitle.toUpperCase();
    return Scaffold(
      backgroundColor: colors.background,
      body: DetailPageHeader(
        title: title,
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
          child: BlocBuilder<StoreOrdersCubit, StoreOrdersState>(
            builder: (context, state) {
              return switch (state.status) {
                LoadStatus.initial || LoadStatus.loading => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                  child: Center(child: GoiasLoadingIndicator()),
                ),
                LoadStatus.empty => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxxl,
                  ),
                  child: Center(
                    child: StateMessage(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.storeOrdersEmptyTitle,
                      message: l10n.storeOrdersEmptyMessage(
                        sl<ClubConfig>().productNames.storeName,
                      ),
                    ),
                  ),
                ),
                LoadStatus.error => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxxl,
                  ),
                  child: Center(
                    child: StateMessage(
                      icon: Icons.error_outline_rounded,
                      title: l10n.storeOrdersLoadError,
                    ),
                  ),
                ),
                LoadStatus.success => Column(
                  children: [
                    for (final order in state.orders) _OrderTile(order: order),
                  ],
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final extraItems = order.items.length - 1;
    return InkWell(
      onTap: () => context.push('/store/orders/${order.id}', extra: order),
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              child: Image.asset(
                order.items.first.thumbnail,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          order.id,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (sl<ClubConfig>().capabilities.storeCommerceMode ==
                          CommerceMode.demo) ...[
                        const SizedBox(width: 6),
                        DemoTag(label: l10n.commonDemoTag),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    fullDateLabel(order.createdAt),
                    style: TextStyle(fontSize: 11.5, color: colors.textHint),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    orderStatusLabel(
                      l10n,
                      OrderStatusSimulator.resolve(order),
                      isPickup: order.isPickup,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.gold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.items.first.productName +
                        (extraItems > 0
                            ? ' · ${l10n.storeOrdersMoreItems(extraItems)}'
                            : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: colors.textHint),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatBrl(order.total),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.textHint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
