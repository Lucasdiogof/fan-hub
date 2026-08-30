import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Ouve `AuthCubit` pra nunca vazar perfil de uma conta pra outra — mesmo
/// padrão já correto do `MembershipStatusCubit`: limpa na hora em
/// logout/sessão expirada (sem esperar rede), recarrega no login.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository, AuthCubit authCubit)
    : super(const ProfileState()) {
    if (authCubit.state is AuthAuthenticated) load();
    _authSubscription = authCubit.stream.listen(_onAuthChanged);
  }

  final ProfileRepository _repository;
  late final StreamSubscription<AuthState> _authSubscription;

  void _onAuthChanged(AuthState state) {
    switch (state) {
      case AuthAuthenticated():
        load();
      case AuthUnauthenticated():
      case AuthSessionExpired():
        emit(const ProfileState(status: LoadStatus.success));
      case AuthInitial():
      case AuthPasswordRecovery():
        break;
    }
  }

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getProfile();
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(status: LoadStatus.success, profile: data));
      case Error(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.error,
            errorMessage: failure.message,
          ),
        );
    }
  }

  Future<Failure?> updatePersonalData({
    String? fullName,
    String? cpf,
    DateTime? birthDate,
    String? phone,
  }) async {
    emit(state.copyWith(saving: true));
    final result = await _repository.updateProfile(
      fullName: fullName,
      cpf: cpf,
      birthDate: birthDate,
      phone: phone,
    );
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            saving: false,
            status: LoadStatus.success,
            profile: data,
          ),
        );
        return null;
      case Error(:final failure):
        emit(state.copyWith(saving: false));
        return failure;
    }
  }

  Future<Failure?> uploadAvatar(Uint8List bytes, String fileExtension) async {
    emit(state.copyWith(uploadingAvatar: true));
    final result = await _repository.uploadAvatar(bytes, fileExtension);
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(uploadingAvatar: false, profile: data));
        return null;
      case Error(:final failure):
        emit(state.copyWith(uploadingAvatar: false));
        return failure;
    }
  }

  @override
  Future<void> close() {
    unawaited(_authSubscription.cancel());
    return super.close();
  }
}
