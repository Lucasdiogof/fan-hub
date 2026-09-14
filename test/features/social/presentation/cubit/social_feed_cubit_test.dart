import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/social/domain/entities/social_post.dart';
import 'package:goias_app/features/social/domain/repositories/social_feed_repository.dart';
import 'package:goias_app/features/social/presentation/cubit/social_feed_cubit.dart';
import 'package:goias_app/features/social/presentation/cubit/social_feed_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

SocialPost _post(SocialPlatform platform, String id) => SocialPost(
  id: id,
  platform: platform,
  authorName: 'Goiás EC',
  authorHandle: '@goiasec',
  mediaType: SocialMediaType.image,
  publishedAt: DateTime(2026, 1, 1),
  permalink: 'https://example.com/$id',
);

class _FakeSocialFeedRepository implements SocialFeedRepository {
  Result<List<SocialPost>> feedResult = const Success([]);

  @override
  Future<Result<List<SocialPost>>> getFeed({SocialPlatform? platform}) async =>
      feedResult;
}

void main() {
  late _FakeSocialFeedRepository repository;

  setUp(() {
    repository = _FakeSocialFeedRepository();
  });

  test(
    'ao criar, já carrega sozinho, com Instagram selecionado por padrão',
    () async {
      final posts = [
        _post(SocialPlatform.instagram, 'i1'),
        _post(SocialPlatform.youtube, 'y1'),
      ];
      repository.feedResult = Success(posts);

      final cubit = SocialFeedCubit(repository);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, LoadStatus.success);
      expect(cubit.state.allPosts, posts);
      expect(cubit.state.selectedPlatform, SocialPlatform.instagram);
      expect(cubit.state.posts, [posts[0]]);
    },
  );

  test('sucesso vazio emite LoadStatus.empty', () async {
    repository.feedResult = const Success([]);

    final cubit = SocialFeedCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.empty);
  });

  test('falha do repositório emite error com a mensagem', () async {
    repository.feedResult = const Error(ServerFailure('indisponível'));

    final cubit = SocialFeedCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.error);
    expect(cubit.state.errorMessage, 'indisponível');
  });

  group('selectPlatform', () {
    test('filtra os posts pela plataforma escolhida', () async {
      final posts = [
        _post(SocialPlatform.instagram, 'i1'),
        _post(SocialPlatform.youtube, 'y1'),
        _post(SocialPlatform.x, 'x1'),
      ];
      repository.feedResult = Success(posts);
      final cubit = SocialFeedCubit(repository);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      cubit.selectPlatform(SocialPlatform.youtube);

      expect(cubit.state.selectedPlatform, SocialPlatform.youtube);
      expect(cubit.state.posts, [posts[1]]);
    });

    test('null mostra tudo, de todas as plataformas juntas', () async {
      final posts = [
        _post(SocialPlatform.instagram, 'i1'),
        _post(SocialPlatform.youtube, 'y1'),
      ];
      repository.feedResult = Success(posts);
      final cubit = SocialFeedCubit(repository);
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      cubit.selectPlatform(null);

      expect(cubit.state.selectedPlatform, isNull);
      expect(cubit.state.posts, posts);
    });

    test(
      'escolher a mesma plataforma já selecionada não emite de novo',
      () async {
        final cubit = SocialFeedCubit(repository);
        addTearDown(cubit.close);
        await Future<void>.delayed(Duration.zero);
        final states = <SocialFeedState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.selectPlatform(SocialPlatform.instagram);
        await Future<void>.delayed(Duration.zero);

        expect(states, isEmpty);
        await subscription.cancel();
      },
    );
  });

  test('refresh chama load() de novo', () async {
    final cubit = SocialFeedCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    final posts = [_post(SocialPlatform.instagram, 'i2')];
    repository.feedResult = Success(posts);
    await cubit.refresh();

    expect(cubit.state.allPosts, posts);
  });
}
