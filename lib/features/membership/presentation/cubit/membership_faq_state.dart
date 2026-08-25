import 'package:equatable/equatable.dart';
import 'package:goias_app/features/membership/domain/entities/faq_category.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MembershipFaqState extends Equatable {
  const MembershipFaqState({
    this.status = LoadStatus.initial,
    this.categories = const [],
    this.selectedCategoryId,
    this.query = '',
    this.expandedItemId,
    this.errorMessage,
  });

  final LoadStatus status;
  final List<FaqCategory> categories;

  /// `null` = "Todas".
  final String? selectedCategoryId;
  final String query;
  final String? expandedItemId;
  final String? errorMessage;

  MembershipFaqState copyWith({
    LoadStatus? status,
    List<FaqCategory>? categories,
    String? selectedCategoryId,
    bool clearSelectedCategoryId = false,
    String? query,
    String? expandedItemId,
    bool clearExpandedItemId = false,
    String? errorMessage,
  }) {
    return MembershipFaqState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      selectedCategoryId: clearSelectedCategoryId
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      query: query ?? this.query,
      expandedItemId: clearExpandedItemId
          ? null
          : (expandedItemId ?? this.expandedItemId),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    categories,
    selectedCategoryId,
    query,
    expandedItemId,
    errorMessage,
  ];
}
