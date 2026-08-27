import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/domain/brazilian_states.dart';
import 'package:goias_app/features/membership/domain/entities/address_lookup_result.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/find_zip_code_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/find_zip_code_state.dart';
import 'package:goias_app/features/membership/presentation/widgets/registration_field.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Busca reversa pelo ViaCEP (UF + cidade + logradouro) pra quem não sabe
/// o próprio CEP — devolve o endereço escolhido pra Etapa de Endereço via
/// `context.pop(AddressLookupResult)`.
class FindZipCodePage extends StatelessWidget {
  const FindZipCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FindZipCodeCubit(sl<AddressRepository>()),
      child: const _FindZipCodeView(),
    );
  }
}

class _FindZipCodeView extends StatelessWidget {
  const _FindZipCodeView();

  Future<void> _pickState(BuildContext context, FindZipCodeCubit cubit) {
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
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.border),
              itemBuilder: (itemContext, index) {
                final state = BrazilianStates.states[index];
                return ListTile(
                  title: Text(
                    state.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
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

  Future<void> _pickCity(
    BuildContext context,
    FindZipCodeCubit cubit,
    List<String> cities,
  ) {
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
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.border),
              itemBuilder: (itemContext, index) {
                final city = cities[index];
                return ListTile(
                  title: Text(
                    city,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    cubit.selectCity(city);
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
    final cubit = context.read<FindZipCodeCubit>();
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: BlocBuilder<FindZipCodeCubit, FindZipCodeState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        context.l10n.membershipFindCepTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.membershipFindCepSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Expanded(
                        child: ListView(
                          children: [
                            RegistrationPickerField(
                              label: context.l10n.addressFieldState,
                              isRequired: true,
                              value: state.state,
                              placeholder: context.l10n.addressSelectState,
                              onTap: () => _pickState(context, cubit),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            RegistrationPickerField(
                              label: context.l10n.addressFieldCity,
                              isRequired: true,
                              value: state.city,
                              placeholder:
                                  state.citiesLoadStatus == LoadStatus.loading
                                  ? context.l10n.membershipLoadingCities
                                  : (state.state.isEmpty
                                        ? context
                                              .l10n
                                              .membershipSelectStateFirst
                                        : context.l10n.membershipSelectCity),
                              onTap:
                                  state.state.isEmpty ||
                                      state.citiesLoadStatus ==
                                          LoadStatus.loading
                                  ? () {}
                                  : () => _pickCity(
                                      context,
                                      cubit,
                                      state.availableCities,
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            RegistrationTextField(
                              label: context.l10n.membershipStreetLabel,
                              isRequired: true,
                              value: state.street,
                              textCapitalization: TextCapitalization.words,
                              onChanged: cubit.updateStreet,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    state.canSearch &&
                                        state.status != LoadStatus.loading
                                    ? cubit.search
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.button,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                child: state.status == LoadStatus.loading
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colors.onPrimary,
                                        ),
                                      )
                                    : Text(context.l10n.membershipSearchCep),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            _ResultsSection(state: state),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({required this.state});

  final FindZipCodeState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    switch (state.status) {
      case LoadStatus.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.membershipFoundAddresses,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: colors.textHint,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final result in state.results) ...[
              _ResultRow(result: result),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      case LoadStatus.empty:
        return Center(
          child: StateMessage(
            icon: Icons.search_off_rounded,
            title: context.l10n.membershipNoAddressFound,
            message: context.l10n.membershipNoAddressHint,
          ),
        );
      case LoadStatus.error:
        return Center(
          child: StateMessage(
            icon: Icons.error_outline_rounded,
            title: context.l10n.membershipAddressSearchError,
            message: state.errorMessage,
          ),
        );
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const SizedBox.shrink();
    }
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});

  final AddressLookupResult result;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () => context.pop(result),
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.street,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (result.neighborhood.isNotEmpty)
                    Text(
                      result.neighborhood,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  Text(
                    '${result.city} - ${result.state}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                  if (result.zipCode.isNotEmpty)
                    Text(
                      '${result.zipCode.substring(0, 5)}-${result.zipCode.substring(5)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}
