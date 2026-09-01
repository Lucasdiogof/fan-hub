import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_button_styles.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/store_product.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/cubit/cart_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/product_detail_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/product_detail_state.dart';
import 'package:goias_app/features/store/presentation/store_display_labels.dart';
import 'package:goias_app/features/store/presentation/widgets/cart_icon_button.dart';
import 'package:goias_app/features/store/presentation/widgets/store_price_block.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailCubit(sl<StoreRepository>())..load(productId),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  const _ProductDetailView();

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  /// Âncora da seção Tamanho — a barra de ação rola até aqui quando o usuário
  /// tenta comprar sem escolher tamanho (ver `_ActionBar`).
  final _sizeSectionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isWide = MediaQuery.sizeOf(context).width >= 840;
    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: isWide
          ? null
          : BlocBuilder<ProductDetailCubit, ProductDetailState>(
              builder: (context, state) {
                if (state.status != LoadStatus.success ||
                    !state.product!.isAvailable) {
                  return const SizedBox.shrink();
                }
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(top: BorderSide(color: colors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _ActionBar(state: state, sizeKey: _sizeSectionKey),
                  ),
                );
              },
            ),
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
                      const Spacer(),
                      const CartIconButton(),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
                    builder: (context, state) {
                      return switch (state.status) {
                        LoadStatus.initial || LoadStatus.loading =>
                          const Center(child: GoiasLoadingIndicator()),
                        LoadStatus.error || LoadStatus.empty => Center(
                          child: StateMessage(
                            icon: Icons.error_outline_rounded,
                            title: context.l10n.storeProductLoadErrorTitle,
                            message: context.l10n.storeProductLoadErrorMessage,
                            actionLabel: context.l10n.storeBackToStoreButton,
                            onAction: () => context.canPop()
                                ? context.pop()
                                : context.go('/store'),
                          ),
                        ),
                        LoadStatus.success => _ProductDetailContent(
                          state: state,
                          sizeKey: _sizeSectionKey,
                        ),
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

class _ProductDetailContent extends StatelessWidget {
  const _ProductDetailContent({required this.state, required this.sizeKey});

  final ProductDetailState state;
  final GlobalKey sizeKey;

  @override
  Widget build(BuildContext context) {
    final product = state.product!;
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    if (isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Gallery(product: product)),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(
              child: _ProductInfo(
                state: state,
                showActions: true,
                sizeKey: sizeKey,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _Gallery(product: product),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _ProductInfo(
              state: state,
              showActions: false,
              sizeKey: sizeKey,
            ),
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.product});

  final StoreProduct product;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  void _openZoom(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, _, _) =>
          _ZoomGallery(images: widget.product.images, initialIndex: _index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final images = widget.product.images;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  label: l10n.storeProductPhotoLabel(
                    widget.product.name,
                    _index + 1,
                    images.length,
                  ),
                  image: true,
                  onTapHint: l10n.storeZoomImageHint,
                  child: PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => _openZoom(context),
                      child: Container(
                        color: colors.surface,
                        child: ExcludeSemantics(
                          child: Image.asset(images[i], fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: ExcludeSemantics(
                    child: _GalleryIconButton(
                      icon: Icons.ios_share_rounded,
                      semanticLabel: l10n.storeShareProduct,
                      onTap: () => unawaited(
                        SharePlus.instance.share(
                          ShareParams(
                            text: widget.product.sourceUrl != null
                                ? '${widget.product.name} — Goiás Store\n${widget.product.sourceUrl}'
                                : '${widget.product.name} — Goiás Store',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  Container(
                    width: i == _index ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _index ? colors.primary : colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GalleryIconButton extends StatelessWidget {
  const _GalleryIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.92),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: colors.textSecondary),
        ),
      ),
    );
  }
}

/// Visualizador em tela cheia com zoom (pinça/duplo toque) — só abre ao
/// tocar numa foto da galeria, nunca substitui o `PageView` principal.
class _ZoomGallery extends StatefulWidget {
  const _ZoomGallery({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_ZoomGallery> createState() => _ZoomGalleryState();
}

class _ZoomGalleryState extends State<_ZoomGallery> {
  late final _controller = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.asset(widget.images[i], fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            top: AppSpacing.md,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({
    required this.state,
    required this.showActions,
    required this.sizeKey,
  });

  final ProductDetailState state;
  final bool showActions;
  final GlobalKey sizeKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final product = state.product!;
    final cubit = context.read<ProductDetailCubit>();

    final metaParts = <String>[
      categoryDisplayName(
        context.l10n,
        product.categoryIds.firstWhere(
          (id) => id != 'personalizable',
          orElse: () => product.categoryIds.isEmpty
              ? product.audience.name
              : product.categoryIds.first,
        ),
      ),
      audienceDisplayName(context.l10n, product.audience),
      product.brand,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.reference.isEmpty
              ? metaParts.join(' · ')
              : '${metaParts.join(' · ')} · ${l10n.storeReferenceLabel} ${product.reference}',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        StorePriceBlock(product: product),
        const SizedBox(height: AppSpacing.xl),
        if (!product.isAvailable)
          _InlineNotice(text: l10n.storeProductSoldOut)
        else ...[
          if (product.availableSizes.isNotEmpty) ...[
            KeyedSubtree(key: sizeKey, child: _FieldLabel(l10n.storeSizeLabel)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in product.variations)
                  ChoiceChip(
                    label: Text(v.size),
                    selected: state.selectedSize == v.size,
                    onSelected: v.inStock
                        ? (_) => cubit.selectSize(v.size)
                        : null,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: !v.inStock
                          ? colors.textHint
                          : state.selectedSize == v.size
                          ? colors.onPrimary
                          : colors.textSecondary,
                    ),
                    selectedColor: colors.primary,
                    backgroundColor: colors.secondary,
                    disabledColor: colors.secondary.withValues(alpha: 0.5),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
              ],
            ),
            if (state.blockReason == ProductBlockReason.chooseSize) ...[
              const SizedBox(height: 6),
              if (state.showSizeRequired)
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: colors.gold,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l10n.storeChooseSizeMessage,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: colors.gold,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  l10n.storeChooseSizeMessage,
                  style: TextStyle(fontSize: 11.5, color: colors.textHint),
                ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
          if (product.allowsPersonalization) ...[
            _PersonalizationForm(state: state),
            const SizedBox(height: AppSpacing.xl),
          ],
          _FieldLabel(l10n.storeQuantityLabel),
          const SizedBox(height: AppSpacing.sm),
          _QuantityStepper(
            quantity: state.quantity,
            onChanged: cubit.setQuantity,
          ),
          const SizedBox(height: AppSpacing.xl),
          const _DeliveryOrPickupPreview(),
        ],
        const SizedBox(height: AppSpacing.xl),
        _FieldLabel(l10n.storeDetailsLabel),
        const SizedBox(height: AppSpacing.sm),
        Text(
          product.description,
          style: TextStyle(
            fontSize: 13,
            color: colors.textSecondary,
            height: 1.5,
          ),
        ),
        if (product.specifications.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          for (final spec in product.specifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      spec.label,
                      style: TextStyle(fontSize: 12.5, color: colors.textHint),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      spec.value,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (showActions) ...[
          const SizedBox(height: AppSpacing.xxl),
          if (product.isAvailable) _ActionBar(state: state, sizeKey: sizeKey),
        ],
      ],
    );
  }
}

/// Prévia de entrega/retirada — só ilustra as duas opções (frete calculado
/// de verdade e retirada de verdade só existem no checkout, ver
/// `CheckoutCubit`); aqui é seleção local, sem persistir nada.
class _DeliveryOrPickupPreview extends StatefulWidget {
  const _DeliveryOrPickupPreview();

  @override
  State<_DeliveryOrPickupPreview> createState() =>
      _DeliveryOrPickupPreviewState();
}

class _DeliveryOrPickupPreviewState extends State<_DeliveryOrPickupPreview> {
  bool _pickup = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(l10n.storeDeliveryOrPickupLabel),
        const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DeliveryOption(
                  label: l10n.storeDeliveryToHome,
                  selected: !_pickup,
                  onTap: () => setState(() => _pickup = false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _DeliveryOption(
                  label: l10n.storePickupAtStore,
                  note: l10n.storePickupFreeNote,
                  selected: _pickup,
                  onTap: () => setState(() => _pickup = true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  const _DeliveryOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.note,
  });

  final String label;
  final String? note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.primary.withValues(alpha: 0.08) : null,
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? colors.primary : colors.textPrimary,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: colors.gold,
                  ),
                ),
              ],
            ],
          ),
        ),
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
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: colors.textHint,
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.text});

  final String text;

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
              text,
              style: TextStyle(
                fontSize: 12.5,
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

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Semantics(
      label: l10n.storeQuantityLabel,
      value: '$quantity',
      increasedValue: '${quantity + 1}',
      decreasedValue: '${quantity - 1}',
      onIncrease: () => onChanged(quantity + 1),
      onDecrease: () => onChanged(quantity - 1),
      child: Row(
        children: [
          ExcludeSemantics(
            child: _StepButton(
              icon: Icons.remove_rounded,
              onTap: () => onChanged(quantity - 1),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          ExcludeSemantics(
            child: _StepButton(
              icon: Icons.add_rounded,
              onTap: () => onChanged(quantity + 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: colors.textPrimary),
      ),
    );
  }
}

class _PersonalizationForm extends StatefulWidget {
  const _PersonalizationForm({required this.state});

  final ProductDetailState state;

  @override
  State<_PersonalizationForm> createState() => _PersonalizationFormState();
}

class _PersonalizationFormState extends State<_PersonalizationForm> {
  late final _nameController = TextEditingController(
    text: widget.state.personalizedName ?? '',
  );
  late final _numberController = TextEditingController(
    text: widget.state.personalizedNumber?.toString() ?? '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final cubit = context.read<ProductDetailCubit>();
    final personalization = widget.state.product!.personalization!;
    final surcharge = widget.state.personalizationSurcharge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(l10n.storePersonalizationLabel),
        const SizedBox(height: AppSpacing.sm),
        if (personalization.allowsName)
          TextField(
            controller: _nameController,
            maxLength: personalization.maxNameLength,
            textCapitalization: TextCapitalization.characters,
            onChanged: cubit.setPersonalizedName,
            decoration: InputDecoration(
              labelText: l10n.storePersonalizationNameField(
                formatBrl(personalization.nameCost),
              ),
              isDense: true,
              filled: true,
              fillColor: colors.secondary,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        if (personalization.allowsName && personalization.allowsNumber)
          const SizedBox(height: AppSpacing.sm),
        if (personalization.allowsNumber)
          TextField(
            controller: _numberController,
            keyboardType: TextInputType.number,
            maxLength: 2,
            onChanged: (value) {
              final n = int.tryParse(value);
              cubit.setPersonalizedNumber(
                n != null &&
                        n >= personalization.minNumber &&
                        n <= personalization.maxNumber
                    ? n
                    : null,
              );
            },
            decoration: InputDecoration(
              labelText: l10n.storePersonalizationNumberField(
                formatBrl(personalization.numberCost),
              ),
              isDense: true,
              filled: true,
              fillColor: colors.secondary,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        if (surcharge > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.storePersonalizationSurchargeNote(formatBrl(surcharge)),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.gold,
            ),
          ),
        ],
      ],
    );
  }
}

/// Barra de ação fixa no rodapé — resumo compacto do total numa linha e, logo
/// abaixo, duas ações lado a lado: "Comprar agora" (dourado, ~60%, conversão
/// direta pro checkout) como principal e "Adicionar" (outline, ~40%) como
/// secundária. Loading independente por botão. Faltando tamanho, os botões
/// não ficam apagados: o toque rola até e destaca a seção Tamanho.
class _ActionBar extends StatefulWidget {
  const _ActionBar({required this.state, required this.sizeKey});

  final ProductDetailState state;
  final GlobalKey sizeKey;

  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  bool _adding = false;
  bool _buying = false;

  ProductDetailState get state => widget.state;

  CartItem _buildItem(StoreProduct product, String size) => CartItem(
    id: '${product.id}_${size}_${DateTime.now().microsecondsSinceEpoch}',
    productId: product.id,
    productName: product.name,
    thumbnail: product.thumbnail,
    size: size,
    unitPrice: product.price,
    quantity: state.quantity,
    personalizedName: state.personalizedName,
    personalizedNumber: state.personalizedNumber,
    personalizationSurcharge: state.personalizationSurcharge,
  );

  /// Retorna `true` quando faltou tamanho e o usuário foi guiado (não segue
  /// pra adicionar/comprar); `false` quando está tudo certo pra prosseguir.
  bool _guardSize() {
    if (state.blockReason != ProductBlockReason.chooseSize) return false;
    context.read<ProductDetailCubit>().requireSize();
    HapticFeedback.mediumImpact();
    final ctx = widget.sizeKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
    return true;
  }

  Future<void> _add() async {
    if (_adding || _buying || _guardSize()) return;
    final product = state.product!;
    final size = state.selectedSize ?? product.availableSizes.first;
    setState(() => _adding = true);
    await context.read<CartCubit>().addItem(_buildItem(product, size));
    if (!mounted) return;
    setState(() => _adding = false);
    _showAddedConfirmation();
  }

  Future<void> _buyNow() async {
    if (_adding || _buying || _guardSize()) return;
    final product = state.product!;
    final size = state.selectedSize ?? product.availableSizes.first;
    setState(() => _buying = true);
    await context.read<CartCubit>().addItem(_buildItem(product, size));
    if (!mounted) return;
    setState(() => _buying = false);
    unawaited(context.push('/store/checkout'));
  }

  void _showAddedConfirmation() {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.storeAddedToCartSnackbar),
        action: SnackBarAction(
          label: l10n.storeSeeCartAction,
          onPressed: () => context.push('/store/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final outOfStock = state.blockReason == ProductBlockReason.outOfStock;
    final total = state.unitPriceWithPersonalization * state.quantity;
    final busy = _adding || _buying;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (outOfStock) ...[
          _InlineNotice(text: l10n.storeVariationSoldOut),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            Text(
              l10n.storeTotal,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              formatBrl(total),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              flex: 45,
              child: ElevatedButton(
                onPressed: (outOfStock || busy) ? null : _add,
                style: goldFilledStyle(context),
                child: _adding
                    ? const _BtnSpinner(color: Colors.white)
                    : Text(
                        l10n.storeAddToCartButton,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.05,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              flex: 55,
              child: ElevatedButton(
                onPressed: (outOfStock || busy) ? null : _buyNow,
                style: matchCtaFilledStyle(context, minHeight: 52),
                child: _buying
                    ? const _BtnSpinner(color: Colors.white)
                    : Text(
                        l10n.storeBuyNowButton,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BtnSpinner extends StatelessWidget {
  const _BtnSpinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
