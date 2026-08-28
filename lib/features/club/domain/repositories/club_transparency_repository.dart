import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/club/domain/entities/club_transparency_topic.dart';

abstract interface class ClubTransparencyRepository {
  Future<Result<List<ClubTransparencyTopic>>> getTopics();
}
