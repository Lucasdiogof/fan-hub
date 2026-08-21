import 'package:equatable/equatable.dart';

class AddressLookupResult extends Equatable {
  const AddressLookupResult({
    required this.zipCode,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  final String zipCode;
  final String street;
  final String neighborhood;
  final String city;
  final String state;

  @override
  List<Object?> get props => [zipCode, street, neighborhood, city, state];
}
