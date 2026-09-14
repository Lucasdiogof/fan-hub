import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:goias_app/features/profile/presentation/cubit/address_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _profile = Profile(id: 'u1', email: 'torcedor@example.com');
const _address = UserAddress(
  zipCode: '74000000',
  street: 'Rua T-1',
  number: '100',
  neighborhood: 'Setor Bueno',
  city: 'Goiânia',
  state: 'GO',
);

class _FakeProfileRepository implements ProfileRepository {
  Result<UserAddress?> getAddressResult = const Success(null);
  Result<void> saveAddressResult = const Success(null);
  UserAddress? lastSaved;

  @override
  Future<Result<Profile>> getProfile() async => const Success(_profile);

  @override
  Future<Result<Profile>> updateProfile({
    String? fullName,
    String? cpf,
    DateTime? birthDate,
    String? phone,
    bool? marketingOptIn,
  }) async => const Success(_profile);

  @override
  Future<Result<UserAddress?>> getAddress() async => getAddressResult;

  @override
  Future<Result<void>> saveAddress(UserAddress address) async {
    lastSaved = address;
    return saveAddressResult;
  }

  @override
  Future<Result<Profile>> uploadAvatar(
    Uint8List bytes,
    String fileExtension,
  ) async => const Success(_profile);
}

void main() {
  late _FakeProfileRepository repository;
  late AddressCubit cubit;

  setUp(() {
    repository = _FakeProfileRepository();
    cubit = AddressCubit(repository);
  });

  tearDown(() => cubit.close());

  test('estado inicial fica em LoadStatus.initial, sem endereço', () {
    expect(cubit.state.status, LoadStatus.initial);
    expect(cubit.state.address, isNull);
  });

  group('load', () {
    test(
      'sucesso com endereço cadastrado emite success com o endereço',
      () async {
        repository.getAddressResult = const Success(_address);

        await cubit.load();

        expect(cubit.state.status, LoadStatus.success);
        expect(cubit.state.address, _address);
      },
    );

    test(
      'sucesso sem endereço cadastrado emite success com address nulo',
      () async {
        repository.getAddressResult = const Success(null);

        await cubit.load();

        expect(cubit.state.status, LoadStatus.success);
        expect(cubit.state.address, isNull);
      },
    );

    test('falha do repositório emite error com a mensagem da falha', () async {
      repository.getAddressResult = const Error(ServerFailure('indisponível'));

      await cubit.load();

      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.errorMessage, 'indisponível');
    });
  });

  group('save', () {
    test(
      'sucesso guarda o endereço no state, para saving=false, retorna null',
      () async {
        repository.saveAddressResult = const Success(null);

        final failure = await cubit.save(_address);

        expect(failure, isNull);
        expect(cubit.state.saving, isFalse);
        expect(cubit.state.status, LoadStatus.success);
        expect(cubit.state.address, _address);
        expect(repository.lastSaved, _address);
      },
    );

    test(
      'falha para saving=false e retorna a falha sem mexer no endereço salvo',
      () async {
        const originalFailure = ServerFailure('erro ao salvar');
        repository.saveAddressResult = const Error(originalFailure);

        final failure = await cubit.save(_address);

        expect(failure, originalFailure);
        expect(cubit.state.saving, isFalse);
        expect(cubit.state.address, isNull);
      },
    );
  });
}
