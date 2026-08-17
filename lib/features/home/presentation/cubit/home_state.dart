import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';

class HomeState extends Equatable {
  const HomeState({
    this.loading = true,
    this.userName,
    this.nextMatch,
    this.lastResult,
    this.featuredNews,
    this.upcomingMatches = const [],
  });

  final bool loading;
  final String? userName;
  final Match? nextMatch;
  final Match? lastResult;
  final NewsArticle? featuredNews;
  final List<Match> upcomingMatches;

  HomeState copyWith({
    bool? loading,
    String? userName,
    Match? nextMatch,
    Match? lastResult,
    NewsArticle? featuredNews,
    List<Match>? upcomingMatches,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      userName: userName ?? this.userName,
      nextMatch: nextMatch ?? this.nextMatch,
      lastResult: lastResult ?? this.lastResult,
      featuredNews: featuredNews ?? this.featuredNews,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    userName,
    nextMatch,
    lastResult,
    featuredNews,
    upcomingMatches,
  ];
}
