import 'package:cached_query_flutter/cached_query_flutter.dart';

extension CachedQueryExtensions on QueryState {
  bool get isLoadingInitial => isLoading && data == null;
}
