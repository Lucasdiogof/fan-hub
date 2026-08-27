import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/membership/data/membership_faq_data_source.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_faq_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

class MembershipFaqCubit extends Cubit<MembershipFaqState> {
  MembershipFaqCubit(
    this._dataSource, {
    String? initialCategoryId,
    String? initialQuery,
  }) : super(
         MembershipFaqState(
           selectedCategoryId: initialCategoryId,
           query: initialQuery ?? '',
         ),
       ) {
    load();
  }

  final MembershipFaqDataSource _dataSource;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final categories = await _dataSource.getCategories();
      emit(state.copyWith(status: LoadStatus.success, categories: categories));
    } catch (_) {
      emit(state.copyWith(status: LoadStatus.error));
    }
  }

  void selectCategory(String? categoryId) {
    emit(
      state.copyWith(
        selectedCategoryId: categoryId,
        clearSelectedCategoryId: categoryId == null,
        clearExpandedItemId: true,
      ),
    );
  }

  void setQuery(String query) =>
      emit(state.copyWith(query: query, clearExpandedItemId: true));

  void toggleItem(String itemId) {
    final isOpen = state.expandedItemId == itemId;
    emit(
      state.copyWith(
        expandedItemId: isOpen ? null : itemId,
        clearExpandedItemId: isOpen,
      ),
    );
  }
}
