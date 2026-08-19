import 'package:equatable/equatable.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/shared/state/load_status.dart';

enum RegistrationStep { access, personal, address }

class MembershipRegistrationState extends Equatable {
  const MembershipRegistrationState({
    required this.plan,
    required this.price,
    this.step = RegistrationStep.access,
    this.showReview = false,
    this.data = const MembershipRegistrationData(),
    this.accessErrors = const {},
    this.personalErrors = const {},
    this.addressErrors = const {},
    this.regulationAccepted = false,
    this.submitStatus = LoadStatus.initial,
    this.submittedMembership,
    this.submitErrorMessage,
  });

  final MembershipPlan plan;
  final MembershipPlanPrice price;
  final RegistrationStep step;
  final bool showReview;
  final MembershipRegistrationData data;
  final Map<String, String> accessErrors;
  final Map<String, String> personalErrors;
  final Map<String, String> addressErrors;

  /// Aceite do Regulamento do Sócio Esmeralda — não é um campo de
  /// [MembershipRegistrationData] porque não é dado do titular, é o estado
  /// do próprio fluxo (igual a [showReview]). Sem ele, `CONFIRMAR
  /// ASSOCIAÇÃO` fica desabilitado de verdade, não só esmaecido.
  final bool regulationAccepted;
  final LoadStatus submitStatus;
  final Membership? submittedMembership;
  final String? submitErrorMessage;

  MembershipRegistrationState copyWith({
    MembershipPlan? plan,
    MembershipPlanPrice? price,
    RegistrationStep? step,
    bool? showReview,
    MembershipRegistrationData? data,
    Map<String, String>? accessErrors,
    Map<String, String>? personalErrors,
    Map<String, String>? addressErrors,
    bool? regulationAccepted,
    LoadStatus? submitStatus,
    Membership? submittedMembership,
    String? submitErrorMessage,
  }) {
    return MembershipRegistrationState(
      plan: plan ?? this.plan,
      price: price ?? this.price,
      step: step ?? this.step,
      showReview: showReview ?? this.showReview,
      data: data ?? this.data,
      accessErrors: accessErrors ?? this.accessErrors,
      personalErrors: personalErrors ?? this.personalErrors,
      addressErrors: addressErrors ?? this.addressErrors,
      regulationAccepted: regulationAccepted ?? this.regulationAccepted,
      submitStatus: submitStatus ?? this.submitStatus,
      submittedMembership: submittedMembership ?? this.submittedMembership,
      submitErrorMessage: submitErrorMessage ?? this.submitErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    plan,
    price,
    step,
    showReview,
    data,
    accessErrors,
    personalErrors,
    addressErrors,
    regulationAccepted,
    submitStatus,
    submittedMembership,
    submitErrorMessage,
  ];
}
