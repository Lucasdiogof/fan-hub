import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/checkout_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/checkout_state.dart';
import 'package:goias_app/features/store/presentation/store_display_labels.dart';
import 'package:goias_app/features/store/presentation/widgets/store_address_form_sheet.dart';
import 'package:goias_app/features/store/presentation/widgets/store_price_block.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

part '../widgets/checkout_payment_review.dart';

List<String> _stepLabels(AppLocalizations l10n) => [
  l10n.storeStepIdentification,
  l10n.storeStepDelivery,
  l10n.storeStepPayment,
  l10n.storeStepReview,
];

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = sl<CartCubit>().state.cart;
    final profile = sl<ProfileCubit>().state.profile;
    return BlocProvider(
      create: (_) => CheckoutCubit(
        sl<StoreRepository>(),
        cart,
        prefillName: profile?.fullName,
        prefillEmail: profile?.email,
      ),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listenWhen: (previous, current) =>
          previous.order == null && current.order != null,
      listener: (context, state) {
        context.read<CartCubit>().clear();
      },
      builder: (context, state) {
        final isConfirmation = state.step == CheckoutStep.confirmation;
        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isConfirmation
                      ? ContentWidth.detail.maxWidth
                      : ContentWidth.wide.maxWidth,
                ),
                child: Column(
                  children: [
                    if (!isConfirmation) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            BackButtonCircle(
                              onTap: () {
                                if (state.step == CheckoutStep.identification) {
                                  context.pop();
                                } else {
                                  context.read<CheckoutCubit>().previousStep();
                                }
                              },
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _StepIndicator(step: state.step)),
                          ],
                        ),
                      ),
                    ],
                    Expanded(child: _CheckoutStepContent(state: state)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final CheckoutStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labels = _stepLabels(context.l10n);
    final index = step.index.clamp(0, labels.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            labels[index].toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= index ? colors.primary : colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CheckoutStepContent extends StatelessWidget {
  const _CheckoutStepContent({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.step) {
      CheckoutStep.identification => _IdentificationStep(state: state),
      CheckoutStep.delivery => _DeliveryStep(state: state),
      CheckoutStep.payment => _PaymentStep(state: state),
      CheckoutStep.review => _ReviewStep(state: state),
      CheckoutStep.confirmation => _ConfirmationStep(state: state),
    };
  }
}

/// Layout comum a toda etapa (exceto confirmação): formulário rolável +
/// botão primário fixo embaixo — no desktop, um resumo do pedido aparece
/// fixo ao lado, sempre visível enquanto o formulário rola.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.state,
    required this.form,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.loading = false,
    this.showSummarySidebar = true,
  });

  final CheckoutState state;
  final Widget form;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool loading;
  final bool showSummarySidebar;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 840;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: isWide && showSummarySidebar
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: form),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(
                        flex: 2,
                        child: _OrderSummarySidebar(state: state),
                      ),
                    ],
                  )
                : form,
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
              label: primaryLabel,
              onPressed: onPrimaryPressed,
              loading: loading,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderSummarySidebar extends StatelessWidget {
  const _OrderSummarySidebar({required this.state});

  final CheckoutState state;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.storeItemCount(cart.itemCount),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.productName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    formatBrl(item.lineTotal),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: AppSpacing.lg),
          _SidebarRow(l10n.storeSubtotal, formatBrl(cart.subtotal)),
          if (cart.coupon != null)
            _SidebarRow(
              l10n.storeDiscountGeneric,
              '- ${formatBrl(cart.discountAmount)}',
              color: colors.gold,
            ),
          _SidebarRow(
            state.fulfillmentMethod == FulfillmentMethod.pickup
                ? l10n.storePickupWord
                : l10n.storeShippingLabel,
            state.shippingCost <= 0
                ? l10n.storeFree
                : formatBrl(state.shippingCost),
          ),
          const Divider(height: AppSpacing.lg),
          _SidebarRow(l10n.storeTotal, formatBrl(state.total), bold: true),
        ],
      ),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow(this.label, this.value, {this.bold = false, this.color});

  final String label;
  final String value;
  final bool bold;
  final Color? color;

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
              color:
                  color ?? (bold ? colors.textPrimary : colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.md),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colors.textHint,
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context,
  String label, {
  String? errorText,
}) {
  final colors = context.colors;
  return InputDecoration(
    labelText: label,
    errorText: errorText,
    isDense: true,
    filled: true,
    fillColor: colors.secondary,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: BorderSide.none,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: BorderSide(color: colors.error),
    ),
  );
}

// ---------------------------------------------------------------------
// Etapa 1 — Identificação
// ---------------------------------------------------------------------

class _IdentificationStep extends StatefulWidget {
  const _IdentificationStep({required this.state});

  final CheckoutState state;

  @override
  State<_IdentificationStep> createState() => _IdentificationStepState();
}

class _IdentificationStepState extends State<_IdentificationStep> {
  late final _nameController = TextEditingController(
    text: widget.state.fullName,
  );
  late final _cpfController = TextEditingController(text: widget.state.cpf);
  late final _emailController = TextEditingController(text: widget.state.email);
  late final _phoneController = TextEditingController(text: widget.state.phone);

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();
    final errors = widget.state.identificationErrors(l10n);

