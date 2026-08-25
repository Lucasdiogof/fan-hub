import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:goias_app/features/profile/presentation/cubit/address_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// `load()` é chamado explicitamente por quem cria o Cubit (nunca no
/// construtor) — pra nunca disparar duas buscas concorrentes quando o
/// carregamento já acontece antes da navegação (ver `GlobalLoading.run`
/// em `profile_page.dart`).
class AddressCubit extends Cubit<AddressState> {
  AddressCubit(this._repository) : super(const AddressState());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getAddress();
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: LoadStatus.success, address: data));
      case Error(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.error,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<Failure?> save(UserAddress address) async {
    emit(state.copyWith(saving: true));
    final result = await _repository.saveAddress(address);
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            saving: false,
            status: LoadStatus.success,
            address: address,
          ),
        );
        return null;
      case Error(:final failure):
        emit(state.copyWith(saving: false));
        return failure;
    }
  }
}
