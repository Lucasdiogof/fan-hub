import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/repositories/delivery_address_repository.dart';
import 'package:goias_app/features/store/presentation/widgets/store_address_form_sheet.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Tela "Endereços de Entrega" — a lista de endereços que a conta pode usar
/// pra receber compras da Loja. Conceitualmente separada do endereço
/// RESIDENCIAL (único, editado em `AddressPage`): aqui pode haver zero, um
/// ou vários, cada um com seu próprio apelido.
class StoreAddressesPage extends StatefulWidget {
  const StoreAddressesPage({super.key});

  @override
  State<StoreAddressesPage> createState() => _StoreAddressesPageState();
}

class _StoreAddressesPageState extends State<StoreAddressesPage> {
  final _repository = sl<DeliveryAddressRepository>();
  List<CustomerAddress>? _addresses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final addresses = await _repository.list();
    if (mounted) setState(() => _addresses = addresses);
  }

  Future<void> _create(CustomerAddress address) async {
    await _repository.create(address);
    await _load();
  }

  Future<void> _update(CustomerAddress address) async {
    await _repository.update(address);
    await _load();
  }

  /// Copia os valores do endereço residencial pra um endereço de entrega
  /// NOVO e independente — pré-preenche o formulário, mas quem confirma é o
  /// próprio usuário (pode ajustar apelido/complemento antes de salvar), e o
  /// resultado nunca fica vinculado ao residencial depois de criado.
  Future<void> _useResidential() async {
    final result = await sl<ProfileRepository>().getAddress();
    final residential = result is Success<UserAddress?> ? result.data : null;
    if (residential == null || residential.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.addressLoadError)));
      return;
    }
    final prefill = CustomerAddress(
      id: '',
      zipCode: residential.zipCode ?? '',
      street: residential.street ?? '',
      number: residential.number ?? '',
      complement: residential.complement,
      neighborhood: residential.neighborhood ?? '',
      city: residential.city ?? '',
      state: residential.state ?? '',
    );
    if (!mounted) return;
    await showStoreAddressFormSheet(context, prefill: prefill, onSave: _create);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final addresses = _addresses;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          BackButtonCircle(onTap: () => context.pop()),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            l10n.storeAddressesTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(left: 52),
                        child: Text(
                          l10n.storeAddressesSubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: addresses == null
                      ? const Center(child: GoiasLoadingIndicator())
                      : addresses.isEmpty
                      ? Center(
                          child: StateMessage(
                            icon: Icons.location_on_outlined,
                            title: l10n.storeAddressesEmptyTitle,
                            message: l10n.storeAddressesEmptyMessage,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          children: [
                            for (final address in addresses)
                              _AddressTile(
                                address: address,
                                onSetDefault: () async {
                                  await _repository.setDefault(address.id);
                                  await _load();
                                },
                                onEdit: () => showStoreAddressFormSheet(
                                  context,
                                  initial: address,
                                  onSave: _update,
                                ),
                                onDelete: () async {
                                  final confirmed = await AppBottomSheet.show(
                                    context,
                                    title: l10n.storeRemoveAddressTitle,
                                    description: l10n.storeRemoveAddressMessage(
                                      address.oneLine,
                                    ),
                                    confirmLabel: l10n.storeRemove,
                                    cancelLabel: l10n.commonCancel,
                                    destructive: true,
                                  );
                                  if (confirmed == true) {
                                    await _repository.delete(address.id);
                                    await _load();
                                  }
                                },
                              ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            showStoreAddressFormSheet(context, onSave: _create),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.storeAddAddress),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: colors.primary,
                          side: BorderSide(color: colors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _useResidential,
                        child: Text(l10n.storeUseResidentialAddress),
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

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  final CustomerAddress address;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
        border: Border.all(
          color: address.isDefault ? colors.primary : colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address.label?.isNotEmpty == true
                            ? address.label!
                            : l10n.storeDeliveryAddressLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (address.isDefault)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Text(
                          l10n.storeDefaultBadge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address.oneLine,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                Text(
                  l10n.storeZipCodePrefix(address.zipCode),
                  style: TextStyle(fontSize: 11.5, color: colors.textHint),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (!address.isDefault)
                      TextButton(
                        onPressed: onSetDefault,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text(l10n.storeMakeDefault),
                      ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: l10n.storeEdit,
                      child: IconButton(
                        onPressed: onEdit,
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 19,
                          color: colors.textHint,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: l10n.storeRemoveAddressTitle,
                      child: IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: colors.textHint,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
