import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/features/profile/presentation/cubit/address_cubit.dart';
import 'package:goias_app/features/profile/presentation/cubit/address_state.dart';
import 'package:goias_app/shared/domain/brazilian_states.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

const _brazilianStates = [
  'Acre',
  'Alagoas',
  'Amapá',
  'Amazonas',
  'Bahia',
  'Ceará',
  'Distrito Federal',
  'Espírito Santo',
  'Goiás',
  'Maranhão',
  'Mato Grosso',
  'Mato Grosso do Sul',
  'Minas Gerais',
  'Pará',
  'Paraíba',
  'Paraná',
  'Pernambuco',
  'Piauí',
  'Rio de Janeiro',
  'Rio Grande do Norte',
  'Rio Grande do Sul',
  'Rondônia',
  'Roraima',
  'Santa Catarina',
  'São Paulo',
  'Sergipe',
  'Tocantins',
];

/// [cubit], quando fornecido, já veio construído e carregado por quem
/// navegou pra cá (ver `GlobalLoading.run` em `profile_page.dart`) — a tela
/// só reaproveita via `BlocProvider.value`. Fica `null` (e a tela cria/
/// carrega o próprio Cubit) só em navegação direta por URL.
class AddressPage extends StatelessWidget {
  const AddressPage({this.cubit, super.key});

  final AddressCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final preloaded = cubit;
    if (preloaded != null) {
      return BlocProvider.value(value: preloaded, child: const _AddressView());
    }
    return BlocProvider(
      create: (_) => sl<AddressCubit>()..load(),
      child: const _AddressView(),
    );
  }
}

class _AddressView extends StatelessWidget {
  const _AddressView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                      PageTitle(context.l10n.addressTitle),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<AddressCubit, AddressState>(
                    buildWhen: (previous, current) =>
                        previous.status != current.status,
                    builder: (context, state) {
                      return switch (state.status) {
                        LoadStatus.initial || LoadStatus.loading =>
                          const Center(child: GoiasLoadingIndicator()),
                        LoadStatus.error => Center(
                          child: StateMessage(
                            icon: Icons.error_outline_rounded,
                            title: context.l10n.addressLoadError,
                            message: state.errorMessage,
                          ),
                        ),
                        _ => _AddressForm(
                          address: state.address ?? const UserAddress(),
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

class _AddressForm extends StatefulWidget {
  const _AddressForm({required this.address});

  final UserAddress address;

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  late String _zip = _applyMask(
    cepInputFormatter(),
    widget.address.zipCode ?? '',
  );
  late String _street = widget.address.street ?? '';
  late String _number = widget.address.number ?? '';
  late String _complement = widget.address.complement ?? '';
  late String _neighborhood = widget.address.neighborhood ?? '';
  late String _city = widget.address.city ?? '';
  late String _state = widget.address.state ?? '';

  Timer? _cepDebounce;
  bool _cepLoading = false;

  @override
  void dispose() {
    _cepDebounce?.cancel();
    super.dispose();
  }

  void _onZipChanged(String value) {
    _zip = value;
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
    if (onlyDigits(_zip) != digits) return;

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
          if (data.street.isNotEmpty) _street = data.street;
          if (data.neighborhood.isNotEmpty) _neighborhood = data.neighborhood;
          if (data.city.isNotEmpty) _city = data.city;
          if (data.state.isNotEmpty) {
            _state = BrazilianStates.nameForCode(data.state);
          }
        });
      case Error(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _pickState() async {
    final colors = context.colors;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.7,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _brazilianStates.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.border),
              itemBuilder: (itemContext, index) {
                final state = _brazilianStates[index];
                return ListTile(
                  title: Text(
                    state,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    setState(() => _state = state);
                    Navigator.of(itemContext).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final address = UserAddress(
      zipCode: onlyDigits(_zip).isEmpty ? null : onlyDigits(_zip),
      street: _street.trim().isEmpty ? null : _street.trim(),
      number: _number.trim().isEmpty ? null : _number.trim(),
      complement: _complement.trim().isEmpty ? null : _complement.trim(),
      neighborhood: _neighborhood.trim().isEmpty ? null : _neighborhood.trim(),
      city: _city.trim().isEmpty ? null : _city.trim(),
      state: _state.isEmpty ? null : _state,
    );
    final failure = await context.read<AddressCubit>().save(address);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.addressSaveSuccess)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        RegistrationTextField(
          label: context.l10n.addressFieldCep,
          value: _zip,
          keyboardType: TextInputType.number,
          inputFormatters: [cepInputFormatter()],
          onChanged: _onZipChanged,
          suffixIcon: _cepLoading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.addressFieldStreet,
          value: _street,
          onChanged: (value) => _street = value,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RegistrationTextField(
                label: context.l10n.addressFieldNumber,
                value: _number,
                keyboardType: TextInputType.number,
                onChanged: (value) => _number = value,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: RegistrationTextField(
                label: context.l10n.addressFieldComplement,
                value: _complement,
                onChanged: (value) => _complement = value,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.addressFieldNeighborhood,
          value: _neighborhood,
          onChanged: (value) => _neighborhood = value,
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationPickerField(
          label: context.l10n.addressFieldState,
          value: _state,
          placeholder: context.l10n.addressSelectState,
          onTap: _pickState,
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.addressFieldCity,
          value: _city,
          onChanged: (value) => _city = value,
        ),
        const SizedBox(height: AppSpacing.xxl),
        BlocBuilder<AddressCubit, AddressState>(
          buildWhen: (previous, current) => previous.saving != current.saving,
          builder: (context, state) {
            return AppPrimaryButton(
              label: context.l10n.addressSaveButton,
              loading: state.saving,
              loadingLabel: context.l10n.commonSaving,
              onPressed: _save,
            );
          },
        ),
      ],
    );
  }
}

String _applyMask(TextInputFormatter formatter, String raw) {
  if (raw.isEmpty) return '';
  return formatter
      .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: raw))
      .text;
}
