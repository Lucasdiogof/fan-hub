import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/presentation/order_status_labels.dart';
import 'package:goias_app/features/store/presentation/widgets/store_price_block.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

class StoreOrderDetailPage extends StatelessWidget {
  const StoreOrderDetailPage({required this.order, super.key});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.detail.maxWidth),
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
                        child: Text(
                          order.id,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      if (order.status == OrderStatus.cancelled)
                        const _CancelledNotice()
                      else
                        _StatusTimeline(order: order),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionCard(
                        title: order.isPickup
                            ? l10n.storePickupWord
                            : l10n.storeStepDelivery,
                        child: order.isPickup
                            ? Text(
                                l10n.storePickupAddressPrefix(
                                  order.pickupInfo?.fullAddress ??
                                      const PickupInformation().fullAddress,
                                ),
                                style: _valueStyle(context),
                              )
                            : Text(
                                order.address?.oneLine ?? '—',
                                style: _valueStyle(context),
                              ),
                      ),
                      _SectionCard(
                        title: l10n.storeCustomerLabel,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.identification.fullName,
                              style: _valueStyle(context),
                            ),
                            Text(
                              maskCpf(order.identification.cpf),
                              style: _hintStyle(context),
                            ),
                            Text(
                              maskEmail(order.identification.email),
                              style: _hintStyle(context),
                            ),
                          ],
                        ),
                      ),
                      _SectionCard(
                        title: l10n.storeStepPayment,
                        child: Text(
                          order.payment.method.name == 'pix'
                              ? l10n.storePaymentPix
                              : l10n.storeCardFinalDigits(
                                  order.payment.cardSummary?.lastFourDigits ??
                                      '----',
                                ),
                          style: _valueStyle(context),
                        ),
                      ),
                      _SectionCard(
                        title: l10n.storeItemsCountLabel(order.itemCount),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final item in order.items)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.cardSmall,
                                      ),
                                      child: Image.asset(
                                        item.thumbnail,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        '${item.quantity}x ${item.productName} (${item.size})',
                                        style: _hintStyle(context),
                                      ),
                                    ),
                                    Text(
                                      formatBrl(item.lineTotal),
                                      style: _valueStyle(context),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(height: AppSpacing.lg),
                            _Row(l10n.storeSubtotal, formatBrl(order.subtotal)),
                            if (order.discountAmount > 0)
                              _Row(
                                l10n.storeDiscountGeneric,
                                '- ${formatBrl(order.discountAmount)}',
                              ),
                            _Row(
                              order.isPickup
                                  ? l10n.storePickupWord
                                  : l10n.storeShippingLabel,
                              order.shippingCost <= 0
                                  ? l10n.storeFree
                                  : formatBrl(order.shippingCost),
                            ),
                            const Divider(height: AppSpacing.lg),
                            _Row(
                              l10n.storeTotal,
                              formatBrl(order.total),
                              bold: true,
                            ),
                          ],
                        ),
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

TextStyle _valueStyle(BuildContext context) => TextStyle(
  fontSize: 13.5,
  fontWeight: FontWeight.w700,
  color: context.colors.textPrimary,
);

TextStyle _hintStyle(BuildContext context) =>
    TextStyle(fontSize: 12, color: context.colors.textSecondary);

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.textHint,
              ),
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? colors.textPrimary : colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 12.5,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: bold ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledNotice extends StatelessWidget {
  const _CancelledNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: colors.gold),
          const SizedBox(width: AppSpacing.sm),
          Text(
            context.l10n.storeOrderCancelled,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: colors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final steps = orderStatusTimeline(isPickup: order.isPickup);
    final currentIndex = steps.indexOf(order.status);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Semantics(
            label:
                '${orderStatusLabel(l10n, steps[i], isPickup: order.isPickup)}: '
                '${i <= currentIndex ? l10n.storeStatusStepDone : l10n.storeStatusStepPending}',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Icon(
                      i <= currentIndex
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 20,
                      color: i <= currentIndex ? colors.primary : colors.border,
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 28,
                        color: i < currentIndex
                            ? colors.primary
                            : colors.border,
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    orderStatusLabel(l10n, steps[i], isPickup: order.isPickup),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == currentIndex
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: i <= currentIndex
                          ? colors.textPrimary
                          : colors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
