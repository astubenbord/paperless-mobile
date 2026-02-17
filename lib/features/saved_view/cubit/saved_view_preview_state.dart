part of 'saved_view_preview_cubit.dart';

sealed class SavedViewPreviewState {
  const SavedViewPreviewState();
}

class InitialSavedViewPreviewState extends SavedViewPreviewState {
  const InitialSavedViewPreviewState();
}

class LoadingSavedViewPreviewState extends SavedViewPreviewState {
  const LoadingSavedViewPreviewState();
}

class LoadedSavedViewPreviewState extends SavedViewPreviewState {
  final List<DocumentModel> documents;

  const LoadedSavedViewPreviewState({
    required this.documents,
  });
}

class ErrorSavedViewPreviewState extends SavedViewPreviewState {
  const ErrorSavedViewPreviewState();
}

class OfflineSavedViewPreviewState extends SavedViewPreviewState {
  const OfflineSavedViewPreviewState();
}
