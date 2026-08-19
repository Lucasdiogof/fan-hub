import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_cubit.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/shared/utils/masks.dart';

class AccessDataStep extends StatelessWidget {
  const AccessDataStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MembershipRegistrationCubit>();
    final state = context.watch<MembershipRegistrationCubit>().state;
    final data = state.data;
    final errors = state.accessErrors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1 de 3 · Dados de acesso',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.colors.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        SegmentedToggle<DocumentType>(
          value: data.documentType,
          options: const [(DocumentType.cpf, 'CPF'), (DocumentType.passport, 'Passaporte')],
          onChanged: (type) => cubit.updateData((current) => current.copyWith(documentType: type)),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (data.documentType == DocumentType.cpf)
          RegistrationTextField(
            label: 'CPF',
            value: data.cpf,
            errorText: errors['cpf'],
            keyboardType: TextInputType.number,
            inputFormatters: [cpfInputFormatter()],
            onChanged: (value) => cubit.updateData((current) => current.copyWith(cpf: value)),
          )
        else
          RegistrationTextField(
            label: 'Passaporte',
            value: data.passport,
            errorText: errors['passport'],
            onChanged: (value) => cubit.updateData((current) => current.copyWith(passport: value)),
          ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Nacionalidade',
          value: data.nationality,
          errorText: errors['nationality'],
          onChanged: (value) => cubit.updateData((current) => current.copyWith(nationality: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'País',
          value: data.country,
          errorText: errors['country'],
          onChanged: (value) => cubit.updateData((current) => current.copyWith(country: value)),
        ),
      ],
    );
  }
}
