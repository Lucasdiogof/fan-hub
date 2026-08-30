import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';

/// Singleton do app (mesma razão do `CartCubit`) — favoritos precisam
/// aparecer marcados em qualquer card, em qualquer tela da loja, sem
/// recarregar. Estado é só o set de ids: nenhum widget guarda "favoritado"
/// localmente.
class FavoritesCubit extends Cubit<Set<String>> {
  FavoritesCubit(this._repository) : super(const {});

  final StoreRepository _repository;

  Future<void> load() async {
    final result = await _repository.loadFavoriteProductIds();
    if (result case Success(:final data)) emit(data);
  }

  Future<void> toggle(String productId) async {
    final updated = {...state};
    if (!updated.remove(productId)) updated.add(productId);
    emit(updated);
    await _repository.saveFavoriteProductIds(updated);
  }

  bool isFavorite(String productId) => state.contains(productId);

  /// Chamado no logout/sessão expirada (ver `AccountSessionCacheGuard`) —
  /// favoritos são locais ao aparelho, nunca podem sobreviver pra outra
  /// conta que faça login em seguida.
  Future<void> clear() async {
    emit(const {});
    await _repository.saveFavoriteProductIds(const {});
  }
}
