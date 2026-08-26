import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/domain/entities/address_lookup_result.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_registration_state.dart';
import 'package:goias_app/l10n/app_localizations.dart';

class _FakeMembershipRepository implements MembershipRepository {
  @override
  Future<Result<List<MembershipPlan>>> getPlans() async => const Success([]);

  @override
  Future<Result<Membership?>> getMyMembership() async => const Success(null);

  @override
  Future<Result<List<CheckIn>>> getMyCheckIns() async => const Success([]);

  @override
  Future<Result<CheckIn>> checkIn(String matchId) async {
    return Success(CheckIn(matchId: matchId, checkedInAt: DateTime.now()));
  }

  @override
  Future<Result<Membership>> submitRegistration({
    required MembershipPlan plan,
    required MembershipPlanPrice price,
    required MembershipRegistrationData data,
    required String regulationVersion,
    required DateTime regulationAcceptedAt,
  }) async {
    return Success(
      Membership(
        id: 'test-membership',
        userId: 'test-user',
        plan: plan,
        planPrice: price,
        status: MembershipStatus.active,
        startedAt: DateTime.now(),
        regulationVersion: regulationVersion,
        regulationAcceptedAt: regulationAcceptedAt,
      ),
    );
  }
}

class _FakeAddressRepository implements AddressRepository {
  @override
  Future<Result<AddressLookupResult?>> findByZipCode(String zipCode) async => const Success(null);

  @override
  Future<Result<List<AddressLookupResult>>> searchByAddress({
    required String state,
    required String city,
    required String street,
  }) async => const Success([]);

  @override
  Future<Result<List<String>>> getCitiesByState(String stateCode) async => const Success(['Goiânia', 'Anápolis']);
}

const _plan = MembershipPlan(
  id: 'nossa-garra',
  name: 'NOSSA GARRA',
  tagline: 'tagline',
  includesStadiumAccess: true,
  stadiumSector: 'Tobogã',
  benefits: ['benefício'],
  prices: [MembershipPlanPrice(label: '', monthlyPrice: 59.9, annualPrice: 718.8)],
);

void main() {
  late MembershipRegistrationCubit cubit;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('pt'));
  });

  setUp(() {
    cubit = MembershipRegistrationCubit(
      _FakeMembershipRepository(),
      _FakeAddressRepository(),
      plan: _plan,
      price: _plan.defaultPrice,
    );
  });

  tearDown(() => cubit.close());

  test('empty required fields only show "obrigatório" errors after Continuar is pressed', () {
    expect(cubit.state.accessErrors(l10n)['cpf'], isNull);
    cubit.continueFromAccess();
    expect(cubit.state.accessErrors(l10n)['cpf'], isNotNull);
    expect(cubit.state.isAccessStepValid, isFalse);
  });

  test('an invalid-but-complete CPF is flagged immediately, without needing Continuar', () {
    cubit.updateCpf('123.456.789-00'); // 11 digits, wrong check digit
    expect(cubit.state.accessErrors(l10n)['cpf'], 'CPF inválido.');
    expect(cubit.state.isAccessStepValid, isFalse);
  });

  test('fixing the CPF clears the error immediately and the step becomes valid', () {
    cubit.continueFromAccess();
    cubit.updateCpf('123.456.789-00');
    expect(cubit.state.accessErrors(l10n)['cpf'], isNotNull);

    cubit.updateNationality('BR');
    cubit.updateCpf('123.456.789-09'); // valid check digits
    expect(cubit.state.accessErrors(l10n)['cpf'], isNull);
    expect(cubit.state.isAccessStepValid, isTrue);
  });

  test('passport format error only shows after the field loses focus or Continuar is pressed', () {
    cubit.updateNationality('AR');
    cubit.updatePassport('A1');
    expect(cubit.state.accessErrors(l10n)['passport'], isNull);

    cubit.markFieldBlurred('passport');
    expect(cubit.state.accessErrors(l10n)['passport'], isNotNull);
  });

  test('back() from the review screen returns to the address step without losing data', () async {
    cubit
      ..updateCpf('123.456.789-09')
      ..updateNationality('BR')
      ..continueFromAccess()
      ..updateContactEmail('lucas@gmail.com')
      ..updateFullName('Lucas Diogo')
      ..updateBirthDate('01011990')
      ..updateGender(Gender.masculino)
      ..updatePhone('(62) 99999-8888')
      ..continueFromPersonal()
      ..updateAddressCountry('BR')
      ..updateZipCode('74000000');

    // Espera o debounce da consulta de CEP terminar (o fake devolve "não
    // encontrado", o que não deveria impedir o preenchimento manual).
    await Future<void>.delayed(const Duration(milliseconds: 600));

    cubit
      ..updateStreet('Rua Teste')
      ..updateNumber('123')
      ..updateNeighborhood('Setor Teste')
      ..updateState('Goiás')
      ..updateCity('Goiânia')
      ..continueToReview();

    expect(cubit.state.showReview, isTrue);

    cubit.back();

    expect(cubit.state.showReview, isFalse);
    expect(cubit.state.step, RegistrationStep.address);
    expect(cubit.state.data.fullName, 'Lucas Diogo');
    expect(cubit.state.data.street, 'Rua Teste');
  });
}
