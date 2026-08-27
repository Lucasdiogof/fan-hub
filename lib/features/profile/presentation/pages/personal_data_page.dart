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
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

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
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.form.maxWidth),
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
                      PageTitle(context.l10n.personalDataTitle),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<ProfileCubit, ProfileState>(
                    buildWhen: (previous, current) =>
                        previous.status != current.status ||
                        previous.profile != current.profile,
                    builder: (context, state) {
                      if (state.status == LoadStatus.error) {
                        return Center(
                          child: StateMessage(
                            icon: Icons.error_outline_rounded,
                            title: context.l10n.personalDataLoadError,
                            message: state.errorMessage,
                          ),
                        );
                      }
                      final profile = state.profile;
                      if (profile == null) {
                        return const Center(child: GoiasLoadingIndicator());
                      }
                      return _PersonalDataForm(profile: profile);
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
  late DateTime? _birthDate = widget.profile.birthDate;

  String? _nameError;
  String? _cpfError;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: context.l10n.personalFieldBirthDate,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final nameError = _name.trim().isEmpty
        ? context.l10n.personalNameRequired
        : null;
    final cpfDigits = onlyDigits(_cpf);
    final cpfError = _cpf.isNotEmpty && cpfDigits.length != 11
        ? context.l10n.personalCpfInvalid
        : null;
    setState(() {
      _nameError = nameError;
      _cpfError = cpfError;
    });
    if (nameError != null || cpfError != null) return;

    final phoneDigits = onlyDigits(_phone);
    final failure = await context.read<ProfileCubit>().updatePersonalData(
      fullName: _name.trim(),
      cpf: cpfDigits.isEmpty ? null : cpfDigits,
      birthDate: _birthDate,
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
    final birthLabel = _birthDate == null
        ? ''
        : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        RegistrationTextField(
          label: context.l10n.authFullNameLabel,
          value: _name,
          errorText: _nameError,
          keyboardType: TextInputType.name,
          onChanged: (value) {
            _name = value;
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.personalFieldCpf,
          value: _cpf,
          errorText: _cpfError,
          keyboardType: TextInputType.number,
          inputFormatters: [cpfInputFormatter()],
          onChanged: (value) {
            _cpf = value;
            if (_cpfError != null) setState(() => _cpfError = null);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationPickerField(
          label: context.l10n.personalFieldBirthDate,
          value: birthLabel,
          placeholder: context.l10n.personalSelectDate,
          onTap: _pickDate,
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: context.l10n.personalFieldPhone,
          value: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [phoneInputFormatter()],
          onChanged: (value) => _phone = value,
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
