import 'package:equatable/equatable.dart';
import 'package:goias_app/features/membership/domain/entities/address_lookup_result.dart';
import 'package:goias_app/shared/state/load_status.dart';

class FindZipCodeState extends Equatable {
  const FindZipCodeState({
    this.state = '',
    this.city = '',
    this.street = '',
    this.availableCities = const [],
    this.citiesLoadStatus = LoadStatus.initial,
    this.status = LoadStatus.initial,
    this.results = const [],
    this.errorMessage,
  });

  final String state;
  final String city;
  final String street;
  final List<String> availableCities;
  final LoadStatus citiesLoadStatus;
  final LoadStatus status;
  final List<AddressLookupResult> results;
  final String? errorMessage;

  bool get canSearch => state.isNotEmpty && city.trim().isNotEmpty && street.trim().length >= 3;

  FindZipCodeState copyWith({
    String? state,
    String? city,
    String? street,
    List<String>? availableCities,
    LoadStatus? citiesLoadStatus,
    LoadStatus? status,
    List<AddressLookupResult>? results,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FindZipCodeState(
      state: state ?? this.state,
      city: city ?? this.city,
      street: street ?? this.street,
      availableCities: availableCities ?? this.availableCities,
      citiesLoadStatus: citiesLoadStatus ?? this.citiesLoadStatus,
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    state,
    city,
    street,
    availableCities,
    citiesLoadStatus,
    status,
    results,
    errorMessage,
  ];
}
