import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:goias_app/shared/domain/brazilian_states.dart';
import 'package:goias_app/features/membership/domain/entities/address_lookup_result.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_state.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/masks.dart';

/// Estado único do fluxo de associação (3 etapas + revisão). Vive por trás
/// de toda a `MembershipRegistrationPage` — voltar uma etapa não reconstrói
/// o cubit, então nada digitado se perde.
class MembershipRegistrationCubit extends Cubit<MembershipRegistrationState> {
  MembershipRegistrationCubit(
    this._membershipStatusCubit,
    this._addressRepository, {
    required MembershipPlan plan,
    required MembershipPlanPrice price,
    MembershipRegistrationData? initialData,
    ProfileRepository? profileRepository,
  }) : super(
         MembershipRegistrationState(
           plan: plan,
           price: price,
           data: initialData ?? const MembershipRegistrationData(),
         ),
       ) {
    // Só busca o endereço residencial quando o clube pediu pré-preenchimento
    // (`MembershipProgramConfig.prefillFromProfile`) — nome/CPF/e-mail/
    // telefone/nascimento já chegam prontos via `initialData` (síncrono,
    // resolvido antes deste cubit existir); o endereço é assíncrono
    // (`ProfileRepository.getAddress()`, mesma fonte que a Loja usa pro
    // "endereço residencial") e por isso é buscado aqui.
    if (profileRepository != null) {
      unawaited(_prefillResidentialAddress(profileRepository));
    }
  }

  final MembershipStatusCubit _membershipStatusCubit;
  final AddressRepository _addressRepository;
  Timer? _cepDebounce;

  Future<void> _prefillResidentialAddress(
    ProfileRepository profileRepository,
  ) async {
    final result = await profileRepository.getAddress();
    if (isClosed) return;
    final address = switch (result) {
      Success(:final data) => data,
      Error() => null,
    };
    if (address == null || address.isEmpty) return;
    // Nunca sobrescreve o que o titular já digitou na Etapa 3 enquanto a
    // busca assíncrona do endereço residencial corria.
    const addressFields = {
      'zipCode',
      'street',
      'number',
      'complement',
      'neighborhood',
      'state',
      'city',
    };
    if (state.touchedFields.intersection(addressFields).isNotEmpty) return;
    _applyUserAddress(address);
  }

  void _applyUserAddress(UserAddress address) {
    emit(
      state.copyWith(
        data: state.data.copyWith(
          addressCountry: address.country ?? state.data.addressCountry,
          zipCode: address.zipCode ?? state.data.zipCode,
          street: address.street ?? state.data.street,
          number: address.number ?? state.data.number,
          complement: address.complement ?? state.data.complement,
          neighborhood: address.neighborhood ?? state.data.neighborhood,
          state: address.state ?? state.data.state,
          city: address.city ?? state.data.city,
        ),
        touchedFields: {
          ...state.touchedFields,
          'zipCode',
          'street',
          'number',
          'neighborhood',
          'state',
          'city',
        },
      ),
    );
    final stateName = address.state;
    if (stateName != null && stateName.isNotEmpty) unawaited(_loadCities(stateName));
  }

  void _updateField(
    String fieldKey,
    MembershipRegistrationData Function(MembershipRegistrationData) update,
  ) {
    emit(
      state.copyWith(
        data: update(state.data),
        touchedFields: {...state.touchedFields, fieldKey},
      ),
    );
  }

  void updateCpf(String value) =>
      _updateField('cpf', (d) => d.copyWith(cpf: value));

  void updateNationality(String isoCode) =>
      _updateField('nationality', (d) => d.copyWith(nationality: isoCode));

  void updatePassport(String value) =>
      _updateField('passport', (d) => d.copyWith(passport: value));

  void updateContactEmail(String value) =>
      _updateField('contactEmail', (d) => d.copyWith(contactEmail: value));

  void updateFullName(String value) =>
      _updateField('fullName', (d) => d.copyWith(fullName: value));

  void updateNickname(String value) =>
      _updateField('nickname', (d) => d.copyWith(nickname: value));

