part of 'document_details_cubit.dart';

class DocumentDetailsState with EquatableMixin {
  final DocumentModel document;

  const DocumentDetailsState({
    required this.document,
  });

  @override
  List<Object?> get props => [document];
}
