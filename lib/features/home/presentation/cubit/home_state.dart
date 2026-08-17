import 'package:equatable/equatable.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';

class HomeState extends Equatable {
  const HomeState({
    this.loading = true,
    this.userName,
    this.featuredNews,
  });

  final bool loading;
  final String? userName;
  final NewsArticle? featuredNews;

  HomeState copyWith({
    bool? loading,
    String? userName,
    NewsArticle? featuredNews,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      userName: userName ?? this.userName,
      featuredNews: featuredNews ?? this.featuredNews,
    );
  }

  @override
  List<Object?> get props => [loading, userName, featuredNews];
}
