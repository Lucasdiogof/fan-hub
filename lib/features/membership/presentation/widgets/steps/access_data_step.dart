import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/country_catalog.dart';
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
    final errors = state.accessErrors(context.l10n);
    final isForeign = data.nationality != 'BR';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.membershipStep1Access,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.membershipCpf,
          isRequired: true,
          value: data.cpf,
          errorText: errors['cpf'],
          keyboardType: TextInputType.number,
          hintText: '000.000.000-00',
          inputFormatters: [cpfInputFormatter()],
          onChanged: cubit.updateCpf,
          onBlur: () => cubit.markFieldBlurred('cpf'),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationDropdownField<String>(
          label: context.l10n.membershipNationality,
          isRequired: true,
          value: data.nationality.isEmpty ? null : data.nationality,
          errorText: errors['nationality'],
          options: [
            for (final country in CountryCatalog.countries)
              RegistrationOption(value: country.code, label: country.name),
          ],
          onChanged: cubit.updateNationality,
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: isForeign ? context.l10n.membershipPassport : context.l10n.membershipPassportOptional,
          value: data.passport,
          errorText: errors['passport'],
          hintText: 'AB123456',
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [passportInputFormatter()],
          onChanged: cubit.updatePassport,
          onBlur: () => cubit.markFieldBlurred('passport'),
        ),
      ],
    );
  }
}
