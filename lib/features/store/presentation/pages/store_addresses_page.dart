import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/features/store/presentation/widgets/store_address_form_sheet.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class StoreAddressesPage extends StatefulWidget {
  const StoreAddressesPage({super.key});

  @override
  State<StoreAddressesPage> createState() => _StoreAddressesPageState();
}

class _StoreAddressesPageState extends State<StoreAddressesPage> {
  final _repository = sl<StoreRepository>();
  List<CustomerAddress>? _addresses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final addresses = await _repository.loadAddresses();
    if (mounted) setState(() => _addresses = addresses);
  }

  Future<void> _save(List<CustomerAddress> updated) async {
    await _repository.saveAddresses(updated);
    if (mounted) setState(() => _addresses = updated);
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
                  child: Row(
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
                                onSetDefault: () => _save([
                                  for (final a in addresses)
                                    a.copyWith(isDefault: a.id == address.id),
                                ]),
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
                                    await _save(
                                      addresses
                                          .where((a) => a.id != address.id)
                                          .toList(),
                                    );
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
                  child: OutlinedButton.icon(
                    onPressed: () => showStoreAddressFormSheet(
                      context,
                      onSave: (address) =>
                          _save([...(addresses ?? []), address]),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.storeAddAddress),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
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
    required this.onDelete,
  });

  final CustomerAddress address;
  final VoidCallback onSetDefault;
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
                if (address.isDefault)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      l10n.storeDefaultBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                  ),
                Text(
                  address.oneLine,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
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
