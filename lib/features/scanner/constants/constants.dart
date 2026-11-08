String mapCameraErrorCode(String errorCode) {
  return switch (errorCode) {
    "cameraPermission" =>
      "Camera permission request ongoing or MediaRecorderCamera permission not granted",
    "cameraNotFound" =>
      "Camera not found. Please call the 'create' method before calling 'initialize'.",
    "captureAlreadyActive" => "Picture is currently already being captured",
    "cannotCreateFile" => "failed to create a file",
    "captureTimeout" => "Picture capture request timed out",
    "captureFailure" =>
      "Unknown reason, the capture has failed due to an abortCaptures() call or an error happened in the framework",
    "IOError" => "Failed saving image or failed to setup writer",
    "videoRecordingFailed" =>
      "Failed to record video or pause/resumeVideoRecording requires Android API +24.",
    "setFlashModeFailed" =>
      "Device does not have flash capabilities, unknown flash mode or could not set flash mode.",
    "setExposurePointFailed" =>
      "Unknown exposure mode, device does not have exposure point capabilities or could not determine max region boundaries",
    "setFocusModeFailed" => "Unknown focus mode",
    "setFocusPointFailed" =>
      "Device does not have focus point capabilities or could not determine max region boundaries",
    "ZOOM_ERROR" =>
      "Zoom level out of bounds (zoom level should be between min_zoom and max_zoom) or called without specifying a zoom level.",
    _ => 'Unknown error: $errorCode',
  };
}
