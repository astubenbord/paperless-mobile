import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/paperless_api.dart';

class DocumentsState extends Equatable {
  final bool isLoading;
  final bool hasLoaded;
  final DocumentFilter filter;
  final List<PagedSearchResult<DocumentModel>> value;
  final int? selectedSavedViewId;

  @JsonKey(ignore: true)
  final List<DocumentModel> selection;

  const DocumentsState({
    this.hasLoaded = false,
    this.isLoading = false,
    this.value = const [],
    this.filter = const DocumentFilter(),
    this.selection = const [],
    this.selectedSavedViewId,
  });

  int get currentPageNumber {
    return filter.page;
  }

  int? get nextPageNumber {
    return isLastPageLoaded ? null : currentPageNumber + 1;
  }

  int get count {
    if (value.isEmpty) {
      return 0;
    }
    return value.first.count;
  }

  bool get isLastPageLoaded {
    if (!hasLoaded) {
      return false;
    }
    if (value.isNotEmpty) {
      return value.last.next == null;
    }
    return true;
  }

  int inferPageCount({required int pageSize}) {
    if (!hasLoaded) {
      return 100000;
    }
    if (value.isEmpty) {
      return 0;
    }
    return value.first.inferPageCount(pageSize: pageSize);
  }

  List<DocumentModel> get documents {
    return value.fold(
        [], (previousValue, element) => [...previousValue, ...element.results]);
  }

  DocumentsState copyWith({
    bool overwrite = false,
    bool? hasLoaded,
    bool? isLoading,
    List<PagedSearchResult<DocumentModel>>? value,
    DocumentFilter? filter,
    List<DocumentModel>? selection,
    int? selectedSavedViewId,
  }) {
    return DocumentsState(
      hasLoaded: hasLoaded ?? this.hasLoaded,
      isLoading: isLoading ?? this.isLoading,
      value: value ?? this.value,
      filter: filter ?? this.filter,
      selection: selection ?? this.selection,
      selectedSavedViewId: selectedSavedViewId ?? this.selectedSavedViewId,
    );
  }

  @override
  List<Object?> get props => [
        hasLoaded,
        filter,
        value,
        selection,
        isLoading,
        selectedSavedViewId,
      ];

  Map<String, dynamic> toJson() {
    final json = {
      'hasLoaded': hasLoaded,
      'isLoading': isLoading,
      'filter': filter.toJson(),
      'selectedSavedViewId': selectedSavedViewId,
      'value':
          value.map((e) => e.toJson(DocumentModelJsonConverter())).toList(),
    };
    return json;
  }

  factory DocumentsState.fromJson(Map<String, dynamic> json) {
    return DocumentsState(
      hasLoaded: json['hasLoaded'],
      isLoading: json['isLoading'],
      selectedSavedViewId: json['selectedSavedViewId'],
      value: (json['value'] as List<dynamic>)
          .map((e) =>
              PagedSearchResult.fromJsonT(e, DocumentModelJsonConverter()))
          .toList(),
      filter: DocumentFilter.fromJson(json['filter']),
    );
  }
}
