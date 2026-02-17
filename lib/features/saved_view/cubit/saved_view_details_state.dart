part of 'saved_view_details_cubit.dart';

class SavedViewDetailsState extends DocumentPagingState {
  final ViewType viewType;

  final Map<int, Correspondent> correspondents;
  final Map<int, DocumentType> documentTypes;
  final Map<int, Tag> tags;
  final Map<int, StoragePath> storagePaths;

  const SavedViewDetailsState({
    this.viewType = ViewType.list,
    super.filter = const DocumentFilter(),
    super.hasLoaded,
    super.isLoading,
    super.value,
    this.correspondents = const {},
    this.documentTypes = const {},
    this.tags = const {},
    this.storagePaths = const {},
  });

  @override
  List<Object?> get props => [
        viewType,
        correspondents,
        documentTypes,
        tags,
        storagePaths,
        ...super.props,
      ];

  @override
  SavedViewDetailsState copyWithPaged({
    bool? hasLoaded,
    bool? isLoading,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
  }) {
    return copyWith(
      hasLoaded: hasLoaded,
      isLoading: isLoading,
      value: value,
      filter: filter,
    );
  }

  SavedViewDetailsState copyWith({
    bool? hasLoaded,
    bool? isLoading,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    ViewType? viewType,
    Map<int, Correspondent>? correspondents,
    Map<int, DocumentType>? documentTypes,
    Map<int, Tag>? tags,
    Map<int, StoragePath>? storagePaths,
  }) {
    return SavedViewDetailsState(
      hasLoaded: hasLoaded ?? this.hasLoaded,
      isLoading: isLoading ?? this.isLoading,
      value: value ?? this.value,
      filter: filter ?? this.filter,
      viewType: viewType ?? this.viewType,
      correspondents: correspondents ?? this.correspondents,
      documentTypes: documentTypes ?? this.documentTypes,
      tags: tags ?? this.tags,
      storagePaths: storagePaths ?? this.storagePaths,
    );
  }
}
