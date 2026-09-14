import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/domain/entities/address_lookup_result.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/find_zip_code_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

const _result = AddressLookupResult(
  zipCode: '74000000',
  street: 'Rua T-1',
  neighborhood: 'Setor Bueno',
  city: 'Goiânia',
  state: 'GO',
);

class _FakeAddressRepository implements AddressRepository {
  Result<AddressLookupResult?> findByZipCodeResult = const Success(null);
  Result<List<AddressLookupResult>> searchByAddressResult = const Success([]);

  final citiesByState = <String, Completer<Result<List<String>>>>{};
  Result<List<String>>? defaultCitiesResult;

  Completer<Result<List<String>>> completerFor(String stateCode) =>
      citiesByState.putIfAbsent(stateCode, () => Completer());

  @override
  Future<Result<AddressLookupResult?>> findByZipCode(String zipCode) async =>
      findByZipCodeResult;

  @override
  Future<Result<List<AddressLookupResult>>> searchByAddress({
    required String state,
    required String city,
    required String street,
  }) async => searchByAddressResult;

  @override
  Future<Result<List<String>>> getCitiesByState(String stateCode) {
    if (defaultCitiesResult != null) {
      return Future.value(defaultCitiesResult);
    }
    return completerFor(stateCode).future;
  }
}

void main() {
  late _FakeAddressRepository repository;
  late FindZipCodeCubit cubit;

  setUp(() {
    repository = _FakeAddressRepository();
    cubit = FindZipCodeCubit(repository);
  });

  tearDown(() => cubit.close());

  test('estado inicial não tem UF/cidade/rua nenhuma', () {
    expect(cubit.state.state, isEmpty);
    expect(cubit.state.canSearch, isFalse);
  });

  test(
    'selectState limpa cidade e dispara o carregamento das cidades',
    () async {
      repository.defaultCitiesResult = const Success(['Goiânia', 'Anápolis']);

      cubit.selectState('Goiás');
      expect(cubit.state.state, 'Goiás');
      expect(cubit.state.city, isEmpty);
      expect(cubit.state.citiesLoadStatus, LoadStatus.loading);

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.citiesLoadStatus, LoadStatus.success);
      expect(cubit.state.availableCities, ['Goiânia', 'Anápolis']);
    },
  );

  test(
    'falha ao carregar cidades emite citiesLoadStatus.error e limpa a lista',
    () async {
      repository.defaultCitiesResult = const Error(
        ServerFailure('indisponível'),
      );

      cubit.selectState('Goiás');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.citiesLoadStatus, LoadStatus.error);
      expect(cubit.state.availableCities, isEmpty);
    },
  );

  test(
    'trocar de UF de novo antes da 1ª resposta chegar descarta a resposta velha',
    () async {
      cubit.selectState('Goiás');
      final goiasCompleter = repository.completerFor('GO');

      cubit.selectState('São Paulo');
      final spCompleter = repository.completerFor('SP');
      spCompleter.complete(const Success(['São Paulo', 'Campinas']));
      await Future<void>.delayed(Duration.zero);

      goiasCompleter.complete(const Success(['Goiânia', 'Anápolis']));
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.state, 'São Paulo');
      expect(cubit.state.availableCities, ['São Paulo', 'Campinas']);
    },
  );

  test('selectCity guarda a cidade escolhida', () {
    cubit.selectCity('Goiânia');
    expect(cubit.state.city, 'Goiânia');
  });

  test('updateStreet guarda a rua digitada', () {
    cubit.updateStreet('Rua T-1');
    expect(cubit.state.street, 'Rua T-1');
  });

  group('canSearch', () {
    test('só fica true com UF + cidade + rua com pelo menos 3 caracteres', () {
      repository.defaultCitiesResult = const Success(['Goiânia']);
      expect(cubit.state.canSearch, isFalse);

      cubit.selectState('Goiás');
      expect(cubit.state.canSearch, isFalse);

      cubit.selectCity('Goiânia');
      expect(cubit.state.canSearch, isFalse);

      cubit.updateStreet('Ru');
      expect(cubit.state.canSearch, isFalse);

      cubit.updateStreet('Rua T-1');
      expect(cubit.state.canSearch, isTrue);
    });
  });

  group('search', () {
    test('sem canSearch, não faz nada', () async {
      await cubit.search();
      expect(cubit.state.status, LoadStatus.initial);
    });

    test('sucesso com resultados emite success com a lista', () async {
      repository.defaultCitiesResult = const Success(['Goiânia']);
      cubit
        ..selectState('Goiás')
        ..selectCity('Goiânia')
        ..updateStreet('Rua T-1');
      repository.searchByAddressResult = const Success([_result]);

      await cubit.search();

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.results, [_result]);
    });

    test('sucesso vazio emite LoadStatus.empty', () async {
      repository.defaultCitiesResult = const Success(['Goiânia']);
      cubit
        ..selectState('Goiás')
        ..selectCity('Goiânia')
        ..updateStreet('Rua T-1');
      repository.searchByAddressResult = const Success([]);

      await cubit.search();

      expect(cubit.state.status, LoadStatus.empty);
    });

    test('falha emite error com a mensagem', () async {
      repository.defaultCitiesResult = const Success(['Goiânia']);
      cubit
        ..selectState('Goiás')
        ..selectCity('Goiânia')
        ..updateStreet('Rua T-1');
      repository.searchByAddressResult = const Error(ServerFailure('erro'));

      await cubit.search();

      expect(cubit.state.status, LoadStatus.error);
      expect(cubit.state.errorMessage, 'erro');
    });
  });
}
