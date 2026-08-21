import 'package:equatable/equatable.dart';
import 'package:goias_app/features/profile/domain/entities/user_address.dart';
import 'package:goias_app/shared/state/load_status.dart';

class AddressState extends Equatable {
  const AddressState({this.status = LoadStatus.initial, this.address, this.errorMessage, this.saving = false});

  final LoadStatus status;
  final UserAddress? address;
  final String? errorMessage;
  final bool saving;

  AddressState copyWith({LoadStatus? status, UserAddress? address, String? errorMessage, bool? saving}) {
    return AddressState(
      status: status ?? this.status,
      address: address ?? this.address,
      errorMessage: errorMessage ?? this.errorMessage,
      saving: saving ?? this.saving,
    );
  }

  @override
  List<Object?> get props => [status, address, errorMessage, saving];
}
