import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/data/regulation_catalog.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_state.dart';
import 'package:goias_app/features/profile/domain/entities/app_user.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/masks.dart';

/// Estado único do fluxo de associação (3 etapas + revisão). Vive por trás
/// de toda a `MembershipRegistrationPage` — voltar uma etapa não reconstrói
/// o cubit, então nada digitado se perde.
class MembershipRegistrationCubit extends Cubit<MembershipRegistrationState> {
  MembershipRegistrationCubit(
    this._repository, {
    required MembershipPlan plan,
    required MembershipPlanPrice price,
    AppUser? prefill,
  }) : super(
         MembershipRegistrationState(
           plan: plan,
           price: price,
           data: MembershipRegistrationData(
             fullName: prefill?.name ?? '',
             contactEmail: prefill?.email ?? '',
             phone: prefill?.phone ?? '',
             cpf: prefill?.cpf ?? '',
           ),
         ),
       );

  final MembershipRepository _repository;

  void updateData(MembershipRegistrationData Function(MembershipRegistrationData current) update) {
    emit(state.copyWith(data: update(state.data)));
  }

  void continueFromAccess() {
    final errors = _validateAccess(state.data);
    if (errors.isNotEmpty) {
      emit(state.copyWith(accessErrors: errors));
      return;
    }
    emit(state.copyWith(step: RegistrationStep.personal, accessErrors: const {}));
  }

  void continueFromPersonal() {
    final errors = _validatePersonal(state.data);
    if (errors.isNotEmpty) {
      emit(state.copyWith(personalErrors: errors));
      return;
    }
    emit(state.copyWith(step: RegistrationStep.address, personalErrors: const {}));
  }

  void continueToReview() {
    final errors = _validateAddress(state.data);
    if (errors.isNotEmpty) {
      emit(state.copyWith(addressErrors: errors));
      return;
    }
    emit(state.copyWith(showReview: true, addressErrors: const {}));
  }

  void setRegulationAccepted(bool value) => emit(state.copyWith(regulationAccepted: value));

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
    final result = await _repository.submitRegistration(
      plan: state.plan,
      price: state.price,
      data: state.data,
      regulationVersion: RegulationCatalog.current.version,
      regulationAcceptedAt: DateTime.now(),
    );
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(submitStatus: LoadStatus.success, submittedMembership: data));
      case Error(:final failure):
        emit(state.copyWith(submitStatus: LoadStatus.error, submitErrorMessage: failure.message));
    }
  }
}

Map<String, String> _validateAccess(MembershipRegistrationData data) {
  final errors = <String, String>{};
  if (data.documentType == DocumentType.cpf) {
    if (onlyDigits(data.cpf).length != 11) {
      errors['cpf'] = 'Informe um CPF válido.';
    }
  } else {
    if (data.passport.trim().isEmpty) {
      errors['passport'] = 'Informe o número do passaporte.';
    }
  }
  if (data.nationality.trim().isEmpty) {
    errors['nationality'] = 'Informe sua nacionalidade.';
  }
  if (data.country.trim().isEmpty) {
    errors['country'] = 'Informe seu país.';
  }
  return errors;
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

Map<String, String> _validatePersonal(MembershipRegistrationData data) {
  final errors = <String, String>{};
  if (!_emailPattern.hasMatch(data.contactEmail.trim())) {
    errors['contactEmail'] = 'Informe um e-mail válido.';
  }
  if (data.fullName.trim().length < 3) {
    errors['fullName'] = 'Informe seu nome completo.';
  }
  if (data.birthDate == null) {
    errors['birthDate'] = 'Informe sua data de nascimento.';
  }
  if (data.gender == null) {
    errors['gender'] = 'Selecione uma opção.';
  }
  if (onlyDigits(data.phone).length < 10) {
    errors['phone'] = 'Informe um celular válido.';
  }
  return errors;
}

Map<String, String> _validateAddress(MembershipRegistrationData data) {
  final errors = <String, String>{};
  if (data.addressCountry.trim().isEmpty) errors['addressCountry'] = 'Informe o país.';
  if (data.street.trim().isEmpty) errors['street'] = 'Informe o logradouro.';
  if (data.number.trim().isEmpty) errors['number'] = 'Informe o número.';
  if (data.neighborhood.trim().isEmpty) errors['neighborhood'] = 'Informe o bairro.';
  if (data.state.trim().isEmpty) errors['state'] = 'Informe o estado.';
  if (data.city.trim().isEmpty) errors['city'] = 'Informe a cidade.';
  return errors;
}
