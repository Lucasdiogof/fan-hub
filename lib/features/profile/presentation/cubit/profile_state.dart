import 'package:equatable/equatable.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/shared/state/load_status.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.status = LoadStatus.initial,
    this.profile,
    this.errorMessage,
    this.saving = false,
    this.uploadingAvatar = false,
  });

  final LoadStatus status;
  final Profile? profile;
  final String? errorMessage;
  final bool saving;
  final bool uploadingAvatar;

  ProfileState copyWith({
    LoadStatus? status,
    Profile? profile,
    String? errorMessage,
    bool? saving,
    bool? uploadingAvatar,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
      saving: saving ?? this.saving,
      uploadingAvatar: uploadingAvatar ?? this.uploadingAvatar,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    errorMessage,
    saving,
    uploadingAvatar,
  ];
}
