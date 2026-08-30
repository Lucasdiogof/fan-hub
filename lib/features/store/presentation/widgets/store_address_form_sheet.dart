import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/validation/app_validators.dart';
import 'package:goias_app/shared/validation/field_touch.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';

/// Formulário de endereço de ENTREGA da Store — separado do endereço
/// residencial (`AddressCubit`/`ProfileRepository`), que é único por conta.
/// [initial] edita um endereço já salvo (mantém o id, o botão diz "Editar").
/// [prefill] só semeia os campos (ex.: copiando o endereço residencial) —
/// sempre um registro NOVO e independente, nunca uma referência ao que o
/// preencheu (o botão diz "Novo endereço" e o `onSave` deve criar, nunca
/// atualizar).
Future<void> showStoreAddressFormSheet(
  BuildContext context, {
  required Future<void> Function(CustomerAddress) onSave,
  CustomerAddress? initial,
  CustomerAddress? prefill,
}) {
  return AppModalSheet.show<void>(
    context,
    dialogMaxWidth: 480,
    builder: (_) =>
        _StoreAddressForm(onSave: onSave, initial: initial, prefill: prefill),
  );
}

class _StoreAddressForm extends StatefulWidget {
  const _StoreAddressForm({required this.onSave, this.initial, this.prefill});

  final Future<void> Function(CustomerAddress) onSave;
  final CustomerAddress? initial;
  final CustomerAddress? prefill;

  @override
  State<_StoreAddressForm> createState() => _StoreAddressFormState();
}

class _StoreAddressFormState extends State<_StoreAddressForm> {
  CustomerAddress? get _seed => widget.initial ?? widget.prefill;

  late final _labelController = TextEditingController(
    text: widget.initial?.label ?? '',
  );
  late final _zipController = TextEditingController(text: _seed?.zipCode ?? '');
  late final _streetController = TextEditingController(
    text: _seed?.street ?? '',
  );
  late final _numberController = TextEditingController(
    text: _seed?.number ?? '',
  );
  late final _complementController = TextEditingController(
    text: _seed?.complement ?? '',
  );
  late final _neighborhoodController = TextEditingController(
    text: _seed?.neighborhood ?? '',
  );
  late final _cityController = TextEditingController(text: _seed?.city ?? '');
  late final _stateController = TextEditingController(
    text: _seed?.state ?? '',
  );

  bool _saving = false;
  bool _submitted = false;

  final _zipTouch = FieldTouch();
  final _streetTouch = FieldTouch();
  final _numberTouch = FieldTouch();
  final _neighborhoodTouch = FieldTouch();
  final _cityTouch = FieldTouch();
  final _stateTouch = FieldTouch();

  @override
  void dispose() {
    _labelController.dispose();
    _zipController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      AppValidators.isValidZipCode(_zipController.text) &&
      _streetController.text.trim().isNotEmpty &&
      _numberController.text.trim().isNotEmpty &&
      _neighborhoodController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _stateController.text.trim().length == 2;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_isValid) return;
    setState(() => _saving = true);
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
        label: _labelController.text.trim().isEmpty
            ? null
            : _labelController.text.trim(),
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
                controller: _labelController,
                decoration: _decoration(
                  context,
                  l10n.storeAddressLabelField,
                ).copyWith(hintText: l10n.storeAddressLabelHint),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _zipController,
                keyboardType: TextInputType.number,
                inputFormatters: [cepInputFormatter()],
                onChanged: (v) {
                  _zipTouch.touched = true;
                  setState(() {});
                },
                decoration: _decoration(
                  context,
                  l10n.storeZipCodeLabel,
                  errorText: _zipTouch.errorFor(
                    _zipController.text,
                    submitted: _submitted,
                    format: (v) => AppValidators.isValidZipCode(v)
                        ? null
                        : l10n.storeValZipInvalid,
                    requiredMessage: l10n.validatorZipRequired,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _streetController,
                onChanged: (v) {
                  _streetTouch.touched = true;
                  setState(() {});
                },
                decoration: _decoration(
                  context,
                  l10n.storeStreetLabel,
                  errorText: _streetTouch.errorFor(
                    _streetController.text,
                    submitted: _submitted,
                    requiredMessage: l10n.membershipValStreet,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _numberController,
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _numberTouch.touched = true;
                        setState(() {});
                      },
                      decoration: _decoration(
                        context,
                        l10n.storeNumberLabel,
                        errorText: _numberTouch.errorFor(
                          _numberController.text,
                          submitted: _submitted,
                          requiredMessage: l10n.membershipValNumber,
                        ),
                      ),
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
                onChanged: (v) {
                  _neighborhoodTouch.touched = true;
                  setState(() {});
                },
                decoration: _decoration(
                  context,
                  l10n.storeNeighborhoodLabel,
                  errorText: _neighborhoodTouch.errorFor(
                    _neighborhoodController.text,
                    submitted: _submitted,
                    requiredMessage: l10n.membershipValNeighborhood,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _cityController,
                      onChanged: (v) {
                        _cityTouch.touched = true;
                        setState(() {});
                      },
                      decoration: _decoration(
                        context,
                        l10n.storeCityLabel,
                        errorText: _cityTouch.errorFor(
                          _cityController.text,
                          submitted: _submitted,
                          requiredMessage: l10n.membershipValCity,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _stateController,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (v) {
                        _stateTouch.touched = true;
                        setState(() {});
                      },
                      decoration: _decoration(
                        context,
                        l10n.storeStateLabel,
                        errorText: _stateTouch.errorFor(
                          _stateController.text,
                          submitted: _submitted,
                          format: (v) => v.trim().length == 2
                              ? null
                              : l10n.membershipValState,
                          requiredMessage: l10n.membershipValState,
                        ),
                      ).copyWith(counterText: ''),
                    ),
                  ),
                ],
              ),
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

  InputDecoration _decoration(
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
}
