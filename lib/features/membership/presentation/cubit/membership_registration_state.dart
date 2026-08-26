import 'package:equatable/equatable.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/membership_registration_validators.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/masks.dart';

enum RegistrationStep { access, personal, address }

/// Única fonte de verdade do formulário — os erros de cada etapa são
/// getters computados a partir de `data` + `touchedFields` + as flags de
/// tentativa, nunca um valor armazenado à parte. Isso é o que garante que
/// "corrigiu o campo" e "erro sumiu" andem sempre juntos: não tem como o
/// texto exibido ficar certo enquanto o estado ainda acha que tá errado,
/// porque o erro é recalculado toda vez a partir do valor atual.
class MembershipRegistrationState extends Equatable {
  const MembershipRegistrationState({
    required this.plan,
    required this.price,
    this.step = RegistrationStep.access,
    this.showReview = false,
    this.data = const MembershipRegistrationData(),
    this.touchedFields = const {},
    this.blurredFields = const {},
    this.accessAttempted = false,
    this.personalAttempted = false,
    this.addressAttempted = false,
    this.cepLookupStatus = LoadStatus.initial,
    this.cepLookupErrorMessage,
    this.availableCities = const [],
    this.citiesLoadStatus = LoadStatus.initial,
    this.regulationAccepted = false,
    this.submitStatus = LoadStatus.initial,
    this.submitErrorMessage,
    this.membership,
  });

  final MembershipPlan plan;
  final MembershipPlanPrice price;
  final RegistrationStep step;
  final bool showReview;
  final MembershipRegistrationData data;

  /// Campos em que o usuário já interagiu — junto com as flags abaixo,
  /// decide se um erro de "campo obrigatório" já deve aparecer.
  final Set<String> touchedFields;

  /// Campos que já perderam o foco pelo menos uma vez — usado só pros
  /// campos de texto livre (e-mail, nome, passaporte): não faz sentido
  /// validar o "formato" enquanto a pessoa ainda está no meio de digitar.
  final Set<String> blurredFields;
  final bool accessAttempted;
  final bool personalAttempted;
  final bool addressAttempted;

  final LoadStatus cepLookupStatus;
  final String? cepLookupErrorMessage;

  /// Cidades do IBGE pra UF selecionada — Cidade depende do Estado, não é
  /// mais texto livre no fluxo brasileiro.
  final List<String> availableCities;
  final LoadStatus citiesLoadStatus;

  final bool regulationAccepted;
  final LoadStatus submitStatus;
  final String? submitErrorMessage;

  /// Preenchida só quando [submitStatus] vira [LoadStatus.success] — é a
  /// associação de verdade criada pelo repositório, não um placeholder.
  final Membership? membership;

  bool _revealed(String field, bool stepAttempted) =>
      touchedFields.contains(field) || stepAttempted;

  // ── ETAPA 1 — ACESSO ─────────────────────────────────────────────────
  Map<String, String> accessErrors(AppLocalizations l10n) {
    final errors = <String, String>{};
    final cpfDigits = onlyDigits(data.cpf);
    if (cpfDigits.isEmpty) {
      if (_revealed('cpf', accessAttempted)) errors['cpf'] = l10n.membershipValCpfRequired;
    } else if (!isValidCpf(data.cpf) &&
        (cpfDigits.length == 11 ||
            blurredFields.contains('cpf') ||
            accessAttempted)) {
      errors['cpf'] = l10n.personalCpfInvalid;
    }

    if (data.nationality.isEmpty && _revealed('nationality', accessAttempted)) {
      errors['nationality'] = l10n.membershipValNationality;
    }

    if (data.passport.trim().isNotEmpty &&
        !isValidPassportShape(data.passport) &&
        (blurredFields.contains('passport') || accessAttempted)) {
      errors['passport'] = l10n.membershipValPassport;
    }

    return errors;
  }

