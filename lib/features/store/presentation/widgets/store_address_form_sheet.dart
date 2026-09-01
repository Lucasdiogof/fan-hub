import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/shared/domain/brazilian_states.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/validation/app_validators.dart';
import 'package:goias_app/shared/validation/field_touch.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';
import 'package:goias_app/shared/widgets/app_option_picker.dart';
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
  late final _stateController = TextEditingController(text: _seed?.state ?? '');

  bool _saving = false;
  bool _submitted = false;

  Timer? _cepDebounce;
  bool _cepLoading = false;

  List<String> _availableCities = const [];
  bool _citiesLoading = false;

  final _zipTouch = FieldTouch();
  final _streetTouch = FieldTouch();
  final _numberTouch = FieldTouch();
  final _neighborhoodTouch = FieldTouch();

  @override
  void initState() {
    super.initState();
    // Editando (ou pré-preenchendo a partir do residencial) um endereço que
    // já tem Estado — carrega a lista de cidades de uma vez, pra abrir o
    // seletor de Cidade já pronto sem precisar trocar de Estado primeiro.
    final state = _stateController.text;
    if (state.isNotEmpty) unawaited(_loadCities(state));
  }

  @override
  void dispose() {
    _cepDebounce?.cancel();
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

  void _onZipChanged(String value) {
    _zipTouch.touched = true;
    setState(() {});
    _cepDebounce?.cancel();

    final digits = onlyDigits(value);
    if (digits.length != 8) return;

    _cepDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _lookupZip(digits),
    );
  }

  Future<void> _lookupZip(String digits) async {
    setState(() => _cepLoading = true);
    final result = await sl<AddressRepository>().findByZipCode(digits);
    if (!mounted) return;
    // O usuário pode ter mudado o CEP enquanto a consulta rodava.
    if (onlyDigits(_zipController.text) != digits) return;

    setState(() => _cepLoading = false);
    switch (result) {
      case Success(:final data):
        if (data == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.addressCepNotFound)),
          );
          return;
        }
        setState(() {
          if (data.street.isNotEmpty) _streetController.text = data.street;
          if (data.neighborhood.isNotEmpty) {
            _neighborhoodController.text = data.neighborhood;
          }
          if (data.city.isNotEmpty) _cityController.text = data.city;
          if (data.state.isNotEmpty) {
            _stateController.text = BrazilianStates.nameForCode(data.state);
          }
        });
        if (data.state.isNotEmpty) {
          unawaited(_loadCities(_stateController.text));
        }
      case Error(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _loadCities(String stateName) async {
    setState(() {
      _citiesLoading = true;
      _availableCities = const [];
    });
    final code = BrazilianStates.codeForName(stateName) ?? stateName;
    final result = await sl<AddressRepository>().getCitiesByState(code);
    if (!mounted || _stateController.text != stateName) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _availableCities = data;
          _citiesLoading = false;
        });
      case Error():
        setState(() => _citiesLoading = false);
    }
  }

  Future<void> _pickState() async {
    final current = _stateController.text;
    final picked = await AppOptionPicker.show<String>(
      context,
      selected: current.isEmpty ? null : current,
      options: [
        for (final state in BrazilianStates.states)
          AppPickerOption(value: state.name, label: state.name),
      ],
    );
    if (picked == null || picked == current) return;
    // Trocar de Estado manualmente limpa a Cidade — uma cidade do Estado
    // anterior não faz mais sentido — e busca os municípios da nova UF.
    setState(() {
      _stateController.text = picked;
      _cityController.text = '';
    });
    unawaited(_loadCities(picked));
  }

  Future<void> _pickCity() async {
    final current = _cityController.text;
    final picked = await AppOptionPicker.show<String>(
      context,
      selected: current.isEmpty ? null : current,
      options: [
        for (final city in _availableCities)
          AppPickerOption(value: city, label: city),
      ],
    );
    if (picked != null) setState(() => _cityController.text = picked);
  }

  bool get _isValid =>
      AppValidators.isValidZipCode(_zipController.text) &&
      _streetController.text.trim().isNotEmpty &&
      _numberController.text.trim().isNotEmpty &&
      _neighborhoodController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _stateController.text.trim().isNotEmpty;

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
        state: _stateController.text.trim(),
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
                onChanged: _onZipChanged,
                decoration:
                    _decoration(
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
                    ).copyWith(
                      suffixIcon: _cepLoading
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
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
                    child: TextField(
                      controller: _stateController,
                      readOnly: true,
                      onTap: _pickState,
                      decoration: _decoration(
                        context,
                        l10n.storeStateLabel,
                        errorText: _submitted && _stateController.text.isEmpty
                            ? l10n.membershipValState
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _cityController,
                      readOnly: true,
                      onTap: _stateController.text.isEmpty || _citiesLoading
                          ? null
                          : _pickCity,
                      decoration: _decoration(
                        context,
                        l10n.storeCityLabel,
                        errorText: _submitted && _cityController.text.isEmpty
                            ? l10n.membershipValCity
                            : null,
                      ).copyWith(
                        hintText: _citiesLoading
                            ? l10n.membershipLoadingCities
                            : (_stateController.text.isEmpty
                                  ? l10n.membershipSelectStateFirst
                                  : l10n.membershipSelectCity),
                      ),
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
