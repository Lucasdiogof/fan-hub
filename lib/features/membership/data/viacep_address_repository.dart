import 'dart:async';

import 'package:dio/dio.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/data/ibge_location_data_source.dart';
import 'package:goias_app/features/membership/data/viacep_data_source.dart';
import 'package:goias_app/features/membership/domain/entities/address_lookup_result.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/shared/utils/masks.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ViaCepAddressRepository implements AddressRepository {
  ViaCepAddressRepository(this._dataSource, this._ibgeDataSource);

  final ViaCepDataSource _dataSource;
  final IbgeLocationDataSource _ibgeDataSource;

  @override
  Future<Result<List<String>>> getCitiesByState(String stateCode) async {
    try {
      final cities = await _ibgeDataSource.getCitiesByState(stateCode);
      return Success(cities);
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        NetworkFailure(
          'Não foi possível carregar as cidades. Tente novamente.',
        ),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        UnexpectedFailure(
          'Não foi possível carregar as cidades. Tente novamente.',
        ),
      );
    }
  }

  @override
  Future<Result<AddressLookupResult?>> findByZipCode(String zipCode) async {
    final digits = onlyDigits(zipCode);
    if (digits.length != 8) return const Success(null);
    try {
      final json = await _dataSource.findByZipCode(digits);
      if (json == null) return const Success(null);
      return Success(_map(json));
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        NetworkFailure('Não foi possível consultar o CEP. Tente novamente.'),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        UnexpectedFailure('Não foi possível consultar o CEP. Tente novamente.'),
      );
    }
  }

  @override
  Future<Result<List<AddressLookupResult>>> searchByAddress({
    required String state,
    required String city,
    required String street,
  }) async {
    try {
      final results = await _dataSource.searchByAddress(
        state: state,
        city: city,
        street: street,
      );
      return Success(results.map(_map).toList());
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        NetworkFailure('Não foi possível buscar o endereço. Tente novamente.'),
      );
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(
        UnexpectedFailure(
          'Não foi possível buscar o endereço. Tente novamente.',
        ),
      );
    }
  }

  AddressLookupResult _map(Map<String, dynamic> json) {
    return AddressLookupResult(
      zipCode: (json['cep'] as String? ?? '').replaceAll('-', ''),
      street: json['logradouro'] as String? ?? '',
      neighborhood: json['bairro'] as String? ?? '',
      city: json['localidade'] as String? ?? '',
      state: json['uf'] as String? ?? '',
    );
  }
}
