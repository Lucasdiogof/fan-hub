import 'package:equatable/equatable.dart';

/// Dados de identificação usados NESTE pedido — separado do perfil
/// principal do usuário de propósito (ver checkout etapa 1): editar aqui
/// nunca toca em `Profile`.
class CustomerIdentification extends Equatable {
  const CustomerIdentification({
    required this.fullName,
    required this.cpf,
    required this.email,
    required this.phone,
  });

  final String fullName;
  final String cpf;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'cpf': cpf,
    'email': email,
    'phone': phone,
  };

  factory CustomerIdentification.fromJson(Map<String, dynamic> json) =>
      CustomerIdentification(
        fullName: json['fullName'] as String,
        cpf: json['cpf'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
      );

  @override
  List<Object?> get props => [fullName, cpf, email, phone];
}

class CustomerAddress extends Equatable {
  const CustomerAddress({
    required this.id,
    required this.zipCode,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    this.reference,
    this.isDefault = false,
    this.label,
  });

  final String id;
  final String zipCode;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String? reference;
  final bool isDefault;

  /// Apelido do endereço de entrega ("Casa", "Trabalho"...) — nunca existe
  /// no endereço residencial, só faz sentido quando há mais de um endereço
  /// pra escolher.
  final String? label;

  String get oneLine =>
      '$street, $number${complement != null ? ' - $complement' : ''} · '
      '$neighborhood, $city - $state';

  CustomerAddress copyWith({bool? isDefault, String? Function()? label}) =>
      CustomerAddress(
        id: id,
        zipCode: zipCode,
        street: street,
        number: number,
        complement: complement,
        neighborhood: neighborhood,
        city: city,
        state: state,
        reference: reference,
        isDefault: isDefault ?? this.isDefault,
        label: label != null ? label() : this.label,
      );

  /// Cópia INDEPENDENTE com um novo id — usada por "usar meu endereço
  /// residencial": os valores são copiados uma vez, nunca uma referência
  /// viva ao residencial (editar um depois nunca afeta o outro).
  CustomerAddress copyAsNew({required String id, String? label}) =>
      CustomerAddress(
        id: id,
        zipCode: zipCode,
        street: street,
        number: number,
        complement: complement,
        neighborhood: neighborhood,
        city: city,
        state: state,
        reference: reference,
        label: label,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'zipCode': zipCode,
    'street': street,
    'number': number,
    'complement': complement,
    'neighborhood': neighborhood,
    'city': city,
    'state': state,
    'reference': reference,
    'isDefault': isDefault,
    'label': label,
  };

  factory CustomerAddress.fromJson(Map<String, dynamic> json) =>
      CustomerAddress(
        id: json['id'] as String,
        zipCode: json['zipCode'] as String,
        street: json['street'] as String,
        number: json['number'] as String,
        complement: json['complement'] as String?,
        neighborhood: json['neighborhood'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        reference: json['reference'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
        label: json['label'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    zipCode,
    street,
    number,
    complement,
    neighborhood,
    city,
    state,
    reference,
    isDefault,
    label,
  ];
}

/// Quem vai retirar na loja, quando não é o próprio titular do pedido.
class PickupResponsible extends Equatable {
  const PickupResponsible({required this.fullName, required this.cpf});

  final String fullName;
  final String cpf;

  Map<String, dynamic> toJson() => {'fullName': fullName, 'cpf': cpf};

  factory PickupResponsible.fromJson(Map<String, dynamic> json) =>
      PickupResponsible(
        fullName: json['fullName'] as String,
        cpf: json['cpf'] as String,
      );

  @override
  List<Object?> get props => [fullName, cpf];
}
