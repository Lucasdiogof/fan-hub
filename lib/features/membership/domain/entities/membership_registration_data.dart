import 'package:equatable/equatable.dart';

enum DocumentType { cpf, passport }

enum Gender { masculino, feminino }

class MembershipRegistrationData extends Equatable {
  const MembershipRegistrationData({
    this.documentType = DocumentType.cpf,
    this.cpf = '',
    this.passport = '',
    this.nationality = 'Brasileira',
    this.country = 'Brasil',
    this.contactEmail = '',
    this.fullName = '',
    this.nickname = '',
    this.birthDate,
    this.gender,
    this.phone = '',
    this.landline = '',
    this.wantsNewsletter = false,
    this.addressCountry = 'Brasil',
    this.zipCode = '',
    this.street = '',
    this.number = '',
    this.complement = '',
    this.neighborhood = '',
    this.state = '',
    this.city = '',
  });

  final DocumentType documentType;
  final String cpf;
  final String passport;
  final String nationality;
  final String country;

  final String contactEmail;
  final String fullName;
  final String nickname;
  final DateTime? birthDate;
  final Gender? gender;
  final String phone;
  final String landline;
  final bool wantsNewsletter;

  final String addressCountry;
  final String zipCode;
  final String street;
  final String number;
  final String complement;
  final String neighborhood;
  final String state;
  final String city;

  MembershipRegistrationData copyWith({
    DocumentType? documentType,
    String? cpf,
    String? passport,
    String? nationality,
    String? country,
    String? contactEmail,
    String? fullName,
    String? nickname,
    DateTime? birthDate,
    Gender? gender,
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
      documentType: documentType ?? this.documentType,
      cpf: cpf ?? this.cpf,
      passport: passport ?? this.passport,
      nationality: nationality ?? this.nationality,
      country: country ?? this.country,
      contactEmail: contactEmail ?? this.contactEmail,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
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
    documentType,
    cpf,
    passport,
    nationality,
    country,
    contactEmail,
    fullName,
    nickname,
    birthDate,
    gender,
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
