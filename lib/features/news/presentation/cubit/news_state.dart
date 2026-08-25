import 'package:equatable/equatable.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';
import 'package:goias_app/shared/state/load_status.dart';

class NewsState extends Equatable {
  const NewsState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final List<NewsItem> items;
  final String? errorMessage;

  NewsState copyWith({
    LoadStatus? status,
    List<NewsItem>? items,
    String? Function()? errorMessage,
  }) {
    return NewsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
