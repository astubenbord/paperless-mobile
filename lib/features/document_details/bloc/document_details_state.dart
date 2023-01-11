part of 'document_details_cubit.dart';

class DocumentDetailsState with EquatableMixin {
  final DocumentModel document;
  final bool isFullContentLoaded;
  final String? fullContent;
  final FieldSuggestions suggestions;

  const DocumentDetailsState({
    required this.document,
    this.suggestions = const FieldSuggestions(),
    this.isFullContentLoaded = false,
    this.fullContent,
  });

  @override
  List<Object?> get props => [
        document,
        suggestions,
        isFullContentLoaded,
        fullContent,
      ];

  DocumentDetailsState copyWith({
    DocumentModel? document,
    FieldSuggestions? suggestions,
    bool? isFullContentLoaded,
    String? fullContent,
  }) {
    return DocumentDetailsState(
      document: document ?? this.document,
      suggestions: suggestions ?? this.suggestions,
      isFullContentLoaded: isFullContentLoaded ?? this.isFullContentLoaded,
      fullContent: fullContent ?? this.fullContent,
    );
  }
}
