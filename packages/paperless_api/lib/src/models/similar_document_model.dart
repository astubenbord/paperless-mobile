import 'package:paperless_api/src/models/document_model.dart';

class SimilarDocumentModel extends DocumentModel {
  final SearchHit searchHit;

  const SimilarDocumentModel({
    required super.id,
    required super.title,
    required super.documentType,
    required super.correspondent,
    required super.created,
    required super.modified,
    required super.added,
    required super.originalFileName,
    required this.searchHit,
    super.archiveSerialNumber,
    super.archivedFileName,
    super.content,
    super.storagePath,
    super.tags,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['__search_hit__'] = searchHit.toJson();
    return json;
  }

  SimilarDocumentModel.fromJson(Map<String, dynamic> json)
      : searchHit = SearchHit.fromJson(json),
        super.fromJson(json);
}

class SearchHit {
  final double? score;
  final String? highlights;
  final int? rank;

  SearchHit({
    this.score,
    required this.highlights,
    required this.rank,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'highlights': highlights,
      'rank': rank,
    };
  }

  SearchHit.fromJson(Map<String, dynamic> json)
      : score = json['score'],
        highlights = json['highlights'],
        rank = json['rank'];
}
