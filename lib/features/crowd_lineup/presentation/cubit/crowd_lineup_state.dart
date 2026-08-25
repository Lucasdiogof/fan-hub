import 'package:equatable/equatable.dart';
import 'package:goias_app/features/crowd_lineup/domain/crowd_lineup.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/features/crowd_lineup/domain/goias_squad.dart';
import 'package:goias_app/features/crowd_lineup/domain/squad_player.dart';
import 'package:goias_app/shared/state/load_status.dart';

class CrowdLineupState extends Equatable {
  const CrowdLineupState({
    this.status = LoadStatus.initial,
    this.formationId = '4-3-3',
    this.slots = const {},
    this.hasVoted = false,
    this.votingOpen = true,
    this.crowd = const CrowdLineup.empty(),
    this.submitting = false,
    this.errorMessage,
  });

  final LoadStatus status;
  final String formationId;
  final Map<int, String> slots;
  final bool hasVoted;
  final bool votingOpen;
  final CrowdLineup crowd;
  final bool submitting;
  final String? errorMessage;

  Formation get formation => formationById(formationId);
  Set<String> get pickedIds => slots.values.toSet();
  bool get isComplete => slots.length == 11;
  int get filledCount => slots.length;
  SquadPlayer? playerAt(int slotIndex) => squadById[slots[slotIndex]];
  bool get canEdit => votingOpen;

  CrowdLineupState copyWith({
    LoadStatus? status,
    String? formationId,
    Map<int, String>? slots,
    bool? hasVoted,
    bool? votingOpen,
    CrowdLineup? crowd,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CrowdLineupState(
      status: status ?? this.status,
      formationId: formationId ?? this.formationId,
      slots: slots ?? this.slots,
      hasVoted: hasVoted ?? this.hasVoted,
      votingOpen: votingOpen ?? this.votingOpen,
      crowd: crowd ?? this.crowd,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    formationId,
    slots,
    hasVoted,
    votingOpen,
    crowd,
    submitting,
    errorMessage,
  ];
}
