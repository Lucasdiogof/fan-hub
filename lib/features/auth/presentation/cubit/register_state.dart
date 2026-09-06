import 'package:goias_app/core/error/failures.dart';

enum RegisterStep { personal, contact, security }

/// Fonte única dos dados do cadastro em 3 passos — cada `Step*` widget lê e
/// escreve aqui (via `RegisterCubit`), então voltar uma etapa nunca perde o
/// que já foi digitado. Validação/estado de "campo tocado" fica nos
/// widgets (`FieldTouch`, ver `register_step_*.dart`), nunca aqui — este
/// state só guarda os VALORES e o progresso entre passos.
class RegisterState {
  const RegisterState({
    this.step = RegisterStep.personal,
    this.fullName = '',
    this.cpf = '',
    this.birthDate = '',
    this.email = '',
    this.phone = '',
    this.marketingOptIn = false,
    this.password = '',
    this.confirmPassword = '',
    this.acceptedTerms = false,
    this.checkingCpf = false,
    this.submitting = false,
    this.formError,
  });

  final RegisterStep step;
  final String fullName;

  /// Como digitado (com máscara) — normalizado (só dígitos) só na hora de
  /// mandar pro backend, ver `RegisterCubit`.
  final String cpf;

  /// Como digitado (DD/MM/AAAA, com máscara) — nunca um `DateTime` aqui;
  /// parseado só na hora de validar/enviar (ver `AppValidators.parseBirthDate`
  /// em `RegisterCubit.submit`), mesmo padrão do `PersonalDataStep` do Sócio.
  final String birthDate;
  final String email;
  final String phone;
  final bool marketingOptIn;
  final String password;
  final String confirmPassword;
  final bool acceptedTerms;

  /// Loading da checagem de unicidade de CPF (RPC) ao tocar "Continuar" no
  /// Passo 1 — nunca a autoridade final, só UX (ver `cpf_is_taken` no SQL).
  final bool checkingCpf;

  /// Loading do `signUp` de verdade, só existe no Passo 3.
  final bool submitting;

  final Failure? formError;

  RegisterState copyWith({
    RegisterStep? step,
    String? fullName,
    String? cpf,
    String? birthDate,
    String? email,
    String? phone,
    bool? marketingOptIn,
    String? password,
    String? confirmPassword,
    bool? acceptedTerms,
    bool? checkingCpf,
    bool? submitting,
    Failure? formError,
    bool clearFormError = false,
  }) {
    return RegisterState(
      step: step ?? this.step,
      fullName: fullName ?? this.fullName,
      cpf: cpf ?? this.cpf,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      checkingCpf: checkingCpf ?? this.checkingCpf,
      submitting: submitting ?? this.submitting,
      formError: clearFormError ? null : (formError ?? this.formError),
    );
  }
}
