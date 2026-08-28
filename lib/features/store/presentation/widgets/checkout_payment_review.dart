part of '../pages/checkout_page.dart';

// ---------------------------------------------------------------------
// Etapa 3 — Pagamento simulado
// ---------------------------------------------------------------------

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();
    return _StepScaffold(
      state: state,
      primaryLabel: l10n.storeContinueButton,
      onPrimaryPressed: state.canProceedFromPayment ? cubit.nextStep : null,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ToggleTile(
                  icon: Icons.qr_code_rounded,
                  label: l10n.storePaymentPix,
                  selected: state.paymentMethod == PaymentMethod.pix,
                  onTap: () => cubit.choosePaymentMethod(PaymentMethod.pix),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ToggleTile(
                  icon: Icons.credit_card_rounded,
                  label: l10n.storeCreditCard,
                  selected: state.paymentMethod == PaymentMethod.creditCard,
                  onTap: () =>
                      cubit.choosePaymentMethod(PaymentMethod.creditCard),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.paymentMethod == PaymentMethod.pix)
            _PixPaymentForm(state: state)
          else
            _CardPaymentForm(state: state),
        ],
      ),
    );
  }
}

class _DemoDisclaimer extends StatelessWidget {
  const _DemoDisclaimer();

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
          Icon(Icons.info_outline_rounded, size: 18, color: colors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.storeDemoDisclaimer,
              style: TextStyle(
                fontSize: 12,
                color: colors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PixPaymentForm extends StatelessWidget {
  const _PixPaymentForm({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();

    if (state.paymentApproved) {
      return _PaymentApprovedNotice(label: l10n.storePixApproved);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          ),
          child: Column(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 96,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.storeQrCodeNote,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _DemoDisclaimer(),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(
          onPressed: () => cubit.simulatePayment(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: Text(
            l10n.storeSimulatePixButton,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _CardPaymentForm extends StatefulWidget {
  const _CardPaymentForm({required this.state});

  final CheckoutState state;

  @override
  State<_CardPaymentForm> createState() => _CardPaymentFormState();
}

class _CardPaymentFormState extends State<_CardPaymentForm> {
  final _numberController = TextEditingController();
  final _holderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  int _installments = 1;

  @override
  void dispose() {
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();
    final total = widget.state.total;

    if (widget.state.paymentApproved) {
      final summary = widget.state.cardSummary;
      return _PaymentApprovedNotice(
        label: summary == null
            ? l10n.storeCardApprovedGeneric
            : l10n.storeCardApprovedWithDigits(summary.lastFourDigits),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _numberController,
          keyboardType: TextInputType.number,
          maxLength: 19,
          decoration: _fieldDecoration(
            context,
            l10n.storeCardNumberLabel,
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _holderController,
          textCapitalization: TextCapitalization.characters,
          decoration: _fieldDecoration(context, l10n.storeCardHolderLabel),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                decoration: _fieldDecoration(
                  context,
                  l10n.storeCardExpiryLabel,
                ).copyWith(counterText: ''),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: _fieldDecoration(
                  context,
                  l10n.storeCardCvvLabel,
                ).copyWith(counterText: ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<int>(
          initialValue: _installments,
          decoration: _fieldDecoration(
            context,
            l10n.storeInstallmentsFieldLabel,
          ),
          items: [
            for (var i = 1; i <= 6; i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                  i == 1
                      ? l10n.storeInstallmentsCash(formatBrl(total))
                      : l10n.storeInstallmentsNoInterest(
                          i,
                          formatBrl(total / i),
                        ),
                ),
              ),
          ],
          onChanged: (v) => setState(() => _installments = v ?? 1),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _DemoDisclaimer(),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton(
          onPressed: () {
            final digits = onlyDigits(_numberController.text);
            final lastFour = digits.length >= 4
                ? digits.substring(digits.length - 4)
                : digits;
            cubit.simulatePayment(
              cardHolderName: _holderController.text.trim(),
              cardLastFourDigits: lastFour,
              installments: _installments,
            );
            // Dados sensíveis descartados assim que o resumo é montado —
            // nunca chegam a sair desta tela.
            _numberController.clear();
            _cvvController.clear();
            _expiryController.clear();
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: Text(
            l10n.storeSimulatePaymentButton,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _PaymentApprovedNotice extends StatelessWidget {
  const _PaymentApprovedNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Etapa 4 — Revisão
// ---------------------------------------------------------------------

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CheckoutCubit>();
    return _StepScaffold(
      state: state,
      showSummarySidebar: false,
      primaryLabel: l10n.storeConfirmOrderButton,
      loading: state.submitting,
      onPrimaryPressed: state.canConfirmOrder ? cubit.confirmOrder : null,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReviewSection(
            title: l10n.storeStepIdentification,
            onEdit: () => cubit.goToStep(CheckoutStep.identification),
            children: [
              Text(state.fullName, style: _reviewValueStyle(context)),
              Text(maskCpf(state.cpf), style: _reviewHintStyle(context)),
              Text(maskEmail(state.email), style: _reviewHintStyle(context)),
              Text(maskPhone(state.phone), style: _reviewHintStyle(context)),
            ],
          ),
          _ReviewSection(
            title: state.fulfillmentMethod == FulfillmentMethod.pickup
                ? l10n.storePickupSectionTitle
                : l10n.storeStepDelivery,
            onEdit: () => cubit.goToStep(CheckoutStep.delivery),
            children: state.fulfillmentMethod == FulfillmentMethod.pickup
                ? [
                    Text(
                      const PickupInformation().fullAddress,
                      style: _reviewValueStyle(context),
                    ),
                    Text(
                      state.selfPickup
                          ? l10n.storePickupBySelf
                          : l10n.storePickupByOther(
                              state.pickupResponsibleName ?? '',
                            ),
                      style: _reviewHintStyle(context),
                    ),
                  ]
                : [
                    if (state.selectedAddress != null)
                      Text(
                        state.selectedAddress!.oneLine,
                        style: _reviewValueStyle(context),
                      ),
                    if (state.selectedShippingOption != null)
                      Text(
                        '${shippingSpeedLabel(l10n, state.selectedShippingOption!.speed)} · '
                        '${shippingEtaLabel(l10n, state.selectedShippingOption!.speed)}',
                        style: _reviewHintStyle(context),
                      ),
                  ],
          ),
          _ReviewSection(
            title: l10n.storeStepPayment,
            onEdit: () => cubit.goToStep(CheckoutStep.payment),
            children: [
              Text(
                state.paymentMethod == PaymentMethod.pix
                    ? l10n.storePaymentPix
                    : l10n.storeCardSummaryLine(
                        state.cardSummary?.lastFourDigits ?? '----',
                        state.cardSummary?.installments ?? 1,
                      ),
                style: _reviewValueStyle(context),
              ),
            ],
          ),
          _ReviewItemsSection(state: state),
          const SizedBox(height: AppSpacing.md),
          _AcceptTermsRow(state: state),
          const SizedBox(height: AppSpacing.md),
          const _DemoDisclaimer(),
        ],
      ),
    );
  }
}

TextStyle _reviewValueStyle(BuildContext context) => TextStyle(
  fontSize: 13.5,
  fontWeight: FontWeight.w700,
  color: context.colors.textPrimary,
);

TextStyle _reviewHintStyle(BuildContext context) =>
    TextStyle(fontSize: 12, color: context.colors.textSecondary);

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
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
              ),
              Semantics(
                button: true,
                label: '${l10n.storeEdit}: $title',
                child: InkWell(
                  onTap: onEdit,
                  child: Text(
                    l10n.storeEdit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewItemsSection extends StatelessWidget {
  const _ReviewItemsSection({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cart = state.cart;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.productName} (${item.size})',
                      style: _reviewHintStyle(context),
                    ),
                  ),
                  Text(
                    formatBrl(item.lineTotal),
                    style: _reviewValueStyle(context),
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

class _AcceptTermsRow extends StatelessWidget {
  const _AcceptTermsRow({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<CheckoutCubit>();
    return MergeSemantics(
      child: InkWell(
        onTap: () => cubit.setAcceptedTerms(!state.acceptedTerms),
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Row(
          children: [
            Checkbox(
              value: state.acceptedTerms,
              onChanged: (v) => cubit.setAcceptedTerms(v ?? false),
              activeColor: colors.primary,
            ),
            Expanded(
              child: Text(
                context.l10n.storeAcceptTerms,
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Etapa 5 — Confirmação
// ---------------------------------------------------------------------

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final order = state.order;
    if (order == null) return const Center(child: GoiasLoadingIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxxl,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, size: 44, color: colors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.storeOrderConfirmedTitle,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order.id,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.gold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarRow(l10n.storeItemsLabel, '${order.itemCount}'),
                _SidebarRow(
                  order.isPickup
                      ? l10n.storePickupWord
                      : l10n.storeStepDelivery,
                  order.isPickup
                      ? const PickupInformation().fullAddress
                      : (order.shippingOption != null
                            ? shippingEtaLabel(
                                l10n,
                                order.shippingOption!.speed,
                              )
                            : ''),
                ),
                const Divider(height: AppSpacing.lg),
                _SidebarRow(
                  l10n.storeTotal,
                  formatBrl(order.total),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppPrimaryButton(
            label: l10n.storeTrackOrderButton,
            onPressed: () =>
                context.go('/store/orders/${order.id}', extra: order),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => context.go('/store'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              l10n.storeContinueShoppingButton,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.go('/'),
            child: Text(l10n.storeBackHomeButton),
          ),
        ],
      ),
    );
  }
}
