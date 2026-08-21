import 'dart:typed_data';

import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';

abstract class ProfileRepository {
  Future<Result<Profile>> getProfile();

  Future<Result<Profile>> updateProfile({String? fullName, String? cpf, DateTime? birthDate, String? phone});

  Future<Result<UserAddress?>> getAddress();

  Future<Result<void>> saveAddress(UserAddress address);

  Future<Result<Profile>> uploadAvatar(Uint8List bytes, String fileExtension);
}
