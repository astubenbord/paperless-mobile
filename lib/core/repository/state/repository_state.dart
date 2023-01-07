abstract class RepositoryState<T> {
  final T values;
  final bool hasLoaded;

  const RepositoryState({
    required this.values,
    this.hasLoaded = false,
  });

  RepositoryState.loaded(this.values) : hasLoaded = true;

  RepositoryState<T> copyWith({
    T? values,
    bool? hasLoaded,
  });
}
