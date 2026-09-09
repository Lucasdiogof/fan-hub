import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/repositories/delivery_address_repository.dart';
import 'package:goias_app/features/store/domain/repositories/store_orders_repository.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/checkout_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/checkout_state.dart';
import 'package:goias_app/features/store/presentation/store_display_labels.dart';
import 'package:goias_app/features/store/presentation/widgets/store_address_form_sheet.dart';
import 'package:goias_app/features/store/presentation/widgets/store_price_block.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/validation/app_validators.dart';
import 'package:goias_app/shared/validation/field_touch.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

part '../widgets/checkout_payment_review.dart';

List<String> _stepLabels(AppLocalizations l10n) => [
  l10n.storeStepIdentification,
  l10n.storeStepDelivery,
  l10n.storeStepReview,
  l10n.storeStepPayment,
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
        sl<StoreOrdersRepository>(),
        sl<DeliveryAddressRepository>(),
        cart,
        prefillName: profile?.fullName,
        prefillEmail: profile?.email,
        prefillCpf: profile?.cpf,
        prefillPhone: profile?.phone,
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
          (previous.order == null && current.order != null) ||
          (previous.errorMessage == null && current.errorMessage != null),
      listener: (context, state) {
        if (state.order != null) {
          context.read<CartCubit>().clear();
          return;
        }
        final l10n = context.l10n;
        AppBottomSheet.show(
          context,
          title: l10n.storeOrderCreateErrorTitle,
          description: l10n.storeOrderCreateErrorMessage,
          icon: Icons.error_outline_rounded,
          confirmLabel: l10n.commonRetry,
          onConfirm: () => context.read<CheckoutCubit>().confirmOrder(),
        );
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
              AppSpacing.lg,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: bold ? 14 : 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                color: bold ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: bold ? 15 : 12.5,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                color:
                    color ?? (bold ? colors.textPrimary : colors.textSecondary),
              ),
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
  // O perfil guarda CPF/telefone só em dígitos — passa pelo formatador na
  // hora de pré-preencher, senão mostra "12345678900" cru até o usuário
  // digitar algo e o `inputFormatters` do campo entrar em ação.
  late final _cpfController = TextEditingController(
    text: cpfInputFormatter()
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: widget.state.cpf),
        )
        .text,
  );
  late final _emailController = TextEditingController(text: widget.state.email);
  late final _phoneController = TextEditingController(
    text: phoneInputFormatter()
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: widget.state.phone),
        )
        .text,
  );

  final _nameTouch = FieldTouch();
  final _cpfTouch = FieldTouch();
  final _emailTouch = FieldTouch();
  final _phoneTouch = FieldTouch();
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    final l10n = context.l10n;
    final valid =
        AppValidators.fullName(l10n, _nameController.text) == null &&
        AppValidators.cpf(l10n, _cpfController.text) == null &&
        AppValidators.email(l10n, _emailController.text) == null &&
        AppValidators.mobilePhone(l10n, _phoneController.text) == null;
    if (valid) context.read<CheckoutCubit>().nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();

    return _StepScaffold(
      state: widget.state,
      primaryLabel: l10n.storeContinueButton,
      onPrimaryPressed: widget.state.canProceedFromIdentification
          ? _submit
          : null,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) {
              _nameTouch.touched = true;
              cubit.updateIdentification(fullName: v);
              setState(() {});
            },
            decoration: _fieldDecoration(
              context,
              l10n.storeFullNameLabel,
              errorText: _nameTouch.errorFor(
                _nameController.text,
                submitted: _submitted,
                format: (v) => AppValidators.fullName(l10n, v),
                requiredMessage: l10n.storeValFullNameRequired,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _cpfController,
            keyboardType: TextInputType.number,
            inputFormatters: [cpfInputFormatter()],
            onChanged: (v) {
              _cpfTouch.touched = true;
              cubit.updateIdentification(cpf: v);
              setState(() {});
            },
            decoration: _fieldDecoration(
              context,
              l10n.storeCpfLabel,
              errorText: _cpfTouch.errorFor(
                _cpfController.text,
                submitted: _submitted,
                format: (v) => AppValidators.cpf(l10n, v),
                requiredMessage: l10n.storeValCpfRequired,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) {
              _emailTouch.touched = true;
              cubit.updateIdentification(email: v);
              setState(() {});
            },
            decoration: _fieldDecoration(
              context,
              l10n.commonEmailLabel,
              errorText: _emailTouch.errorFor(
                _emailController.text,
                submitted: _submitted,
                format: (v) => AppValidators.email(l10n, v),
                requiredMessage: l10n.validatorEmailRequired,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [phoneInputFormatter()],
            onChanged: (v) {
              _phoneTouch.touched = true;
              cubit.updateIdentification(phone: v);
              setState(() {});
            },
            decoration: _fieldDecoration(
              context,
              l10n.storePhoneLabel,
              errorText: _phoneTouch.errorFor(
                _phoneController.text,
                submitted: _submitted,
                format: (v) => AppValidators.mobilePhone(l10n, v),
                requiredMessage: l10n.validatorPhoneRequired,
              ),
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
    // "Retirar na loja" só existe pro clube que tem ponto de retirada REAL
    // (`ClubConfig.integrations.pickupAddress != null`) — nunca um `if
    // (club == bragantino)` hardcoded, e nunca mostrado como
    // "indisponível"/placeholder: o clube sem endereço simplesmente não vê
    // a opção, só entrega. Goiás (tem endereço) continua exatamente como
    // sempre foi.
    final hasPickup = sl<ClubConfig>().integrations.pickupAddress != null;
    final effectiveMethod = hasPickup
        ? state.fulfillmentMethod
        : FulfillmentMethod.delivery;
    return _StepScaffold(
      state: state,
      primaryLabel: context.l10n.storeContinueButton,
      onPrimaryPressed: state.canProceedFromDelivery ? cubit.nextStep : null,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPickup) _FulfillmentToggle(state: state),
          if (effectiveMethod == FulfillmentMethod.delivery)
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

class _DeliveryAddressSection extends StatefulWidget {
  const _DeliveryAddressSection({required this.state});

  final CheckoutState state;

  @override
  State<_DeliveryAddressSection> createState() =>
      _DeliveryAddressSectionState();
}

class _DeliveryAddressSectionState extends State<_DeliveryAddressSection> {
  late final Future<UserAddress?> _residentialFuture = _loadResidential();

  Future<UserAddress?> _loadResidential() async {
    final result = await sl<ProfileRepository>().getAddress();
    return result is Success<UserAddress?> ? result.data : null;
  }

  Future<void> _useResidential(CheckoutCubit cubit, UserAddress residential) {
    return cubit.addAddress(
      CustomerAddress(
        id: 'addr_${DateTime.now().microsecondsSinceEpoch}',
        zipCode: residential.zipCode ?? '',
        street: residential.street ?? '',
        number: residential.number ?? '',
        complement: residential.complement,
        neighborhood: residential.neighborhood ?? '',
        city: residential.city ?? '',
        state: residential.state ?? '',
      ),
    );
  }

  Future<void> _openChooser(UserAddress? residential) async {
    final cubit = context.read<CheckoutCubit>();
    await AppModalSheet.show<void>(
      context,
      builder: (sheetContext) => _AddressChooserSheet(
        addresses: widget.state.addresses,
        selectedId: widget.state.selectedAddressId,
        hasResidential: residential != null && !residential.isEmpty,
        onSelect: (id) {
          cubit.selectAddress(id);
          Navigator.of(sheetContext).pop();
        },
        onAddNew: () {
          Navigator.of(sheetContext).pop();
          showStoreAddressFormSheet(context, onSave: cubit.addAddress);
        },
        onUseResidential: residential == null
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                _useResidential(cubit, residential);
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();
    final state = widget.state;

    return FutureBuilder<UserAddress?>(
      future: _residentialFuture,
      builder: (context, snapshot) {
        final residential = snapshot.data;
        final hasResidential = residential != null && !residential.isEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldLabel(l10n.storeDeliveryAddressSummaryTitle),
            if (state.selectedAddress != null)
              _SelectedAddressSummary(
                address: state.selectedAddress!,
                onChange: () => _openChooser(residential),
              )
            else
              _NoDeliveryAddressState(
                hasResidential: hasResidential,
                onUseResidential: hasResidential
                    ? () => _useResidential(cubit, residential)
                    : null,
                onAddNew: () => showStoreAddressFormSheet(
                  context,
                  onSave: cubit.addAddress,
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
      },
    );
  }
}

/// Resumo do endereço já selecionado (padrão, na maioria das vezes) — só um
/// CTA discreto pra abrir o seletor completo, em vez da lista sempre
/// expandida de antes.
class _SelectedAddressSummary extends StatelessWidget {
  const _SelectedAddressSummary({
    required this.address,
    required this.onChange,
  });

  final CustomerAddress address;
  final VoidCallback onChange;

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
          Icon(Icons.location_on_outlined, color: colors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.label?.isNotEmpty == true)
                  Text(
                    address.label!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                Text(
                  address.oneLine,
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(l10n.storeChangeAddressButton),
          ),
        ],
      ),
    );
  }
}

/// Nenhum endereço de entrega ainda — nunca abre o formulário sozinho; só
/// oferece os dois caminhos possíveis, condicionados a existir (ou não) um
/// endereço residencial pra copiar.
class _NoDeliveryAddressState extends StatelessWidget {
  const _NoDeliveryAddressState({
    required this.hasResidential,
    required this.onUseResidential,
    required this.onAddNew,
  });

  final bool hasResidential;
  final VoidCallback? onUseResidential;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.storeNoDeliveryAddressTitle,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasResidential)
            OutlinedButton(
              onPressed: onUseResidential,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: Text(l10n.storeUseResidentialAddress),
            ),
          if (hasResidential) const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onAddNew,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              hasResidential
                  ? l10n.storeAddAnotherAddress
                  : l10n.storeAddAddress,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: colors.textSecondary,
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet "Escolha onde receber" — lista todos os endereços já
/// salvos como radio-tiles (reaproveita `_AddressCard`) + os dois atalhos de
/// criação. Abrir/fechar é decisão de quem chama (`_openChooser`), não do
/// sheet em si.
class _AddressChooserSheet extends StatelessWidget {
  const _AddressChooserSheet({
    required this.addresses,
    required this.selectedId,
    required this.hasResidential,
    required this.onSelect,
    required this.onAddNew,
    required this.onUseResidential,
  });

  final List<CustomerAddress> addresses;
  final String? selectedId;
  final bool hasResidential;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddNew;
  final VoidCallback? onUseResidential;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.storeChooseDeliveryAddressTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final address in addresses)
              _AddressCard(
                address: address,
                selected: selectedId == address.id,
                onTap: () => onSelect(address.id),
              ),
            OutlinedButton.icon(
              onPressed: onAddNew,
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
            if (onUseResidential != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onUseResidential,
                child: Text(l10n.storeUseResidentialAddress),
              ),
            ],
          ],
        ),
      ),
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

class _PickupSection extends StatefulWidget {
  const _PickupSection({required this.state});

  final CheckoutState state;

  @override
  State<_PickupSection> createState() => _PickupSectionState();
}

class _PickupSectionState extends State<_PickupSection> {
  final _nameTouch = FieldTouch();
  final _cpfTouch = FieldTouch();

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final colors = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();
    final pickupInfo = PickupInformation.forActiveClub();
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
            onChanged: (v) {
              _nameTouch.touched = true;
              cubit.updatePickupResponsible(name: v);
              setState(() {});
            },
            decoration: _fieldDecoration(
              context,
              l10n.storePickupResponsibleNameField,
              errorText: _nameTouch.errorFor(
                state.pickupResponsibleName ?? '',
                submitted: false,
                format: (v) => AppValidators.fullName(l10n, v),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [cpfInputFormatter()],
            onChanged: (v) {
              _cpfTouch.touched = true;
              cubit.updatePickupResponsible(cpf: v);
              setState(() {});
            },
            decoration: _fieldDecoration(
              context,
              l10n.storePickupResponsibleCpfField,
              errorText: _cpfTouch.errorFor(
                state.pickupResponsibleCpf ?? '',
                submitted: false,
                format: (v) => AppValidators.cpf(l10n, v),
              ),
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