  bool get isAccessStepValid =>
      isValidCpf(data.cpf) &&
      data.nationality.isNotEmpty &&
      (data.passport.trim().isEmpty || isValidPassportShape(data.passport));

  // ── ETAPA 2 — DADOS CADASTRAIS ───────────────────────────────────────
  Map<String, String> personalErrors(AppLocalizations l10n) {
    final errors = <String, String>{};

    if (data.contactEmail.trim().isEmpty) {
      if (_revealed('contactEmail', personalAttempted)) {
        errors['contactEmail'] = l10n.membershipValContactEmail;
      }
    } else if (!isValidEmailShape(data.contactEmail) &&
        (blurredFields.contains('contactEmail') || personalAttempted)) {
      errors['contactEmail'] = l10n.validatorEmailInvalid;
    }

    if (data.fullName.trim().isEmpty) {
      if (_revealed('fullName', personalAttempted)) {
        errors['fullName'] = l10n.validatorNameRequired;
      }
    } else if (!isValidFullName(data.fullName) &&
        (blurredFields.contains('fullName') || personalAttempted)) {
      errors['fullName'] = l10n.membershipValNameInvalid;
    }

    final birthDigits = onlyDigits(data.birthDate);
    final birthRevealed =
        blurredFields.contains('birthDate') ||
        personalAttempted ||
        birthDigits.length == 8;
    if (birthDigits.isEmpty) {
      if (_revealed('birthDate', personalAttempted)) {
        errors['birthDate'] = l10n.membershipValBirthRequired;
      }
    } else if (birthDigits.length < 8) {
      if (birthRevealed) errors['birthDate'] = l10n.membershipValBirthInvalid;
    } else {
      final parsed = parseDdMmYyyy(data.birthDate);
      if (parsed == null || parsed.isAfter(DateTime.now())) {
        errors['birthDate'] = l10n.membershipValBirthInvalid;
      } else if (!isAtLeast18(parsed)) {
        errors['birthDate'] = l10n.membershipValMinAge;
      }
    }

    if (data.gender == null && _revealed('gender', personalAttempted)) {
      errors['gender'] = l10n.membershipValSelectOption;
    }

    final phoneDigits = onlyDigits(data.phone);
    final isBrazilPhone = data.phoneCountryCode == 'BR';
    final phoneValid = isBrazilPhone
        ? isValidMobilePhone(data.phone)
        : isValidInternationalPhone(data.phone);
    final phoneComplete = isBrazilPhone
        ? phoneDigits.length >= 11
        : phoneDigits.length >= 6;
    if (phoneDigits.isEmpty) {
      if (_revealed('phone', personalAttempted)) {
        errors['phone'] = l10n.membershipValPhoneRequired;
      }
    } else if (!phoneValid &&
        (phoneComplete ||
            blurredFields.contains('phone') ||
            personalAttempted)) {
      errors['phone'] = l10n.membershipValPhoneInvalid;
    }

    return errors;
  }

  bool get isPersonalStepValid {
    if (!isValidEmailShape(data.contactEmail)) return false;
    if (!isValidFullName(data.fullName)) return false;
    final birth = parseDdMmYyyy(data.birthDate);
    if (birth == null || birth.isAfter(DateTime.now()) || !isAtLeast18(birth)) {
      return false;
    }
    if (data.gender == null) return false;
    final phoneValid = data.phoneCountryCode == 'BR'
        ? isValidMobilePhone(data.phone)
        : isValidInternationalPhone(data.phone);
    if (!phoneValid) return false;
    return true;
  }

