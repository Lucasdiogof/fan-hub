import 'dart:typed_data';

import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/profile/data/profile_error_mapper.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<Result<Profile>> getProfile() async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', _uid)
          .maybeSingle();
      return Success(_mapProfile(row));
    } catch (error, stackTrace) {
      return Error(mapProfileError(error, stackTrace, isWrite: false));
    }
  }

  @override
  Future<Result<Profile>> updateProfile({
    String? fullName,
    String? cpf,
    DateTime? birthDate,
    String? phone,
    bool? marketingOptIn,
  }) async {
    try {
      final row = await _client
          .from('profiles')
          .update({
            'full_name': fullName,
            'cpf': cpf,
            'birth_date': birthDate == null ? null : _dateOnly(birthDate),
            'phone': phone,
            // Diferente dos 4 campos acima (sempre sobrescritos, mesmo com
            // null — é assim que a tela de Dados Pessoais consegue LIMPAR um
            // campo de propósito): `marketingOptIn` só entra no update
            // quando o chamador realmente passou um valor, nunca apaga o
            // opt-in existente por omissão.
            'marketing_opt_in': ?marketingOptIn,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', _uid)
          .select()
          .maybeSingle();
      return Success(_mapProfile(row));
    } catch (error, stackTrace) {
      return Error(mapProfileError(error, stackTrace));
    }
  }

  @override
  Future<Result<UserAddress?>> getAddress() async {
    try {
      final row = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', _uid)
          .maybeSingle();
      if (row == null) return const Success(null);
      return Success(
        UserAddress(
          zipCode: row['zip_code'] as String?,
          street: row['street'] as String?,
          number: row['number'] as String?,
          complement: row['complement'] as String?,
          neighborhood: row['neighborhood'] as String?,
          city: row['city'] as String?,
          state: row['state'] as String?,
          country: row['country'] as String? ?? 'BR',
        ),
      );
    } catch (error, stackTrace) {
      return Error(mapProfileError(error, stackTrace, isWrite: false));
    }
  }

  @override
  Future<Result<void>> saveAddress(UserAddress address) async {
    try {
      await _client.from('user_addresses').upsert({
        'user_id': _uid,
        'zip_code': address.zipCode,
        'street': address.street,
        'number': address.number,
        'complement': address.complement,
        'neighborhood': address.neighborhood,
        'city': address.city,
        'state': address.state,
        'country': address.country,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapProfileError(error, stackTrace));
    }
  }

  @override
  Future<Result<Profile>> uploadAvatar(
    Uint8List bytes,
    String fileExtension,
  ) async {
    try {
      final ext = fileExtension.toLowerCase() == 'jpg'
          ? 'jpeg'
          : fileExtension.toLowerCase();
      final path = '$_uid/avatar.$ext';
      await _client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
          );
      final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
      final bustedUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      final row = await _client
          .from('profiles')
          .update({
            'avatar_url': bustedUrl,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', _uid)
          .select()
          .maybeSingle();
      return Success(_mapProfile(row));
    } catch (error, stackTrace) {
      return Error(mapProfileError(error, stackTrace));
    }
  }

  Profile _mapProfile(Map<String, dynamic>? row) {
    final user = _client.auth.currentUser!;
    final birth = row?['birth_date'] as String?;
    return Profile(
      id: user.id,
      email: user.email ?? '',
      fullName: row?['full_name'] as String?,
      cpf: row?['cpf'] as String?,
      birthDate: birth == null ? null : DateTime.tryParse(birth),
      phone: row?['phone'] as String?,
      avatarUrl: row?['avatar_url'] as String?,
      marketingOptIn: row?['marketing_opt_in'] as bool? ?? false,
    );
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