  void updateBirthDate(String value) =>
      _updateField('birthDate', (d) => d.copyWith(birthDate: value));

  void updateGender(Gender gender) =>
      _updateField('gender', (d) => d.copyWith(gender: gender));

  void updatePhoneCountryCode(String isoCode) => _updateField(
    'phoneCountryCode',
    (d) => d.copyWith(phoneCountryCode: isoCode),
  );

  void updatePhone(String value) =>
      _updateField('phone', (d) => d.copyWith(phone: value));

  void updateLandline(String value) =>
      _updateField('landline', (d) => d.copyWith(landline: value));

  void updateWantsNewsletter(bool value) => _updateField(
    'wantsNewsletter',
    (d) => d.copyWith(wantsNewsletter: value),
  );

  void updateAddressCountry(String isoCode) {
    _cepDebounce?.cancel();
    emit(
      state.copyWith(
        data: state.data.copyWith(addressCountry: isoCode),
        touchedFields: {...state.touchedFields, 'addressCountry'},
        cepLookupStatus: LoadStatus.initial,
        clearCepLookupError: true,
      ),
    );
  }

  void updateZipCode(String value) {
    _updateField('zipCode', (d) => d.copyWith(zipCode: value));
    _cepDebounce?.cancel();

    final digits = onlyDigits(value);
    if (digits.length != 8 || state.data.addressCountry != 'BR') {
      emit(
        state.copyWith(
          cepLookupStatus: LoadStatus.initial,
          clearCepLookupError: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        cepLookupStatus: LoadStatus.loading,
        clearCepLookupError: true,
      ),
    );
    _cepDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _lookupZipCode(digits),
    );
  }

  Future<void> _lookupZipCode(String digits) async {
    final result = await _addressRepository.findByZipCode(digits);
    if (isClosed) return;
    // O usuário pode ter mudado o CEP enquanto a consulta rodava.
    if (onlyDigits(state.data.zipCode) != digits) return;

    switch (result) {
      case Success(:final data):
        if (data == null) {
          emit(
            state.copyWith(
              cepLookupStatus: LoadStatus.error,
              cepLookupErrorMessage: 'CEP não encontrado.',
            ),
          );
          return;
        }
        _applyAddress(data, alsoZipCode: false);
        emit(
          state.copyWith(
            cepLookupStatus: LoadStatus.success,
            clearCepLookupError: true,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            cepLookupStatus: LoadStatus.error,
            cepLookupErrorMessage: failure.message,
          ),
        );
    }
  }

  /// Usado tanto pela consulta automática quanto pela tela "Não sei meu
  /// CEP" — os dois caminhos precisam atualizar o mesmo estado único, sem
  /// deixar o Cubit acreditar que os campos continuam vazios.
  void applyAddressLookupResult(AddressLookupResult result) =>
      _applyAddress(result, alsoZipCode: true);

  void _applyAddress(AddressLookupResult result, {required bool alsoZipCode}) {
    final stateName = BrazilianStates.nameForCode(result.state);
    emit(
      state.copyWith(
        data: state.data.copyWith(
          zipCode: alsoZipCode ? result.zipCode : state.data.zipCode,
          street: result.street.isNotEmpty ? result.street : state.data.street,
          neighborhood: result.neighborhood.isNotEmpty
              ? result.neighborhood
              : state.data.neighborhood,
          city: result.city.isNotEmpty ? result.city : state.data.city,
          state: result.state.isNotEmpty ? stateName : state.data.state,
        ),
        touchedFields: {
          ...state.touchedFields,
          'zipCode',
          'street',
          'neighborhood',
          'state',
          'city',
        },
        cepLookupStatus: LoadStatus.success,
        clearCepLookupError: true,
      ),
    );
    // Carrega a lista de cidades da UF pra manter o seletor de Cidade
    // coerente com o que o CEP já preencheu, caso o usuário queira revisar.
    if (result.state.isNotEmpty) unawaited(_loadCities(stateName));
  }