  // ── ETAPA 3 — ENDEREÇO ───────────────────────────────────────────────
  Map<String, String> addressErrors(AppLocalizations l10n) {
    final errors = <String, String>{};

    if (data.addressCountry.isEmpty &&
        _revealed('addressCountry', addressAttempted)) {
      errors['addressCountry'] = l10n.membershipValCountry;
    }

    if (data.addressCountry == 'BR') {
      final cepDigits = onlyDigits(data.zipCode);
      if (cepDigits.length < 8 && _revealed('zipCode', addressAttempted)) {
        errors['zipCode'] = l10n.membershipValCep8;
      } else if (cepLookupStatus == LoadStatus.error) {
        errors['zipCode'] =
            l10n.membershipCepLookupError;
      }
    }

    if (data.street.trim().isEmpty && _revealed('street', addressAttempted)) {
      errors['street'] = l10n.membershipValStreet;
    }
    if (data.number.trim().isEmpty && _revealed('number', addressAttempted)) {
      errors['number'] = l10n.membershipValNumber;
    }
    if (data.neighborhood.trim().isEmpty &&
        _revealed('neighborhood', addressAttempted)) {
      errors['neighborhood'] = l10n.membershipValNeighborhood;
    }
    if (data.state.trim().isEmpty && _revealed('state', addressAttempted)) {
      errors['state'] = l10n.membershipValState;
    }
    if (data.city.trim().isEmpty && _revealed('city', addressAttempted)) {
      errors['city'] = l10n.membershipValCity;
    }

    return errors;
  }

  bool get isAddressStepValid {
    if (cepLookupStatus == LoadStatus.loading) return false;
    if (data.addressCountry.isEmpty) return false;
    if (data.addressCountry == 'BR' && onlyDigits(data.zipCode).length != 8) {
      return false;
    }
    if (data.street.trim().isEmpty) return false;
    if (data.number.trim().isEmpty) return false;
    if (data.neighborhood.trim().isEmpty) return false;
    if (data.state.trim().isEmpty) return false;
    if (data.city.trim().isEmpty) return false;
    return true;
  }

  MembershipRegistrationState copyWith({
    MembershipPlan? plan,
    MembershipPlanPrice? price,
    RegistrationStep? step,
    bool? showReview,
    MembershipRegistrationData? data,
    Set<String>? touchedFields,
    Set<String>? blurredFields,
    bool? accessAttempted,
    bool? personalAttempted,
    bool? addressAttempted,
    LoadStatus? cepLookupStatus,
    String? cepLookupErrorMessage,
    bool clearCepLookupError = false,
    List<String>? availableCities,
    LoadStatus? citiesLoadStatus,
    bool? regulationAccepted,
    LoadStatus? submitStatus,
    String? submitErrorMessage,
    Membership? membership,
  }) {
    return MembershipRegistrationState(
      plan: plan ?? this.plan,
      price: price ?? this.price,
      step: step ?? this.step,
      showReview: showReview ?? this.showReview,
      data: data ?? this.data,
      touchedFields: touchedFields ?? this.touchedFields,
      blurredFields: blurredFields ?? this.blurredFields,
      accessAttempted: accessAttempted ?? this.accessAttempted,
      personalAttempted: personalAttempted ?? this.personalAttempted,
      addressAttempted: addressAttempted ?? this.addressAttempted,
      cepLookupStatus: cepLookupStatus ?? this.cepLookupStatus,
      cepLookupErrorMessage: clearCepLookupError
          ? null
          : (cepLookupErrorMessage ?? this.cepLookupErrorMessage),
      availableCities: availableCities ?? this.availableCities,
      citiesLoadStatus: citiesLoadStatus ?? this.citiesLoadStatus,
      regulationAccepted: regulationAccepted ?? this.regulationAccepted,
      submitStatus: submitStatus ?? this.submitStatus,
      submitErrorMessage: submitErrorMessage ?? this.submitErrorMessage,
      membership: membership ?? this.membership,
    );
  }

  @override
  List<Object?> get props => [
    plan,
    price,
    step,
    showReview,
    data,
    touchedFields,
    blurredFields,
    accessAttempted,
    personalAttempted,
    addressAttempted,
    cepLookupStatus,
    cepLookupErrorMessage,
    availableCities,
    citiesLoadStatus,
    regulationAccepted,
    submitStatus,
    submitErrorMessage,
    membership,
  ];
}
