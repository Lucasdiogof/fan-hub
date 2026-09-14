import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/validation/app_validators.dart';
import 'package:goias_app/shared/validation/field_touch.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class PersonalDataPage extends StatelessWidget {
  const PersonalDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<ProfileCubit>(),
      child: const _PersonalDataView(),
    );
  }
}

class _PersonalDataView extends StatelessWidget {
  const _PersonalDataView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final title = context.l10n.personalDataTitle;
    return Scaffold(
      backgroundColor: colors.background,
      body: DetailPageHeader(
        maxWidth: ContentWidth.form,
        title: title,
        heroTitle: Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: BlocBuilder<ProfileCubit, ProfileState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.profile != current.profile,
            builder: (context, state) {
              if (state.status == LoadStatus.error) {
                return SizedBox(
                  height: 320,
                  child: Center(
                    child: StateMessage(
                      icon: Icons.error_outline_rounded,
                      title: context.l10n.personalDataLoadError,
                      message: state.errorMessage,
                    ),
                  ),
                );
              }
              final profile = state.profile;
              if (profile == null) {
                return const SizedBox(
                  height: 320,
                  child: Center(child: GoiasLoadingIndicator()),
                );
              }
              return _PersonalDataForm(profile: profile);
            },
          ),
        ),
      ),
    );
  }
}

class _PersonalDataForm extends StatefulWidget {
  const _PersonalDataForm({required this.profile});

  final Profile profile;

  @override
  State<_PersonalDataForm> createState() => _PersonalDataFormState();
}

class _PersonalDataFormState extends State<_PersonalDataForm> {
  late String _name = widget.profile.fullName ?? '';
  late String _cpf = _applyMask(cpfInputFormatter(), widget.profile.cpf ?? '');
  late String _phone = _applyMask(
    phoneInputFormatter(),
    widget.profile.phone ?? '',
  );
  late String _birthDate = _formatBirthDate(widget.profile.birthDate);

  final _nameTouch = FieldTouch();
  final _cpfTouch = FieldTouch();
  final _birthTouch = FieldTouch();
  final _phoneTouch = FieldTouch();
  bool _submitted = false;

  bool get _isDirty =>
      _name != (widget.profile.fullName ?? '') ||
      _cpf != _applyMask(cpfInputFormatter(), widget.profile.cpf ?? '') ||
      _phone != _applyMask(phoneInputFormatter(), widget.profile.phone ?? '') ||
      _birthDate != _formatBirthDate(widget.profile.birthDate);

  // CPF deixou de ser opcional (regra de negócio nova) — nome e CPF sempre
  // exigidos; data de nascimento/celular continuam opcionais (só validam
  // formato quando preenchidos).
  bool get _isValid =>
      _name.trim().isNotEmpty &&
      AppValidators.isValidCpf(onlyDigits(_cpf)) &&
      (_birthDate.isEmpty ||
          AppValidators.birthDate(context.l10n, _birthDate) == null) &&
      (_phone.isEmpty || AppValidators.isValidMobilePhone(_phone));

  bool get _canSubmit => _isDirty && _isValid;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!_isValid) return;

    final cpfDigits = onlyDigits(_cpf);
    final phoneDigits = onlyDigits(_phone);
    final failure = await context.read<ProfileCubit>().updatePersonalData(
      fullName: _name.trim(),
      cpf: cpfDigits.isEmpty ? null : cpfDigits,
      birthDate: _birthDate.isEmpty
          ? null
          : AppValidators.parseBirthDate(_birthDate),
      phone: phoneDigits.isEmpty ? null : phoneDigits,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.personalUpdateSuccess)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationTextField(
          label: context.l10n.authFullNameLabel,
          value: _name,
          errorText: _nameTouch.errorFor(
            _name,
            submitted: _submitted,
            requiredMessage: context.l10n.personalNameRequired,
          ),
          keyboardType: TextInputType.name,
          onChanged: (value) {
            _nameTouch.touched = true;
            setState(() => _name = value);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.personalFieldCpf,
          value: _cpf,
          errorText: _cpfTouch.errorFor(
            _cpf,
            submitted: _submitted,
            requiredMessage: context.l10n.personalCpfRequired,
            format: (v) => AppValidators.isValidCpf(onlyDigits(v))
                ? null
                : context.l10n.personalCpfInvalid,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [cpfInputFormatter()],
          onChanged: (value) {
            _cpfTouch.touched = true;
            setState(() => _cpf = value);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.personalFieldBirthDate,
          value: _birthDate,
          hintText: context.l10n.authBirthDateHint,
          errorText: _birthTouch.errorFor(
            _birthDate,
            submitted: _submitted,
            format: (v) => AppValidators.birthDate(context.l10n, v),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [birthDateInputFormatter()],
          onChanged: (value) {
            _birthTouch.touched = true;
            setState(() => _birthDate = value);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.personalFieldPhone,
          value: _phone,
          errorText: _phoneTouch.errorFor(
            _phone,
            submitted: _submitted,
            format: (v) => AppValidators.isValidMobilePhone(v)
                ? null
                : context.l10n.storeValPhoneInvalid,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [phoneInputFormatter()],
          onChanged: (value) {
            _phoneTouch.touched = true;
            setState(() => _phone = value);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.commonEmailLabel,
          value: widget.profile.email,
          readOnly: true,
          onChanged: (_) {},
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.personalEmailLocked,
          style: TextStyle(fontSize: 12, color: colors.textHint),
        ),
        const SizedBox(height: AppSpacing.xxl),
        BlocBuilder<ProfileCubit, ProfileState>(
          buildWhen: (previous, current) => previous.saving != current.saving,
          builder: (context, state) {
            return AppPrimaryButton(
              label: context.l10n.commonSave,
              loading: state.saving,
              loadingLabel: context.l10n.commonSaving,
              onPressed: _canSubmit ? _save : null,
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

String _formatBirthDate(DateTime? date) {
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
