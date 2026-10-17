import 'package:goias_app/core/error/failures.dart';

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data, {this.cachedAt});

  final T data;

  /// Preenchido só quando [data] veio da última consulta salva no aparelho
  /// (sem rede / falha ao atualizar) — a tela deve avisar que o conteúdo
  /// pode estar desatualizado. `null` = dado fresco.
  final DateTime? cachedAt;
}

class Error<T> extends Result<T> {
  const Error(this.failure);

  final Failure failure;
}
