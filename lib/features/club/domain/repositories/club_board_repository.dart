import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/entities/club_board_section.dart';

abstract interface class ClubBoardRepository {
  Future<Result<List<ClubBoardSection>>> getBoard();
}
