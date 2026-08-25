import 'package:equatable/equatable.dart';

class UserAddress extends Equatable {
  const UserAddress({
    this.zipCode,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.country = 'BR',
  });

  final String? zipCode;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? country;

  bool get isEmpty => [
    zipCode,
    street,
    number,
    neighborhood,
    city,
    state,
  ].every((value) => value == null || value.isEmpty);

  @override
  List<Object?> get props => [
    zipCode,
    street,
    number,
    complement,
    neighborhood,
    city,
    state,
    country,
  ];
}
