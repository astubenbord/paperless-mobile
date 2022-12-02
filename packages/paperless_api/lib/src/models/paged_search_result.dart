import 'package:equatable/equatable.dart';
import 'package:paperless_api/src/models/document_model.dart';

const pageRegex = r".*page=(\d+).*";

class PagedSearchResultJsonSerializer<T> {
  final Map<String, dynamic> json;
  final T Function(Map<String, dynamic>) fromJson;

  PagedSearchResultJsonSerializer(this.json, this.fromJson);
}

class PagedSearchResult<T> extends Equatable {
  /// Total number of available items
  final int count;

  /// Link to next page
  final String? next;

  /// Link to previous page
  final String? previous;

  /// Actual items
  final List<T> results;

  int get pageKey {
    if (next != null) {
      final matches = RegExp(pageRegex).allMatches(next!);
      final group = matches.first.group(1)!;
      final nextPageKey = int.parse(group);
      return nextPageKey - 1;
    }
    if (previous != null) {
      // This is only executed if it's the last page or there is no data.
      final matches = RegExp(pageRegex).allMatches(previous!);
      if (matches.isEmpty) {
        //In case there is a match but a page is not explicitly set, the page is 1 per default. Therefore, if the previous page is 1, this page is 1+1=2
        return 2;
      }
      final group = matches.first.group(1)!;
      final previousPageKey = int.parse(group);
      return previousPageKey + 1;
    }
    return 1;
  }

  const PagedSearchResult({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PagedSearchResult.fromJson(
      PagedSearchResultJsonSerializer<T> serializer) {
    return PagedSearchResult(
      count: serializer.json['count'],
      next: serializer.json['next'],
      previous: serializer.json['previous'],
      results: List<Map<String, dynamic>>.from(serializer.json['results'])
          .map<T>(serializer.fromJson)
          .toList(),
    );
  }

  PagedSearchResult copyWith({
    int? count,
    String? next,
    String? previous,
    List<DocumentModel>? results,
  }) {
    return PagedSearchResult(
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      results: results ?? this.results,
    );
  }

  ///
  /// Returns the number of pages based on the given [pageSize]. The last page
  /// might not exhaust its capacity.
  ///
  int inferPageCount({required int pageSize}) {
    if (pageSize == 0) {
      return 0;
    }
    return (count / pageSize).round() + 1;
  }

  @override
  List<Object?> get props => [count, next, previous, results];
}
