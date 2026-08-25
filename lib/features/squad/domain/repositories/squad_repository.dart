import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';

abstract interface class SquadRepository {
  Future<Result<List<SquadMember>>> getSquad();
}
