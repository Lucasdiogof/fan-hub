import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';

class HomeState extends Equatable {
  const HomeState({
    this.loading = true,
    this.userName,
    this.nextMatch,
    this.featuredNews,
    this.upcomingMatches = const [],
    this.ticketsOpenMatchIds = const {},
  });

  final bool loading;
  final String? userName;
  final Match? nextMatch;
  final NewsArticle? featuredNews;
  final List<Match> upcomingMatches;

  /// Mock local — ingresso/check-in não vem da API-Football, só dados
  /// esportivos (Match, Standing) vêm.
  final Set<String> ticketsOpenMatchIds;

  HomeState copyWith({
    bool? loading,
    String? userName,
    Match? nextMatch,
    NewsArticle? featuredNews,
    List<Match>? upcomingMatches,
    Set<String>? ticketsOpenMatchIds,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      userName: userName ?? this.userName,
      nextMatch: nextMatch ?? this.nextMatch,
      featuredNews: featuredNews ?? this.featuredNews,
      upcomingMatches: upcomingMatches ?? this.upcomingMatches,
      ticketsOpenMatchIds: ticketsOpenMatchIds ?? this.ticketsOpenMatchIds,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    userName,
    nextMatch,
    featuredNews,
    upcomingMatches,
    ticketsOpenMatchIds,
  ];
}
