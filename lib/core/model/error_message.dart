class ErrorMessage implements Exception {
  final ErrorCode code;
  final StackTrace? stackTrace;
  final int? httpStatusCode;

  const ErrorMessage(this.code, {this.stackTrace, this.httpStatusCode});

  factory ErrorMessage.unknown() {
    return const ErrorMessage(ErrorCode.unknown);
  }

  @override
  String toString() {
    return "ErrorMessage(code: $code${stackTrace != null ? ', stackTrace: ${stackTrace.toString()}' : ''}${httpStatusCode != null ? ', httpStatusCode: $httpStatusCode' : ''})";
  }
}

enum ErrorCode {
  unknown,
  authenticationFailed,
  notAuthenticated,
  documentUploadFailed,
  documentUpdateFailed,
  documentLoadFailed,
  documentDeleteFailed,
  documentBulkDeleteFailed,
  documentPreviewFailed,
  documentAsnQueryFailed,
  tagCreateFailed,
  tagLoadFailed,
  documentTypeCreateFailed,
  documentTypeLoadFailed,
  correspondentCreateFailed,
  correspondentLoadFailed,
  scanRemoveFailed,
  invalidClientCertificateConfiguration,
  biometricsNotSupported,
  biometricAuthenticationFailed,
  deviceOffline,
  serverUnreachable,
  similarQueryError,
  autocompleteQueryError,
  storagePathLoadFailed,
  storagePathCreateFailed,
  loadSavedViewsError,
  createSavedViewError,
  deleteSavedViewError,
  requestTimedOut,
  storagePathAlreadyExists,
  unsupportedFileFormat;
}
