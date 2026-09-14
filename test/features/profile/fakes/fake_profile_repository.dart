import 'dart:typed_data';

import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';

const profileFixture = Profile(id: 'u1', email: 'torcedor@example.com');

class FakeProfileRepository implements ProfileRepository {
  Result<Profile> getProfileResult = const Success(profileFixture);
  Result<Profile> updateProfileResult = const Success(profileFixture);
  Result<UserAddress?> getAddressResult = const Success(null);
  Result<void> saveAddressResult = const Success(null);
  Result<Profile> uploadAvatarResult = const Success(profileFixture);
  UserAddress? lastSaved;

  @override
  Future<Result<Profile>> getProfile() async => getProfileResult;

  @override
  Future<Result<Profile>> updateProfile({
    String? fullName,
    String? cpf,
    DateTime? birthDate,
    String? phone,
    bool? marketingOptIn,
  }) async => updateProfileResult;

  @override
  Future<Result<UserAddress?>> getAddress() async => getAddressResult;

  @override
  Future<Result<void>> saveAddress(UserAddress address) async {
    lastSaved = address;
    return saveAddressResult;
  }

  @override
  Future<Result<Profile>> uploadAvatar(
    Uint8List bytes,
    String fileExtension,
  ) async => uploadAvatarResult;
}
