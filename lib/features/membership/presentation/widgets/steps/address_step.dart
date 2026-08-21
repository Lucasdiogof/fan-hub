import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/brazilian_states.dart';
import 'package:goias_app/features/membership/domain/country_catalog.dart';
import 'package:goias_app/features/membership/domain/entities/address_lookup_result.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_cubit.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/masks.dart';

class AddressStep extends StatelessWidget {
  const AddressStep({super.key});

  Future<void> _pickState(BuildContext context, MembershipRegistrationCubit cubit) {
    final colors = context.colors;
    return showModalBottomSheet<void>(
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
              itemCount: BrazilianStates.states.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
              itemBuilder: (itemContext, index) {
                final state = BrazilianStates.states[index];
                return ListTile(
                  title: Text(state.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  onTap: () {
                    cubit.selectState(state.name);
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

  Future<void> _pickCity(BuildContext context, MembershipRegistrationCubit cubit, List<String> cities) {
    final colors = context.colors;
    return showModalBottomSheet<void>(
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
              itemCount: cities.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
              itemBuilder: (itemContext, index) {
                final city = cities[index];
                return ListTile(
                  title: Text(city, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  onTap: () {
                    cubit.updateCity(city);
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

  Future<void> _findZipCode(BuildContext context, MembershipRegistrationCubit cubit) async {
    final result = await context.push<AddressLookupResult>('/membership/find-zip-code');
    if (result != null) cubit.applyAddressLookupResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MembershipRegistrationCubit>();
    final state = context.watch<MembershipRegistrationCubit>().state;
    final data = state.data;
    final errors = state.addressErrors;
    final colors = context.colors;
    final isBrazil = data.addressCountry == 'BR';
    final citiesLoading = state.citiesLoadStatus == LoadStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('3 de 3 · Endereço', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.primary)),
        const SizedBox(height: AppSpacing.lg),
        RegistrationDropdownField<String>(
          label: 'País',
          isRequired: true,
          value: data.addressCountry.isEmpty ? null : data.addressCountry,
          errorText: errors['addressCountry'],
          options: [for (final country in CountryCatalog.countries) RegistrationOption(value: country.code, label: country.name)],
          onChanged: cubit.updateAddressCountry,
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: isBrazil ? 'CEP' : 'Código postal',
          isRequired: isBrazil,
          value: data.zipCode,
          errorText: errors['zipCode'],
          keyboardType: TextInputType.number,
          hintText: isBrazil ? '00000-000' : null,
          inputFormatters: isBrazil ? [cepInputFormatter()] : null,
          suffixIcon: state.cepLookupStatus == LoadStatus.loading
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                  ),
                )
              : (state.cepLookupStatus == LoadStatus.success
                    ? Icon(Icons.check_circle_rounded, color: colors.primary, size: 20)
                    : null),
          onChanged: cubit.updateZipCode,
        ),
        if (isBrazil) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => _findZipCode(context, cubit),
            child: Text(
              'Não sei meu CEP',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.primary),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Logradouro',
          isRequired: true,
          value: data.street,
          errorText: errors['street'],
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.updateStreet,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RegistrationTextField(
                label: 'Número',
                isRequired: true,
                value: data.number,
                errorText: errors['number'],
                keyboardType: TextInputType.number,
                onChanged: cubit.updateNumber,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: RegistrationTextField(
                label: 'Complemento (opcional)',
                value: data.complement,
                onChanged: cubit.updateComplement,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Bairro',
          isRequired: true,
          value: data.neighborhood,
          errorText: errors['neighborhood'],
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.updateNeighborhood,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isBrazil)
          RegistrationPickerField(
            label: 'Estado',
            isRequired: true,
            value: data.state,
            placeholder: 'Selecionar estado',
            errorText: errors['state'],
            onTap: () => _pickState(context, cubit),
          )
        else
          RegistrationTextField(
            label: 'Estado',
            isRequired: true,
            value: data.state,
            errorText: errors['state'],
            onChanged: cubit.updateState,
          ),
        const SizedBox(height: AppSpacing.lg),
        if (isBrazil)
          RegistrationPickerField(
            label: 'Cidade',
            isRequired: true,
            value: data.city,
            placeholder: citiesLoading
                ? 'Carregando cidades...'
                : (data.state.isEmpty ? 'Selecione o estado primeiro' : 'Selecionar cidade'),
            errorText: errors['city'],
            onTap: data.state.isEmpty || citiesLoading
                ? () {}
                : () => _pickCity(context, cubit, state.availableCities),
          )
        else
          RegistrationTextField(
            label: 'Cidade',
            isRequired: true,
            value: data.city,
            errorText: errors['city'],
            textCapitalization: TextCapitalization.words,
            onChanged: cubit.updateCity,
          ),
      ],
    );
  }
}