  /// Escolher o Estado manualmente (fora do preenchimento por CEP) limpa a
  /// Cidade — uma cidade de outro estado não faz mais sentido — e busca a
  /// lista de municípios da nova UF no IBGE.
  void selectState(String stateName) {
    emit(
      state.copyWith(
        data: state.data.copyWith(state: stateName, city: ''),
        touchedFields: {...state.touchedFields, 'state', 'city'},
        availableCities: const [],
        citiesLoadStatus: LoadStatus.loading,
      ),
    );
    unawaited(_loadCities(stateName));
  }

  Future<void> _loadCities(String stateName) async {
    final code = BrazilianStates.codeForName(stateName) ?? stateName;
    final result = await _addressRepository.getCitiesByState(code);
    if (isClosed) return;
    // O usuário pode ter trocado de estado de novo enquanto isso rodava.
    if (state.data.state != stateName) return;
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            availableCities: data,
            citiesLoadStatus: LoadStatus.success,
          ),
        );
      case Error():
        emit(
          state.copyWith(
            availableCities: const [],
            citiesLoadStatus: LoadStatus.error,
          ),
        );
    }
  }

  void updateStreet(String value) =>
      _updateField('street', (d) => d.copyWith(street: value));

  void updateNumber(String value) =>
      _updateField('number', (d) => d.copyWith(number: value));

  void updateComplement(String value) =>
      _updateField('complement', (d) => d.copyWith(complement: value));

  void updateNeighborhood(String value) =>
      _updateField('neighborhood', (d) => d.copyWith(neighborhood: value));

  void updateState(String value) =>
      _updateField('state', (d) => d.copyWith(state: value));

  void updateCity(String value) =>
      _updateField('city', (d) => d.copyWith(city: value));

  void continueFromAccess() {
    emit(state.copyWith(accessAttempted: true));
    if (!state.isAccessStepValid) return;
    emit(state.copyWith(step: RegistrationStep.personal));
  }

  void continueFromPersonal() {
    emit(state.copyWith(personalAttempted: true));
    if (!state.isPersonalStepValid) return;
    emit(state.copyWith(step: RegistrationStep.address));
  }

  void continueToReview() {
    emit(state.copyWith(addressAttempted: true));
    if (!state.isAddressStepValid) return;
    emit(state.copyWith(showReview: true));
  }

  void setRegulationAccepted(bool value) =>
      emit(state.copyWith(regulationAccepted: value));

  /// Da revisão volta só pra Etapa 3; das etapas 2/3 volta uma etapa; nunca
  /// perde o que já foi preenchido, porque tudo continua no mesmo `data`.
  void back() {
    if (state.showReview) {
      emit(state.copyWith(showReview: false));
      return;
    }
    switch (state.step) {
      case RegistrationStep.personal:
        emit(state.copyWith(step: RegistrationStep.access));
      case RegistrationStep.address:
        emit(state.copyWith(step: RegistrationStep.personal));
      case RegistrationStep.access:
        break;
    }
  }

  Future<void> submit() async {
    if (!state.regulationAccepted) return;
    emit(state.copyWith(submitStatus: LoadStatus.loading));
    final result = await _membershipStatusCubit.subscribeToPlan(
      plan: state.plan,
      price: state.price,
      data: state.data,
      // Nunca fixo no Goiás — cada clube tem o próprio regulamento/termo
      // (ver `MembershipProgramConfig.regulationVersion`), gravado junto do
      // aceite de quem está se associando.
      regulationVersion: sl<ClubConfig>().membershipProgram.regulationVersion.version,
      regulationAcceptedAt: DateTime.now(),
    );
    switch (result) {
      case Success<Membership>(:final data):
        emit(
          state.copyWith(submitStatus: LoadStatus.success, membership: data),
        );
      case Error<Membership>(:final failure):
        emit(
          state.copyWith(
            submitStatus: LoadStatus.error,
            submitErrorMessage: failure.message,
          ),
        );
    }
  }

  @override
  Future<void> close() {
    _cepDebounce?.cancel();
    return super.close();
  }
}
