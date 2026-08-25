import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/features/news/presentation/cubit/news_state.dart';
import 'package:goias_app/shared/state/load_status.dart';

/// Singleton (ver `injection_container.dart`) — a Home e a tela completa de
/// Notícias compartilham a mesma lista já carregada, sem buscar duas vezes:
/// o site oficial não pagina (só expõe as ~15 mais recentes), então "ver
/// mais" é só mostrar o que já foi buscado, não uma página nova.
class NewsCubit extends Cubit<NewsState> {
  NewsCubit(this._repository) : super(const NewsState()) {
    load();
  }

  final NewsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _repository.getList();
    switch (result) {
      case Success(:final data):
        emit(
          state.copyWith(
            status: data.isEmpty ? LoadStatus.empty : LoadStatus.success,
            items: data,
            errorMessage: () => null,
          ),
        );
      case Error(:final failure):
        emit(
          state.copyWith(
            status: LoadStatus.error,
            errorMessage: () => failure.message,
          ),
        );
    }
  }

  Future<void> refresh() => load();
}
