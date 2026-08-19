import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_cubit.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/shared/utils/masks.dart';

const _brazilianStates = [
  'Acre', 'Alagoas', 'Amapá', 'Amazonas', 'Bahia', 'Ceará', 'Distrito Federal',
  'Espírito Santo', 'Goiás', 'Maranhão', 'Mato Grosso', 'Mato Grosso do Sul',
  'Minas Gerais', 'Pará', 'Paraíba', 'Paraná', 'Pernambuco', 'Piauí',
  'Rio de Janeiro', 'Rio Grande do Norte', 'Rio Grande do Sul', 'Rondônia',
  'Roraima', 'Santa Catarina', 'São Paulo', 'Sergipe', 'Tocantins',
];

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
              itemCount: _brazilianStates.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
              itemBuilder: (itemContext, index) {
                final state = _brazilianStates[index];
                return ListTile(
                  title: Text(state, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  onTap: () {
                    cubit.updateData((current) => current.copyWith(state: state));
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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MembershipRegistrationCubit>();
    final state = context.watch<MembershipRegistrationCubit>().state;
    final data = state.data;
    final errors = state.addressErrors;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('3 de 3 · Endereço', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.primary)),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'País',
          value: data.addressCountry,
          errorText: errors['addressCountry'],
          onChanged: (value) => cubit.updateData((current) => current.copyWith(addressCountry: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'CEP (opcional)',
          value: data.zipCode,
          keyboardType: TextInputType.number,
          inputFormatters: [cepInputFormatter()],
          onChanged: (value) => cubit.updateData((current) => current.copyWith(zipCode: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Logradouro',
          value: data.street,
          errorText: errors['street'],
          onChanged: (value) => cubit.updateData((current) => current.copyWith(street: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RegistrationTextField(
                label: 'Número',
                value: data.number,
                errorText: errors['number'],
                keyboardType: TextInputType.number,
                onChanged: (value) => cubit.updateData((current) => current.copyWith(number: value)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: RegistrationTextField(
                label: 'Complemento (opcional)',
                value: data.complement,
                onChanged: (value) => cubit.updateData((current) => current.copyWith(complement: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Bairro',
          value: data.neighborhood,
          errorText: errors['neighborhood'],
          onChanged: (value) => cubit.updateData((current) => current.copyWith(neighborhood: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationPickerField(
          label: 'Estado',
          value: data.state,
          placeholder: 'Selecionar estado',
          errorText: errors['state'],
          onTap: () => _pickState(context, cubit),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Cidade',
          value: data.city,
          errorText: errors['city'],
          onChanged: (value) => cubit.updateData((current) => current.copyWith(city: value)),
        ),
      ],
    );
  }
}
