import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';

class HomeState extends Equatable {
  const HomeState({this.loading = true, this.nextMatch});

  final bool loading;
  final Match? nextMatch;

  HomeState copyWith({bool? loading, Match? nextMatch, bool clearNextMatch = false}) {
    return HomeState(
      loading: loading ?? this.loading,
      nextMatch: clearNextMatch ? null : (nextMatch ?? this.nextMatch),
    );
  }

  @override
  List<Object?> get props => [loading, nextMatch];
}
