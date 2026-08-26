import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/country_catalog.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_cubit.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/shared/utils/masks.dart';

class PersonalDataStep extends StatelessWidget {
  const PersonalDataStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MembershipRegistrationCubit>();
    final state = context.watch<MembershipRegistrationCubit>().state;
    final data = state.data;
    final errors = state.personalErrors(context.l10n);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.membershipStep2Personal,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.membershipContactEmail,
          isRequired: true,
          value: data.contactEmail,
          errorText: errors['contactEmail'],
          keyboardType: TextInputType.emailAddress,
          onChanged: cubit.updateContactEmail,
          onBlur: () => cubit.markFieldBlurred('contactEmail'),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.authFullNameLabel,
          isRequired: true,
          value: data.fullName,
          errorText: errors['fullName'],
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.updateFullName,
          onBlur: () => cubit.markFieldBlurred('fullName'),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.membershipNickname,
          value: data.nickname,
          textCapitalization: TextCapitalization.words,
          onChanged: cubit.updateNickname,
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.personalFieldBirthDate,
          isRequired: true,
          value: data.birthDate,
          errorText: errors['birthDate'],
          keyboardType: TextInputType.number,
          hintText: context.l10n.membershipBirthdateHint,
          inputFormatters: [birthDateInputFormatter()],
          onChanged: cubit.updateBirthDate,
          onBlur: () => cubit.markFieldBlurred('birthDate'),
        ),
        const SizedBox(height: AppSpacing.lg),
        FieldLabel(context.l10n.membershipGender, isRequired: true),
        const SizedBox(height: 6),
        SegmentedToggle<Gender>(
          value: data.gender,
          options: [
            (Gender.masculino, context.l10n.membershipGenderMale),
            (Gender.feminino, context.l10n.membershipGenderFemale),
          ],
          onChanged: cubit.updateGender,
        ),
        if (errors['gender'] != null) ...[
          const SizedBox(height: 4),
          Text(
            errors['gender']!,
            style: TextStyle(fontSize: 12, color: colors.primary),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.personalFieldPhone,
          isRequired: true,
          value: data.phone,
          errorText: errors['phone'],
          keyboardType: TextInputType.phone,
          hintText: data.phoneCountryCode == 'BR' ? '(00) 00000-0000' : null,
          prefix: _PhoneCountryPrefix(
            isoCode: data.phoneCountryCode,
            onChanged: cubit.updatePhoneCountryCode,
          ),
          inputFormatters: data.phoneCountryCode == 'BR'
              ? [phoneInputFormatter()]
              : null,
          onChanged: cubit.updatePhone,
          onBlur: () => cubit.markFieldBlurred('phone'),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.membershipHomePhone,
          value: data.landline,
          keyboardType: TextInputType.phone,
          inputFormatters: [landlineInputFormatter()],
          onChanged: cubit.updateLandline,
        ),
        const SizedBox(height: AppSpacing.lg),
        _NewsletterCheckbox(
          value: data.wantsNewsletter,
          onChanged: cubit.updateWantsNewsletter,
        ),
      ],
    );
  }
}

/// Prefixo tocável do campo Celular — abre um seletor de país/DDI em vez de
/// fixar o Brasil, já que o titular pode ter um número de outro país.
class _PhoneCountryPrefix extends StatelessWidget {
  const _PhoneCountryPrefix({required this.isoCode, required this.onChanged});

  final String isoCode;
  final ValueChanged<String> onChanged;

  Future<void> _open(BuildContext context) async {
    final colors = context.colors;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.7,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: CountryCatalog.countries.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.border),
              itemBuilder: (itemContext, index) {
                final country = CountryCatalog.countries[index];
                return ListTile(
                  leading: Text(
                    CountryCatalog.flagFor(country.code),
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  trailing: Text(
                    country.dialCode,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    onChanged(country.code);
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
    final colors = context.colors;
    return GestureDetector(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CountryCatalog.flagFor(isoCode),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 6),
            Text(
              CountryCatalog.dialCodeFor(isoCode),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 16, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}

class _NewsletterCheckbox extends StatelessWidget {
  const _NewsletterCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: value ? colors.primary : colors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? colors.primary : colors.border,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(Icons.check_rounded, size: 15, color: colors.onPrimary)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.l10n.membershipNewsletter,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