    return _StepScaffold(
      state: widget.state,
      primaryLabel: l10n.storeContinueButton,
      onPrimaryPressed: () {
        if (cubit.validateIdentification()) cubit.nextStep();
      },
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => cubit.updateIdentification(fullName: v),
            decoration: _fieldDecoration(
              context,
              l10n.storeFullNameLabel,
              errorText: errors['fullName'],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _cpfController,
            keyboardType: TextInputType.number,
            inputFormatters: [cpfInputFormatter()],
            onChanged: (v) => cubit.updateIdentification(cpf: v),
            decoration: _fieldDecoration(
              context,
              l10n.storeCpfLabel,
              errorText: errors['cpf'],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) => cubit.updateIdentification(email: v),
            decoration: _fieldDecoration(
              context,
              l10n.commonEmailLabel,
              errorText: errors['email'],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [phoneInputFormatter()],
            onChanged: (v) => cubit.updateIdentification(phone: v),
            decoration: _fieldDecoration(
              context,
              l10n.storePhoneLabel,
              errorText: errors['phone'],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Etapa 2 — Entrega ou retirada
// ---------------------------------------------------------------------

class _DeliveryStep extends StatelessWidget {
  const _DeliveryStep({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CheckoutCubit>();
    return _StepScaffold(
      state: state,
      primaryLabel: context.l10n.storeContinueButton,
      onPrimaryPressed: state.canProceedFromDelivery ? cubit.nextStep : null,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FulfillmentToggle(state: state),
          if (state.fulfillmentMethod == FulfillmentMethod.delivery)
            _DeliveryAddressSection(state: state)
          else
            _PickupSection(state: state),
        ],
      ),
    );
  }
}

class _FulfillmentToggle extends StatelessWidget {
  const _FulfillmentToggle({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();
    return Row(
      children: [
        Expanded(
          child: _ToggleTile(
            icon: Icons.local_shipping_outlined,
            label: l10n.storeDeliveryToHome,
            selected: state.fulfillmentMethod == FulfillmentMethod.delivery,
            onTap: () => cubit.setFulfillmentMethod(FulfillmentMethod.delivery),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ToggleTile(
            icon: Icons.storefront_outlined,
            label: l10n.storePickupAtStore,
            selected: state.fulfillmentMethod == FulfillmentMethod.pickup,
            onTap: () => cubit.setFulfillmentMethod(FulfillmentMethod.pickup),
          ),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.12)
                : colors.secondary,
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(
              color: selected ? colors.primary : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryAddressSection extends StatelessWidget {
  const _DeliveryAddressSection({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(l10n.storeDeliveryAddressLabel),
        for (final address in state.addresses)
          _AddressCard(
            address: address,
            selected: state.selectedAddressId == address.id,
            onTap: () => cubit.selectAddress(address.id),
          ),
        OutlinedButton.icon(
          onPressed: () =>
              showStoreAddressFormSheet(context, onSave: cubit.addAddress),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.storeAddAddress),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
        ),
        if (state.selectedAddress != null) ...[
          _FieldLabel(l10n.storeShippingLabel),
          if (state.loadingShipping)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: GoiasLoadingIndicator()),
            )
          else
            for (final option in state.shippingOptions)
              _ShippingOptionTile(
                option: option,
                selected: state.selectedShippingSpeed == option.speed,
                onTap: () => cubit.selectShippingSpeed(option.speed),
              ),
        ],
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final CustomerAddress address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected ? colors.primary : colors.textHint,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.oneLine,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.storeZipCodePrefix(address.zipCode),
                      style: TextStyle(fontSize: 11.5, color: colors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShippingOptionTile extends StatelessWidget {
  const _ShippingOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ShippingOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: selected ? colors.primary : colors.textHint,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shippingSpeedLabel(l10n, option.speed),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      shippingEtaLabel(l10n, option.speed),
                      style: TextStyle(fontSize: 11.5, color: colors.textHint),
                    ),
                  ],
                ),
              ),
              Text(
                option.isFree ? l10n.storeFree : formatBrl(option.price),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: option.isFree ? colors.gold : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupSection extends StatelessWidget {
  const _PickupSection({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();
    const pickupInfo = PickupInformation();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          margin: const EdgeInsets.only(top: AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          ),
          child: Row(
            children: [
              Icon(Icons.storefront_rounded, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickupInfo.storeName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      pickupInfo.fullAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _FieldLabel(l10n.storePickupResponsibleLabel),
        _ToggleRow(
          selected: state.selfPickup,
          onTapSelf: () => cubit.setSelfPickup(true),
          onTapOther: () => cubit.setSelfPickup(false),
        ),
        if (!state.selfPickup) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            onChanged: (v) => cubit.updatePickupResponsible(name: v),
            decoration: _fieldDecoration(
              context,
              l10n.storePickupResponsibleNameField,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [cpfInputFormatter()],
            onChanged: (v) => cubit.updatePickupResponsible(cpf: v),
            decoration: _fieldDecoration(
              context,
              l10n.storePickupResponsibleCpfField,
            ),
          ),
        ],
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.selected,
    required this.onTapSelf,
    required this.onTapOther,
  });

  final bool selected;
  final VoidCallback onTapSelf;
  final VoidCallback onTapOther;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _ToggleTile(
            icon: Icons.person_outline_rounded,
            label: l10n.storePickupSelf,
            selected: selected,
            onTap: onTapSelf,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ToggleTile(
            icon: Icons.group_outlined,
            label: l10n.storePickupOther,
            selected: !selected,
            onTap: onTapOther,
          ),
        ),
      ],
    );
  }
}
