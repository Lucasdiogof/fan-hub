import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';

/// Formulário de endereço da Store — próprio, separado do endereço de
/// perfil usado pelo módulo de Ingressos (`AddressCubit`); a Store tem seu
/// catálogo de endereços independente (ver `StoreRepository`).
Future<void> showStoreAddressFormSheet(
  BuildContext context, {
  required Future<void> Function(CustomerAddress) onSave,
  CustomerAddress? initial,
}) {
  return AppModalSheet.show<void>(
    context,
    dialogMaxWidth: 480,
    builder: (_) => _StoreAddressForm(onSave: onSave, initial: initial),
  );
}

class _StoreAddressForm extends StatefulWidget {
  const _StoreAddressForm({required this.onSave, this.initial});

  final Future<void> Function(CustomerAddress) onSave;
  final CustomerAddress? initial;

  @override
  State<_StoreAddressForm> createState() => _StoreAddressFormState();
}

class _StoreAddressFormState extends State<_StoreAddressForm> {
  late final _zipController = TextEditingController(
    text: widget.initial?.zipCode ?? '',
  );
  late final _streetController = TextEditingController(
    text: widget.initial?.street ?? '',
  );
  late final _numberController = TextEditingController(
    text: widget.initial?.number ?? '',
  );
  late final _complementController = TextEditingController(
    text: widget.initial?.complement ?? '',
  );
  late final _neighborhoodController = TextEditingController(
    text: widget.initial?.neighborhood ?? '',
  );
  late final _cityController = TextEditingController(
    text: widget.initial?.city ?? '',
  );
  late final _stateController = TextEditingController(
    text: widget.initial?.state ?? '',
  );

  bool _saving = false;
  bool _hasError = false;

  @override
  void dispose() {
    _zipController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (onlyDigits(_zipController.text).length != 8 ||
        _streetController.text.trim().isEmpty ||
        _numberController.text.trim().isEmpty ||
        _neighborhoodController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().length != 2) {
      setState(() => _hasError = true);
      return;
    }
    setState(() {
      _saving = true;
      _hasError = false;
    });
    await widget.onSave(
      CustomerAddress(
        id:
            widget.initial?.id ??
            'addr_${DateTime.now().microsecondsSinceEpoch}',
        zipCode: _zipController.text,
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        complement: _complementController.text.trim().isEmpty
            ? null
            : _complementController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
        isDefault: widget.initial?.isDefault ?? false,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  widget.initial == null
                      ? l10n.storeNewAddressTitle
                      : l10n.storeEditAddressTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _zipController,
                keyboardType: TextInputType.number,
                inputFormatters: [cepInputFormatter()],
                decoration: _decoration(context, l10n.storeZipCodeLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _streetController,
                decoration: _decoration(context, l10n.storeStreetLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(context, l10n.storeNumberLabel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _complementController,
                      decoration: _decoration(
                        context,
                        l10n.storeComplementLabel,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _neighborhoodController,
                decoration: _decoration(context, l10n.storeNeighborhoodLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _cityController,
                      decoration: _decoration(context, l10n.storeCityLabel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _stateController,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _decoration(
                        context,
                        l10n.storeStateLabel,
                      ).copyWith(counterText: ''),
                    ),
                  ),
                ],
              ),
              if (_hasError) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.storeAddressFormError,
                  style: TextStyle(fontSize: 12, color: colors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: l10n.storeSaveAddressButton,
                loading: _saving,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, String label) {
    final colors = context.colors;
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: colors.secondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide.none,
      ),
    );
  }
}
