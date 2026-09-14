import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/membership/data/membership_faq_data_source.dart';
import 'package:goias_app/features/membership/domain/entities/faq_category.dart';
import 'package:goias_app/features/membership/domain/entities/faq_item.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_faq_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _dummyClient() => SupabaseClient(
  'https://example.supabase.co',
  'anon-key',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

const _category = FaqCategory(
  id: 'cadastro',
  title: 'Cadastro',
  items: [
    FaqItem(id: 'q1', question: 'Como assino?', answer: []),
    FaqItem(id: 'q2', question: 'Posso cancelar?', answer: []),
  ],
);

class _FakeFaqDataSource extends MembershipFaqDataSource {
  _FakeFaqDataSource() : super(_dummyClient(), goiasClubConfig);

  List<FaqCategory>? categoriesResult = const [_category];
  bool shouldThrow = false;

  @override
  Future<List<FaqCategory>> getCategories() async {
    if (shouldThrow) throw Exception('falha simulada');
    return categoriesResult!;
  }
}

void main() {
  late _FakeFaqDataSource dataSource;

  setUp(() {
    dataSource = _FakeFaqDataSource();
  });

  test('ao criar, já carrega sozinho as categorias', () async {
    final cubit = MembershipFaqCubit(dataSource);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.categories, [_category]);
  });

  test('categoria/query iniciais vêm do construtor', () {
    final cubit = MembershipFaqCubit(
      dataSource,
      initialCategoryId: 'cadastro',
      initialQuery: 'assinar',
    );
    addTearDown(cubit.close);

    expect(cubit.state.selectedCategoryId, 'cadastro');
    expect(cubit.state.query, 'assinar');
  });

  test('falha na fonte de dados emite LoadStatus.error', () async {
    dataSource.shouldThrow = true;

    final cubit = MembershipFaqCubit(dataSource);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.error);
  });

  test('selectCategory guarda a categoria e fecha o item expandido', () async {
    final cubit = MembershipFaqCubit(dataSource);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);
    cubit.toggleItem('q1');
    expect(cubit.state.expandedItemId, 'q1');

    cubit.selectCategory('cadastro');

    expect(cubit.state.selectedCategoryId, 'cadastro');
    expect(cubit.state.expandedItemId, isNull);
  });

  test('selectCategory(null) volta pra "Todas"', () async {
    final cubit = MembershipFaqCubit(dataSource, initialCategoryId: 'cadastro');
    addTearDown(cubit.close);

    cubit.selectCategory(null);

    expect(cubit.state.selectedCategoryId, isNull);
  });

  test('setQuery atualiza a busca e fecha o item expandido', () async {
    final cubit = MembershipFaqCubit(dataSource);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);
    cubit.toggleItem('q1');

    cubit.setQuery('cancelar');

    expect(cubit.state.query, 'cancelar');
    expect(cubit.state.expandedItemId, isNull);
  });

  group('toggleItem', () {
    test('abre um item fechado', () async {
      final cubit = MembershipFaqCubit(dataSource);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      cubit.toggleItem('q1');

      expect(cubit.state.expandedItemId, 'q1');
    });

    test('tocar de novo no mesmo item fecha ele', () async {
      final cubit = MembershipFaqCubit(dataSource);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);
      cubit.toggleItem('q1');

      cubit.toggleItem('q1');

      expect(cubit.state.expandedItemId, isNull);
    });

    test(
      'abrir outro item troca qual está expandido, nunca acumula dois',
      () async {
        final cubit = MembershipFaqCubit(dataSource);
        addTearDown(cubit.close);
        await Future<void>.delayed(Duration.zero);
        cubit.toggleItem('q1');

        cubit.toggleItem('q2');

        expect(cubit.state.expandedItemId, 'q2');
      },
    );
  });
}
