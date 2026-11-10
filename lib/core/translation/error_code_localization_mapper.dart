import 'package:flutter/cupertino.dart';
import 'package:paperless_mobile/api/paperless_api.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

String translateError(BuildContext context, ErrorCode code) {
  return switch (code) {
    ErrorCode.unknown => S.of(context)!.anUnknownErrorOccurred,
    ErrorCode.authenticationFailed =>
      S.of(context)!.authenticationFailedPleaseTryAgain,
    ErrorCode.notAuthenticated => S.of(context)!.userIsNotAuthenticated,
    ErrorCode.documentUploadFailed => S.of(context)!.couldNotUploadDocument,
    ErrorCode.documentUpdateFailed => S.of(context)!.couldNotUpdateDocument,
    ErrorCode.documentLoadFailed => S.of(context)!.couldNotLoadDocuments,
    ErrorCode.documentDeleteFailed => S.of(context)!.couldNotDeleteDocument,
    ErrorCode.documentPreviewFailed =>
      S.of(context)!.couldNotLoadDocumentPreview,
    ErrorCode.documentAsnQueryFailed =>
      S.of(context)!.couldNotAssignArchiveSerialNumber,
    ErrorCode.tagCreateFailed => S.of(context)!.couldNotCreateTag,
    ErrorCode.tagLoadFailed => S.of(context)!.couldNotLoadTags,
    ErrorCode.documentTypeCreateFailed => S.of(context)!.couldNotCreateDocument,
    ErrorCode.documentTypeLoadFailed =>
      S.of(context)!.couldNotLoadDocumentTypes,
    ErrorCode.correspondentCreateFailed =>
      S.of(context)!.couldNotCreateCorrespondent,
    ErrorCode.correspondentLoadFailed =>
      S.of(context)!.couldNotLoadCorrespondents,
    ErrorCode.scanRemoveFailed =>
      S.of(context)!.anErrorOccurredRemovingTheScans,
    ErrorCode.invalidClientCertificateConfiguration =>
      S.of(context)!.invalidCertificateOrMissingPassphrase,
    ErrorCode.documentBulkActionFailed =>
      S.of(context)!.couldNotBulkEditDocuments,
    ErrorCode.biometricsNotSupported =>
      S.of(context)!.biometricAuthenticationNotSupported,
    ErrorCode.biometricAuthenticationFailed =>
      S.of(context)!.biometricAuthenticationFailed,
    ErrorCode.deviceOffline => S.of(context)!.youAreCurrentlyOffline,
    ErrorCode.serverUnreachable =>
      S.of(context)!.couldNotReachYourPaperlessServer,
    ErrorCode.similarQueryError => S.of(context)!.couldNotLoadSimilarDocuments,
    ErrorCode.autocompleteQueryError =>
      S.of(context)!.anErrorOccurredWhileTryingToAutocompleteYourQuery,
    ErrorCode.storagePathLoadFailed => S.of(context)!.couldNotLoadStoragePaths,
    ErrorCode.storagePathCreateFailed =>
      S.of(context)!.couldNotCreateStoragePath,
    ErrorCode.loadSavedViewsError => S.of(context)!.couldNotLoadSavedViews,
    ErrorCode.createSavedViewError => S.of(context)!.couldNotCreateSavedView,
    ErrorCode.deleteSavedViewError => S.of(context)!.couldNotDeleteSavedView,
    ErrorCode.requestTimedOut => S.of(context)!.requestTimedOut,
    ErrorCode.unsupportedFileFormat => S.of(context)!.fileFormatNotSupported,
    ErrorCode.missingClientCertificate =>
      S.of(context)!.aClientCertificateWasExpectedButNotSent,
    ErrorCode.suggestionsQueryError => S.of(context)!.couldNotLoadSuggestions,
    ErrorCode.acknowledgeTasksError => S.of(context)!.couldNotAcknowledgeTasks,
    ErrorCode.correspondentDeleteFailed =>
      S.of(context)!.couldNotDeleteCorrespondent,
    ErrorCode.documentTypeDeleteFailed =>
      S.of(context)!.couldNotDeleteDocumentType,
    ErrorCode.tagDeleteFailed => S.of(context)!.couldNotDeleteTag,
    ErrorCode.storagePathDeleteFailed =>
      S.of(context)!.couldNotDeleteStoragePath,
    ErrorCode.correspondentUpdateFailed =>
      S.of(context)!.couldNotUpdateCorrespondent,
    ErrorCode.documentTypeUpdateFailed =>
      S.of(context)!.couldNotUpdateDocumentType,
    ErrorCode.tagUpdateFailed => S.of(context)!.couldNotUpdateTag,
    ErrorCode.storagePathUpdateFailed =>
      S.of(context)!.couldNotUpdateStoragePath,
    ErrorCode.serverInformationLoadFailed =>
      S.of(context)!.couldNotLoadServerInformation,
    ErrorCode.serverStatisticsLoadFailed =>
      S.of(context)!.couldNotLoadStatistics,
    ErrorCode.uiSettingsLoadFailed => S.of(context)!.couldNotLoadUISettings,
    ErrorCode.loadTasksError => S.of(context)!.couldNotLoadTasks,
    ErrorCode.userNotFound => S.of(context)!.userNotFound,
    ErrorCode.updateSavedViewError => S.of(context)!.couldNotUpdateSavedView,
    ErrorCode.userAlreadyExists => S.of(context)!.userAlreadyExists,
    ErrorCode.customFieldCreateFailed =>
      S.of(context)!.couldNotCreateCustomField,
    ErrorCode.customFieldLoadFailed => S.of(context)!.couldNotLoadCustomField,
    ErrorCode.customFieldDeleteFailed =>
      S.of(context)!.couldNotDeleteCustomField,
    ErrorCode.deleteNoteFailed => S.of(context)!.couldNotDeleteNote,
    ErrorCode.addNoteFailed => S.of(context)!.couldNotCreateNote,
    ErrorCode.mfaCodeRequired => S.of(context)!.mfaCodeRequired,
    ErrorCode.customFieldUpdateFailed =>
      S.of(context)!.couldNotUpdateCustomField,
    ErrorCode.userCreateError => S.of(context)!.couldNotCreateUser,
    ErrorCode.userUpdateError => S.of(context)!.couldNotUpdateUser,
    ErrorCode.userListError => S.of(context)!.couldNotLoadUsers,
    ErrorCode.userGetError => S.of(context)!.couldNotLoadUser,
    ErrorCode.userDeleteError => S.of(context)!.couldNotDeleteUser,
    ErrorCode.bulkDownloadFailed => S.of(context)!.couldNotDownloadDocuments,
    ErrorCode.bulkEditDocumentsFailed =>
      S.of(context)!.couldNotBulkEditDocuments,
    ErrorCode.profileGetError => S.of(context)!.couldNotLoadUserProfile,
    ErrorCode.invalidApiKey => S.of(context)!.invalidApiKey,
    ErrorCode.documentChatFailed => S.of(context)!.documentChatFailed,
  };
}
