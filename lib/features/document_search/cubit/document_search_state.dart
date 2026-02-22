part of 'document_search_cubit.dart';

enum SearchView {
  suggestions,
  results;
}

@JsonSerializable(ignoreUnannotated: true)
class DocumentSearchState extends DocumentPagingState {
  final List<String> searchHistory;
  final SearchView view;
  final List<String> suggestions;
  @JsonKey()
  final ViewType viewType;

  const DocumentSearchState({
    this.view = SearchView.suggestions,
    this.searchHistory = const [],
    this.suggestions = const [],
    this.viewType = ViewType.detailed,
    super.filter = const DocumentFilter(),
    super.hasLoaded,
    super.isLoading,
    super.value,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        searchHistory,
        suggestions,
        view,
        viewType,
      ];

  @override
  DocumentSearchState copyWithPaged({
    bool? hasLoaded,
    bool? isLoading,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
  }) {
    return copyWith(
      hasLoaded: hasLoaded,
      isLoading: isLoading,
      filter: filter,
      value: value,
    );
  }

  DocumentSearchState copyWith({
    List<String>? searchHistory,
    bool? hasLoaded,
    bool? isLoading,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    List<String>? suggestions,
    SearchView? view,
    ViewType? viewType,
  }) {
    return DocumentSearchState(
      value: value ?? this.value,
      filter: filter ?? this.filter,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      isLoading: isLoading ?? this.isLoading,
      searchHistory: searchHistory ?? this.searchHistory,
      view: view ?? this.view,
      suggestions: suggestions ?? this.suggestions,
      viewType: viewType ?? this.viewType,
    );
  }

  factory DocumentSearchState.fromJson(Map<String, dynamic> json) =>
      _$DocumentSearchStateFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentSearchStateToJson(this);
}
