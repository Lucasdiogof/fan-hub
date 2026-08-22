import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/features/profile/presentation/cubit/address_cubit.dart';
import 'package:goias_app/features/profile/presentation/cubit/address_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

const _brazilianStates = [
  'Acre', 'Alagoas', 'Amapá', 'Amazonas', 'Bahia', 'Ceará', 'Distrito Federal',
  'Espírito Santo', 'Goiás', 'Maranhão', 'Mato Grosso', 'Mato Grosso do Sul',
  'Minas Gerais', 'Pará', 'Paraíba', 'Paraná', 'Pernambuco', 'Piauí',
  'Rio de Janeiro', 'Rio Grande do Norte', 'Rio Grande do Sul', 'Rondônia',
  'Roraima', 'Santa Catarina', 'São Paulo', 'Sergipe', 'Tocantins',
];

class AddressPage extends StatelessWidget {
  const AddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<AddressCubit>(), child: const _AddressView());
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
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                      const PageTitle('MEU ENDEREÇO'),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<AddressCubit, AddressState>(
                    buildWhen: (previous, current) => previous.status != current.status,
                    builder: (context, state) {
                      return switch (state.status) {
                        LoadStatus.initial || LoadStatus.loading => Center(
                          child: CircularProgressIndicator(color: colors.primary),
                        ),
                        LoadStatus.error => Center(
                          child: StateMessage(
                            icon: Icons.error_outline_rounded,
                            title: 'Não foi possível carregar seu endereço.',
                            message: state.errorMessage,
                          ),
                        ),
                        _ => _AddressForm(address: state.address ?? const UserAddress()),
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
  late String _zip = _applyMask(cepInputFormatter(), widget.address.zipCode ?? '');
  late String _street = widget.address.street ?? '';
  late String _number = widget.address.number ?? '';
  late String _complement = widget.address.complement ?? '';
  late String _neighborhood = widget.address.neighborhood ?? '';
  late String _city = widget.address.city ?? '';
  late String _state = widget.address.state ?? '';

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
              separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
              itemBuilder: (itemContext, index) {
                final state = _brazilianStates[index];
                return ListTile(
                  title: Text(state, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
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
      messenger.showSnackBar(const SnackBar(content: Text('Endereço salvo com sucesso.')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
      children: [
        RegistrationTextField(
          label: 'CEP',
          value: _zip,
          keyboardType: TextInputType.number,
          inputFormatters: [cepInputFormatter()],
          onChanged: (value) => _zip = value,
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Logradouro',
          value: _street,
          onChanged: (value) => _street = value,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RegistrationTextField(
                label: 'Número',
                value: _number,
                keyboardType: TextInputType.number,
                onChanged: (value) => _number = value,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: RegistrationTextField(
                label: 'Complemento (opcional)',
                value: _complement,
                onChanged: (value) => _complement = value,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Bairro',
          value: _neighborhood,
          onChanged: (value) => _neighborhood = value,
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationPickerField(
          label: 'Estado',
          value: _state,
          placeholder: 'Selecionar estado',
          onTap: _pickState,
        ),
        const SizedBox(height: AppSpacing.lg),
        RegistrationTextField(
          label: 'Cidade',
          value: _city,
          onChanged: (value) => _city = value,
        ),
        const SizedBox(height: AppSpacing.xxl),
        BlocBuilder<AddressCubit, AddressState>(
          buildWhen: (previous, current) => previous.saving != current.saving,
          builder: (context, state) {
            return AppPrimaryButton(
              label: 'SALVAR ENDEREÇO',
              loading: state.saving,
              loadingLabel: 'Salvando...',
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
  return formatter.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: raw)).text;
}
