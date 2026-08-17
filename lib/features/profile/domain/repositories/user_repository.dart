import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/profile/domain/entities/app_user.dart';

abstract class UserRepository {
  Future<Result<AppUser>> getCurrentUser();
}
