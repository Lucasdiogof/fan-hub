import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_cubit.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/shared/utils/masks.dart';

class PersonalDataStep extends StatelessWidget {
  const PersonalDataStep({super.key});

  Future<void> _pickBirthDate(BuildContext context, MembershipRegistrationCubit cubit, DateTime? current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 110),
      lastDate: now,
      helpText: 'DATA DE NASCIMENTO',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
    );
    if (picked != null) {
      cubit.updateData((data) => data.copyWith(birthDate: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MembershipRegistrationCubit>();
    final state = context.watch<MembershipRegistrationCubit>().state;
    final data = state.data;
    final errors = state.personalErrors;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('2 de 3 · Dados cadastrais', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.primary)),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'E-mail de contato',
          value: data.contactEmail,
          errorText: errors['contactEmail'],
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => cubit.updateData((current) => current.copyWith(contactEmail: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Nome completo',
          value: data.fullName,
          errorText: errors['fullName'],
          onChanged: (value) => cubit.updateData((current) => current.copyWith(fullName: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Apelido (opcional)',
          value: data.nickname,
          onChanged: (value) => cubit.updateData((current) => current.copyWith(nickname: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationPickerField(
          label: 'Data de nascimento',
          value: data.birthDate == null ? '' : _formatDate(data.birthDate!),
          placeholder: 'Selecionar data',
          errorText: errors['birthDate'],
          onTap: () => _pickBirthDate(context, cubit, data.birthDate),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Sexo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textSecondary)),
        const SizedBox(height: 6),
        SegmentedToggle<Gender>(
          value: data.gender,
          options: const [(Gender.masculino, 'Masculino'), (Gender.feminino, 'Feminino')],
          onChanged: (gender) => cubit.updateData((current) => current.copyWith(gender: gender)),
        ),
        if (errors['gender'] != null) ...[
          const SizedBox(height: 4),
          Text(errors['gender']!, style: TextStyle(fontSize: 12, color: colors.error)),
        ],
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Celular',
          value: data.phone,
          errorText: errors['phone'],
          keyboardType: TextInputType.phone,
          prefixText: '🇧🇷 +55  ',
          inputFormatters: [phoneInputFormatter()],
          onChanged: (value) => cubit.updateData((current) => current.copyWith(phone: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Telefone residencial (opcional)',
          value: data.landline,
          keyboardType: TextInputType.phone,
          inputFormatters: [landlineInputFormatter()],
          onChanged: (value) => cubit.updateData((current) => current.copyWith(landline: value)),
        ),
        const SizedBox(height: AppSpacing.lg),
        _NewsletterCheckbox(
          value: data.wantsNewsletter,
          onChanged: (value) => cubit.updateData((current) => current.copyWith(wantsNewsletter: value)),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
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
              border: Border.all(color: value ? colors.primary : colors.border, width: 1.5),
            ),
            child: value ? Icon(Icons.check_rounded, size: 15, color: colors.onPrimary) : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Desejo receber notícias do clube e do Sócio Esmeralda por e-mail.',
              style: TextStyle(fontSize: 13, height: 1.4, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
