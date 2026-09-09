import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_state.dart';
import 'package:goias_app/features/store/presentation/widgets/store_price_block.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Frete grátis (calculado de verdade no checkout, com CEP) começa em
/// R$399,90 — aqui só um selo informativo, o valor final vem do
/// `StoreRepository.calculateShipping`.
const _freeShippingThreshold = 399.90;

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
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
                      Text(
                        l10n.storeCartTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<CartCubit, CartState>(
                    builder: (context, state) {
                      if (state.cart.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StateMessage(
                                icon: Icons.shopping_bag_outlined,
                                title: l10n.storeCartEmptyTitle,
                                message: l10n.storeCartEmptyMessage(
                                  sl<ClubConfig>().identity.code,
                                  sl<ClubConfig>().identity.shortName,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextButton(
                                onPressed: () => context.go('/store'),
                                child: Text(
                                  l10n.storeCartEmptyCta(
                                    sl<ClubConfig>().productNames.storeName,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final isWide = MediaQuery.sizeOf(context).width >= 840;
                      return isWide
                          ? _CartWideLayout(state: state)
                          : _CartNarrowLayout(state: state);
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

class _CartWideLayout extends StatelessWidget {
  const _CartWideLayout({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                for (final item in state.cart.items) _CartItemTile(item: item),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _CouponField(state: state),
                const SizedBox(height: AppSpacing.lg),
                _SummaryCard(state: state),
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: context.l10n.storeCheckoutCta,
                  onPressed: () => context.push('/store/checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartNarrowLayout extends StatelessWidget {
  const _CartNarrowLayout({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            children: [
              for (final item in state.cart.items) _CartItemTile(item: item),
              const SizedBox(height: AppSpacing.sm),
              _CouponField(state: state),
              const SizedBox(height: AppSpacing.md),
              _SummaryCard(state: state),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppPrimaryButton(
              label: context.l10n.storeCheckoutCta,
              onPressed: () => context.push('/store/checkout'),
            ),
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              child: Image.asset(
                item.thumbnail,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.storeCartItemSize(item.size),
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                if (item.isPersonalized)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        if (item.personalizedName != null)
                          item.personalizedName,
                        if (item.personalizedNumber != null)
                          l10n.storeCartItemNumber(item.personalizedNumber!),
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: colors.gold,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Semantics(
                  label: l10n.storeQuantityLabel,
                  value: '${item.quantity}',
                  increasedValue: '${item.quantity + 1}',
                  decreasedValue: '${item.quantity - 1}',
                  onIncrease: () => _updateQty(context, item.quantity + 1),
                  onDecrease: () => _updateQty(context, item.quantity - 1),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: _QtyButton(
                          icon: Icons.remove_rounded,
                          onTap: () => _updateQty(context, item.quantity - 1),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${item.quantity}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      ExcludeSemantics(
                        child: _QtyButton(
                          icon: Icons.add_rounded,
                          onTap: () => _updateQty(context, item.quantity + 1),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatBrl(item.lineTotal),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: l10n.storeRemoveItemAction(item.productName),
            child: InkWell(
              onTap: () => _confirmRemove(context, item),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: colors.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateQty(BuildContext context, int quantity) {
    context.read<CartCubit>().updateQuantity(item.id, quantity);
  }

  Future<void> _confirmRemove(BuildContext context, CartItem item) async {
    final cubit = context.read<CartCubit>();
    final l10n = context.l10n;
    final confirmed = await AppBottomSheet.show(
      context,
      title: l10n.storeRemoveItemTitle,
      description: l10n.storeRemoveItemMessage(item.productName),
      confirmLabel: l10n.storeRemove,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (confirmed == true) unawaited(cubit.removeItem(item.id));
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 13, color: colors.textPrimary),
      ),
    );
  }
}

class _CouponField extends StatefulWidget {
  const _CouponField({required this.state});

  final CartState state;

  @override
  State<_CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<_CouponField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final coupon = widget.state.cart.coupon;

    if (coupon != null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        ),
        child: Row(
          children: [
            Icon(Icons.local_offer_rounded, size: 16, color: colors.gold),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${coupon.code} · -${coupon.discountPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: colors.gold,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: l10n.storeRemove,
              child: InkWell(
                onTap: () => context.read<CartCubit>().removeCoupon(),
                child: Text(
                  l10n.storeRemove,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: l10n.storeCouponHint,
                  isDense: true,
                  filled: true,
                  fillColor: colors.secondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: widget.state.applyingCoupon
                  ? null
                  : () =>
                        context.read<CartCubit>().applyCoupon(_controller.text),
              child: Text(l10n.storeCouponApply),
            ),
          ],
        ),
        if (widget.state.invalidCoupon)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              l10n.storeCouponInvalid,
              style: TextStyle(fontSize: 11.5, color: colors.error),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final CartState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cart = state.cart;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: l10n.storeSubtotal,
            value: formatBrl(cart.subtotal),
          ),
          if (cart.coupon != null)
            _SummaryRow(
              label: l10n.storeDiscountLabel(cart.coupon!.code),
              value: '- ${formatBrl(cart.discountAmount)}',
              valueColor: colors.gold,
            ),
          const Divider(height: AppSpacing.xl),
          _SummaryRow(
            label: l10n.storeTotal,
            value: formatBrl(cart.totalAfterDiscount),
            bold: true,
          ),
          if (cart.totalAfterDiscount < _freeShippingThreshold) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.storeFreeShippingNote(formatBrl(_freeShippingThreshold)),
              style: TextStyle(fontSize: 11.5, color: colors.textHint),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? colors.textPrimary : colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 17 : 13,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color:
                  valueColor ??
                  (bold ? colors.textPrimary : colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
