import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/domain/brazilian_states.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/find_zip_code_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class FindZipCodeCubit extends Cubit<FindZipCodeState> {
  FindZipCodeCubit(this._repository) : super(const FindZipCodeState());

  final AddressRepository _repository;

  void selectState(String value) {
    emit(state.copyWith(state: value, city: '', availableCities: const [], citiesLoadStatus: LoadStatus.loading));
    _loadCities(value);
  }

  Future<void> _loadCities(String stateName) async {
    final code = BrazilianStates.codeForName(stateName) ?? stateName;
    final result = await _repository.getCitiesByState(code);
    if (isClosed) return;
    if (state.state != stateName) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(availableCities: data, citiesLoadStatus: LoadStatus.success));
      case Error():
        emit(state.copyWith(availableCities: const [], citiesLoadStatus: LoadStatus.error));
    }
  }

  void selectCity(String value) => emit(state.copyWith(city: value));

  void updateStreet(String value) => emit(state.copyWith(street: value));

  Future<void> search() async {
    if (!state.canSearch) return;
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));

    final ufCode = BrazilianStates.codeForName(state.state) ?? state.state;
    final result = await _repository.searchByAddress(
      state: ufCode,
      city: state.city.trim(),
      street: state.street.trim(),
    );
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: data.isEmpty ? LoadStatus.empty : LoadStatus.success, results: data));
      case Error(:final failure):
        emit(state.copyWith(status: LoadStatus.error, errorMessage: failure.message));
    }
  }
}
