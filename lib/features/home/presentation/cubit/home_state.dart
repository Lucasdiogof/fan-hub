import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';

class HomeState extends Equatable {
  const HomeState({this.loading = true, this.nextMatch, this.isMember = false});

  final bool loading;
  final Match? nextMatch;
  final bool isMember;

  HomeState copyWith({bool? loading, Match? nextMatch, bool clearNextMatch = false, bool? isMember}) {
    return HomeState(
      loading: loading ?? this.loading,
      nextMatch: clearNextMatch ? null : (nextMatch ?? this.nextMatch),
      isMember: isMember ?? this.isMember,
    );
  }

  @override
  List<Object?> get props => [loading, nextMatch, isMember];
}
