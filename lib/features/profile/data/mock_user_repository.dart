import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/features/profile/domain/entities/app_user.dart';
import 'package:goias_app/features/profile/domain/repositories/user_repository.dart';

class MockUserRepository implements UserRepository {
  static const _latency = Duration(milliseconds: 300);

  @override
  Future<Result<AppUser>> getCurrentUser() async {
    await Future<void>.delayed(_latency);
    return const Success(MockData.currentUser);
  }
}
