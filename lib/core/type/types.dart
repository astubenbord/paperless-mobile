typedef JSON = Map<String, dynamic>;
typedef PaperlessValidationErrors = Map<String, String>;
typedef PaperlessLocalizedErrorMessage = String;

extension ValidationErrorsUtils on PaperlessValidationErrors {
  bool get hasFieldUnspecificError => containsKey("non_field_errors");
  String? get fieldUnspecificError => this['non_field_errors'];
}
