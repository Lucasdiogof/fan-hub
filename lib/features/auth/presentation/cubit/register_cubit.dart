import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/register_state.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:goias_app/shared/validation/app_validators.dart';

/// Governa só navegação entre os 3 passos + os dados coletados — a
/// validação "esse campo está certo?" mora nos widgets (`FieldTouch`),
/// igual todo formulário novo do app. O `signUp` de verdade só é chamado
/// no Passo 3 ([submit]), nunca antes.
class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this._authCubit) : super(const RegisterState());

  final AuthCubit _authCubit;

  void updateFullName(String value) =>
      emit(state.copyWith(fullName: value, clearFormError: true));
  void updateCpf(String value) =>
      emit(state.copyWith(cpf: value, clearFormError: true));
  void updateBirthDate(String value) =>
      emit(state.copyWith(birthDate: value, clearFormError: true));
  void updateEmail(String value) =>
      emit(state.copyWith(email: value, clearFormError: true));
  void updatePhone(String value) =>
      emit(state.copyWith(phone: value, clearFormError: true));
  void updateMarketingOptIn(bool value) =>
      emit(state.copyWith(marketingOptIn: value));
  void updatePassword(String value) =>
      emit(state.copyWith(password: value, clearFormError: true));
  void updateConfirmPassword(String value) =>
      emit(state.copyWith(confirmPassword: value, clearFormError: true));
  void updateAcceptedTerms(bool value) =>
      emit(state.copyWith(acceptedTerms: value));

  /// Só avança se o CPF (normalizado) ainda não existir — checagem de UX,
  /// nunca a autoridade final (essa é o unique index no Postgres). Retorna
  /// `true` quando avançou.
  Future<bool> continueFromPersonal() async {
    emit(state.copyWith(checkingCpf: true, clearFormError: true));
    final result = await _authCubit.isCpfTaken(onlyDigits(state.cpf));
    switch (result) {
      case Success<bool>(:final data):
        emit(
          state.copyWith(
            checkingCpf: false,
            step: data ? state.step : RegisterStep.contact,
            formError: data
                ? 'Este CPF já está cadastrado em outra conta.'
                : null,
            clearFormError: !data,
          ),
        );
        return !data;
      case Error<bool>(:final failure):
        emit(
          state.copyWith(checkingCpf: false, formError: failure.message),
        );
        return false;
    }
  }

  void continueFromContact() =>
      emit(state.copyWith(step: RegisterStep.security, clearFormError: true));

  /// `true` só quando havia um passo anterior de verdade — `false` no
  /// Passo 1 significa "a tela é quem decide o que fazer" (sair do
  /// cadastro), nunca um passo -1 inexistente.
  bool back() {
    switch (state.step) {
      case RegisterStep.personal:
        return false;
      case RegisterStep.contact:
        emit(state.copyWith(step: RegisterStep.personal, clearFormError: true));
        return true;
      case RegisterStep.security:
        emit(state.copyWith(step: RegisterStep.contact, clearFormError: true));
        return true;
    }
  }

  Future<Result<bool>> submit() async {
    emit(state.copyWith(submitting: true, clearFormError: true));
    final result = await _authCubit.signUp(
      fullName: state.fullName.trim(),
      email: state.email,
      password: state.password,
      cpf: onlyDigits(state.cpf),
      birthDate: AppValidators.parseBirthDate(state.birthDate)!,
      phone: onlyDigits(state.phone),
      marketingOptIn: state.marketingOptIn,
    );
    switch (result) {
      case Success<bool>():
        emit(state.copyWith(submitting: false));
      case Error<bool>(:final failure):
        emit(state.copyWith(submitting: false, formError: failure.message));
    }
    return result;
  }
}
