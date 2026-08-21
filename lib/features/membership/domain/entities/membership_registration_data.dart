import 'package:equatable/equatable.dart';

enum Gender { masculino, feminino }

/// CPF é sempre obrigatório (regra do programa); passaporte é sempre
/// opcional (dado adicional, não um substituto do CPF) — não existe mais
/// um toggle "ou/ou" entre os dois.
class MembershipRegistrationData extends Equatable {
  const MembershipRegistrationData({
    this.cpf = '',
    this.nationality = 'BR',
    this.passport = '',
    this.contactEmail = '',
    this.fullName = '',
    this.nickname = '',
    this.birthDate = '',
    this.gender,
    this.phoneCountryCode = 'BR',
    this.phone = '',
    this.landline = '',
    this.wantsNewsletter = false,
    this.addressCountry = 'BR',
    this.zipCode = '',
    this.street = '',
    this.number = '',
    this.complement = '',
    this.neighborhood = '',
    this.state = '',
    this.city = '',
  });

  final String cpf;

  /// Código ISO do país (ex.: "BR") — nacionalidade do titular.
  final String nationality;
  final String passport;

  final String contactEmail;
  final String fullName;
  final String nickname;

  /// Texto mascarado "DD/MM/AAAA", não um `DateTime` — evita duas fontes de
  /// verdade pro mesmo campo (o que o usuário digitou vs. o que foi
  /// interpretado). Parseie com `parseDdMmYyyy` quando precisar da data real.
  final String birthDate;
  final Gender? gender;

  /// Código ISO do país do celular (ex.: "BR") — decide o DDI (+55) e se a
  /// máscara/validação brasileira de celular se aplica.
  final String phoneCountryCode;
  final String phone;
  final String landline;
  final bool wantsNewsletter;

  /// Código ISO do país do endereço — pode divergir da nacionalidade.
  final String addressCountry;
  final String zipCode;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String state;
  final String city;

  MembershipRegistrationData copyWith({
    String? cpf,
    String? nationality,
    String? passport,
    String? contactEmail,
    String? fullName,
    String? nickname,
    String? birthDate,
    Gender? gender,
    String? phoneCountryCode,
    String? phone,
    String? landline,
    bool? wantsNewsletter,
    String? addressCountry,
    String? zipCode,
    String? street,
    String? number,
    String? complement,
    String? neighborhood,
    String? state,
    String? city,
  }) {
    return MembershipRegistrationData(
      cpf: cpf ?? this.cpf,
      nationality: nationality ?? this.nationality,
      passport: passport ?? this.passport,
      contactEmail: contactEmail ?? this.contactEmail,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phone: phone ?? this.phone,
      landline: landline ?? this.landline,
      wantsNewsletter: wantsNewsletter ?? this.wantsNewsletter,
      addressCountry: addressCountry ?? this.addressCountry,
      zipCode: zipCode ?? this.zipCode,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      neighborhood: neighborhood ?? this.neighborhood,
      state: state ?? this.state,
      city: city ?? this.city,
    );
  }

  @override
  List<Object?> get props => [
    cpf,
    nationality,
    passport,
    contactEmail,
    fullName,
    nickname,
    birthDate,
    gender,
    phoneCountryCode,
    phone,
    landline,
    wantsNewsletter,
    addressCountry,
    zipCode,
    street,
    number,
    complement,
    neighborhood,
    state,
    city,
  ];
}
