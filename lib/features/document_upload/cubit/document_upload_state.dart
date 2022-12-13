part of 'document_upload_cubit.dart';

@immutable
class DocumentUploadState extends Equatable {
  final Map<int, Tag> tags;
  final Map<int, Correspondent> correspondents;
  final Map<int, DocumentType> documentTypes;

  const DocumentUploadState({
    required this.tags,
    required this.correspondents,
    required this.documentTypes,
  });

  @override
  List<Object> get props => [
        tags,
        correspondents,
        documentTypes,
      ];

  DocumentUploadState copyWith({
    Map<int, Tag>? tags,
    Map<int, Correspondent>? correspondents,
    Map<int, DocumentType>? documentTypes,
  }) {
    return DocumentUploadState(
      tags: tags ?? this.tags,
      correspondents: correspondents ?? this.correspondents,
      documentTypes: documentTypes ?? this.documentTypes,
    );
  }
}
